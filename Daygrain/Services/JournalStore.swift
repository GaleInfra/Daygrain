import SwiftUI
import UIKit
import ImageIO

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var emotionTags: [EmotionTag] = []
    @Published private(set) var fieldbooks: [Fieldbook] = []
    @Published private(set) var reviews: [WeeklyReview] = []
    @Published private(set) var revisits: [RevisitTask] = []
    @Published private(set) var drafts: [JournalDraft] = []
    @Published private(set) var trash: [TrashedEntry] = []
    @Published var storageError: String?
    @Published private(set) var isReadOnly = false

    private let databaseURL: URL
    private let photosURL: URL
    private let audioURL: URL
    private let imageCache = NSCache<NSString, UIImage>()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        // Keep the original directory so a branding update opens the existing journal.
        let root = support.appendingPathComponent("Stillnote", isDirectory: true)
        databaseURL = root.appendingPathComponent("journal.json")
        photosURL = root.appendingPathComponent("Photos", isDirectory: true)
        audioURL = root.appendingPathComponent("Audio", isDirectory: true)
        imageCache.countLimit = 18
        imageCache.totalCostLimit = 48 * 1_024 * 1_024
        do {
            try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                var db = try decoder.decode(JournalDatabase.self, from: Data(contentsOf: databaseURL))
                try Self.validate(db)
                db.version = 2
                apply(db)
                // Upgrade only after the old file has been fully decoded and validated.
                try persist(db)
                try purgeExpiredTrash()
            } else {
                let db = JournalDatabase()
                try persist(db)
                apply(db)
            }
        } catch {
            isReadOnly = true
            storageError = "Your journal could not be opened. Existing files have been preserved. Reopen Daygrain or restore a backup. \(error.localizedDescription)"
        }
    }

    private var database: JournalDatabase {
        JournalDatabase(entries: entries, emotionTags: emotionTags, fieldbooks: fieldbooks, reviews: reviews, revisits: revisits, drafts: drafts, trash: trash)
    }

    private func persist(_ db: JournalDatabase) throws {
        try encoder.encode(db).write(to: databaseURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func apply(_ db: JournalDatabase) {
        entries = db.entries.sorted { $0.date > $1.date }
        emotionTags = db.emotionTags
        fieldbooks = db.fieldbooks.sorted { $0.createdAt > $1.createdAt }
        reviews = db.reviews.sorted { $0.weekStart > $1.weekStart }
        revisits = db.revisits.sorted { $0.dueDate < $1.dueDate }
        drafts = db.drafts.sorted { $0.updatedAt > $1.updatedAt }
        trash = db.trash.sorted { $0.deletedAt > $1.deletedAt }
    }

    private func commit(_ db: JournalDatabase) throws {
        guard !isReadOnly else { throw JournalError.persistence("The journal is in recovery mode. Restore a backup or reopen the app before making changes.") }
        try persist(db)
        apply(db)
    }

    private func writePhotos(_ photos: [PendingPhoto], into entry: inout JournalEntry, written: inout [URL]) throws {
        for photo in photos {
            let url = photoURL(photo.id)
            if !FileManager.default.fileExists(atPath: url.path) {
                try photo.data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                written.append(url)
            }
            if !entry.photoIDs.contains(photo.id) { entry.photoIDs.append(photo.id) }
        }
    }

    func save(_ original: JournalEntry, newPhotos: [PendingPhoto]) throws {
        var entry = original
        entry.title = entry.title.trimmed
        entry.notes = entry.notes.trimmed
        entry.location = entry.location.trimmed
        entry.trigger = entry.trigger.trimmed
        entry.context = entry.context.trimmed
        entry.updatedAt = Date()
        entry.observations = entry.observations.compactMap { $0.text.trimmed.isEmpty ? nil : SensoryObservation(sense: $0.sense, text: $0.text.trimmed) }
        guard !entry.title.isEmpty else { throw JournalError.persistence("Give your note a title before saving.") }
        guard entry.emotionTagIDs.allSatisfy({ id in emotionTags.contains { $0.id == id } }) else { throw JournalError.missingTag }
        entry.fieldbookIDs.removeAll { id in !fieldbooks.contains { $0.id == id } }
        entry.linkedEntryIDs = Array(Set(entry.linkedEntryIDs.filter { id in id != entry.id && entries.contains { $0.id == id } }))
        var db = database
        var written: [URL] = []
        do {
            try writePhotos(newPhotos, into: &entry, written: &written)
            guard entry.photoIDs.count <= 6 else { throw JournalError.invalidPhoto }
            if let taskID = entry.revisitTaskID, let index = db.revisits.firstIndex(where: { $0.id == taskID }) {
                let source = db.revisits[index].sourceEntryID
                guard db.entries.contains(where: { $0.id == source }) else { throw JournalError.persistence("The original note is in Recently Deleted. Restore it before completing this revisit.") }
                if !entry.linkedEntryIDs.contains(source) { entry.linkedEntryIDs.append(source) }
                db.revisits[index].completedEntryID = entry.id
            }
            db.entries.removeAll { $0.id == entry.id }
            for index in db.entries.indices {
                let id = db.entries[index].id
                if entry.linkedEntryIDs.contains(id) && !db.entries[index].linkedEntryIDs.contains(entry.id) {
                    db.entries[index].linkedEntryIDs.append(entry.id)
                } else if !entry.linkedEntryIDs.contains(id) {
                    db.entries[index].linkedEntryIDs.removeAll { $0 == entry.id }
                }
            }
            db.entries.append(entry)
            db.drafts.removeAll { $0.id == entry.id }
            try commit(db)
            cleanUnusedPhotos()
        } catch {
            written.forEach { try? FileManager.default.removeItem(at: $0) }
            throw error
        }
    }

    func saveDraft(_ original: JournalEntry, newPhotos: [PendingPhoto], isEditing: Bool) throws {
        var entry = original
        entry.emotionTagIDs.removeAll { id in !emotionTags.contains { $0.id == id } }
        entry.fieldbookIDs.removeAll { id in !fieldbooks.contains { $0.id == id } }
        entry.linkedEntryIDs.removeAll { id in !entries.contains { $0.id == id } }
        var db = database
        var written: [URL] = []
        do {
            try writePhotos(newPhotos, into: &entry, written: &written)
            guard entry.photoIDs.count <= 6 else { throw JournalError.invalidPhoto }
            db.drafts.removeAll { $0.id == entry.id }
            db.drafts.append(JournalDraft(entry: entry, isEditingExisting: isEditing))
            try commit(db)
            cleanUnusedPhotos()
        } catch {
            written.forEach { try? FileManager.default.removeItem(at: $0) }
            throw error
        }
    }

    func deleteDraft(_ id: UUID) throws {
        var db = database
        db.drafts.removeAll { $0.id == id }
        try commit(db)
        cleanUnusedPhotos()
    }

    func delete(_ entry: JournalEntry) throws {
        var db = database
        db.entries.removeAll { $0.id == entry.id }
        db.drafts.removeAll { $0.id == entry.id }
        db.trash.removeAll { $0.id == entry.id }
        db.trash.append(TrashedEntry(entry: entry))
        try commit(db)
    }

    func restoreFromTrash(_ item: TrashedEntry) throws {
        var db = database
        guard db.trash.contains(where: { $0.id == item.id }) else { return }
        db.trash.removeAll { $0.id == item.id }
        db.entries.append(item.entry)
        for i in db.entries.indices where item.entry.linkedEntryIDs.contains(db.entries[i].id) {
            if !db.entries[i].linkedEntryIDs.contains(item.id) { db.entries[i].linkedEntryIDs.append(item.id) }
        }
        try commit(db)
    }

    func permanentlyDelete(_ ids: Set<UUID>) throws {
        var db = database
        let removed = ids.intersection(Set(db.trash.map(\.id)))
        db.trash.removeAll { removed.contains($0.id) }
        for index in db.entries.indices { db.entries[index].linkedEntryIDs.removeAll { removed.contains($0) } }
        for index in db.trash.indices { db.trash[index].entry.linkedEntryIDs.removeAll { removed.contains($0) } }
        for index in db.drafts.indices { db.drafts[index].entry.linkedEntryIDs.removeAll { removed.contains($0) } }
        for index in db.reviews.indices { db.reviews[index].highlightedEntryIDs.removeAll { removed.contains($0) } }
        db.revisits.removeAll { removed.contains($0.sourceEntryID) }
        for index in db.revisits.indices {
            if let id = db.revisits[index].completedEntryID, removed.contains(id) { db.revisits[index].completedEntryID = nil }
        }
        try commit(db)
        cleanUnusedPhotos()
    }

    func purgeExpiredTrash() throws {
        let expired = Set(trash.filter { $0.expiresAt <= Date() }.map(\.id))
        if !expired.isEmpty { try permanentlyDelete(expired) }
    }

    func toggleFavorite(_ entry: JournalEntry) {
        var db = database
        guard let index = db.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        db.entries[index].isFavorite.toggle()
        db.entries[index].updatedAt = Date()
        do { try commit(db) } catch { storageError = error.localizedDescription }
    }

    func saveTag(_ original: EmotionTag) throws {
        var tag = original
        tag.name = tag.name.trimmed
        guard !tag.name.isEmpty else { throw JournalError.emptyTag }
        guard !emotionTags.contains(where: { $0.id != tag.id && $0.name.caseInsensitiveCompare(tag.name) == .orderedSame }) else { throw JournalError.duplicateTag }
        var db = database
        if let index = db.emotionTags.firstIndex(where: { $0.id == tag.id }) { db.emotionTags[index] = tag }
        else { db.emotionTags.append(tag) }
        try commit(db)
    }

    func deleteTag(_ tag: EmotionTag) throws {
        var db = database
        db.emotionTags.removeAll { $0.id == tag.id }
        for i in db.entries.indices { db.entries[i].emotionTagIDs.removeAll { $0 == tag.id } }
        for i in db.drafts.indices { db.drafts[i].entry.emotionTagIDs.removeAll { $0 == tag.id } }
        for i in db.trash.indices { db.trash[i].entry.emotionTagIDs.removeAll { $0 == tag.id } }
        try commit(db)
    }

    func saveFieldbook(_ original: Fieldbook) throws {
        var book = original
        book.name = book.name.trimmed
        book.intention = book.intention.trimmed
        guard !book.name.isEmpty else { throw JournalError.persistence("Give your fieldbook a name.") }
        guard !fieldbooks.contains(where: { $0.id != book.id && $0.name.caseInsensitiveCompare(book.name) == .orderedSame }) else { throw JournalError.persistence("A fieldbook with this name already exists.") }
        var db = database
        if let index = db.fieldbooks.firstIndex(where: { $0.id == book.id }) { db.fieldbooks[index] = book }
        else { db.fieldbooks.append(book) }
        try commit(db)
    }

    func deleteFieldbook(_ book: Fieldbook) throws {
        var db = database
        db.fieldbooks.removeAll { $0.id == book.id }
        for i in db.entries.indices { db.entries[i].fieldbookIDs.removeAll { $0 == book.id } }
        for i in db.drafts.indices { db.drafts[i].entry.fieldbookIDs.removeAll { $0 == book.id } }
        for i in db.trash.indices { db.trash[i].entry.fieldbookIDs.removeAll { $0 == book.id } }
        try commit(db)
    }

    func setMembership(entryIDs: Set<UUID>, bookID: UUID) throws {
        guard fieldbooks.contains(where: { $0.id == bookID }) else { return }
        var db = database
        for index in db.entries.indices {
            let wasMember = db.entries[index].fieldbookIDs.contains(bookID)
            db.entries[index].fieldbookIDs.removeAll { $0 == bookID }
            if entryIDs.contains(db.entries[index].id) { db.entries[index].fieldbookIDs.append(bookID) }
            if wasMember != entryIDs.contains(db.entries[index].id) { db.entries[index].updatedAt = Date() }
        }
        for i in db.drafts.indices where db.drafts[i].isEditingExisting {
            if let note = db.entries.first(where: { $0.id == db.drafts[i].id }) { db.drafts[i].entry.fieldbookIDs = note.fieldbookIDs }
        }
        try commit(db)
    }

    func setLinks(entryID: UUID, linkedIDs: Set<UUID>) throws {
        var db = database
        guard let sourceIndex = db.entries.firstIndex(where: { $0.id == entryID }) else { return }
        let valid = linkedIDs.intersection(Set(entries.map(\.id))).subtracting([entryID])
        db.entries[sourceIndex].linkedEntryIDs = Array(valid)
        for i in db.entries.indices where db.entries[i].id != entryID {
            db.entries[i].linkedEntryIDs.removeAll { $0 == entryID }
            if valid.contains(db.entries[i].id) { db.entries[i].linkedEntryIDs.append(entryID) }
        }
        for i in db.drafts.indices where db.drafts[i].isEditingExisting {
            if let note = db.entries.first(where: { $0.id == db.drafts[i].id }) { db.drafts[i].entry.linkedEntryIDs = note.linkedEntryIDs }
        }
        try commit(db)
    }

    func saveRevisit(_ task: RevisitTask) throws {
        guard entries.contains(where: { $0.id == task.sourceEntryID }), !task.question.trimmed.isEmpty else { throw JournalError.persistence("Choose a note and write a detail to revisit.") }
        var db = database
        db.revisits.removeAll { $0.id == task.id }
        db.revisits.append(task)
        try commit(db)
    }

    func deleteRevisit(_ task: RevisitTask) throws {
        var db = database
        db.revisits.removeAll { $0.id == task.id }
        try commit(db)
    }

    var pendingRevisits: [RevisitTask] {
        revisits.filter { task in
            entries.contains { $0.id == task.sourceEntryID } && (task.completedEntryID == nil || !entries.contains { $0.id == task.completedEntryID })
        }
    }

    func saveReview(_ original: WeeklyReview) throws {
        var review = original
        review.summary = review.summary.trimmed
        review.detailToKeep = review.detailToKeep.trimmed
        review.nextFocus = review.nextFocus.trimmed
        guard !review.summary.isEmpty || !review.detailToKeep.isEmpty || !review.nextFocus.isEmpty else { throw JournalError.persistence("Write at least one part of your review.") }
        review.updatedAt = Date()
        review.highlightedEntryIDs.removeAll { id in !entries.contains { $0.id == id } }
        var db = database
        db.reviews.removeAll { $0.id == review.id || Calendar.current.isDate($0.weekStart, inSameDayAs: review.weekStart) }
        db.reviews.append(review)
        try commit(db)
    }

    func deleteReview(_ review: WeeklyReview) throws {
        var db = database
        db.reviews.removeAll { $0.id == review.id }
        try commit(db)
    }

    func entries(in book: Fieldbook) -> [JournalEntry] { entries.filter { $0.fieldbookIDs.contains(book.id) } }
    func tags(for entry: JournalEntry) -> [EmotionTag] { emotionTags.filter { entry.emotionTagIDs.contains($0.id) } }
    func linkedEntries(for entry: JournalEntry) -> [JournalEntry] { entries.filter { entry.linkedEntryIDs.contains($0.id) } }
    func entries(on date: Date) -> [JournalEntry] { entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } }
    func entries(inWeek date: Date) -> [JournalEntry] { entries.filter { $0.date >= ReviewCalendar.start(of: date) && $0.date < ReviewCalendar.end(of: date) } }
    func review(for date: Date) -> WeeklyReview? { reviews.first { Calendar.current.isDate($0.weekStart, inSameDayAs: ReviewCalendar.start(of: date)) } }

    var currentStreak: Int {
        let calendar = Calendar.current
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: Date())
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while days.contains(day) { count += 1; day = calendar.date(byAdding: .day, value: -1, to: day)! }
        return count
    }

    func image(for id: String, thumbnail: Bool = false) -> UIImage? {
        let cacheKey = "\(id)-\(thumbnail ? "thumb" : "full")" as NSString
        if let cached = imageCache.object(forKey: cacheKey) { return cached }
        let image: UIImage
        if thumbnail {
            guard let source = CGImageSourceCreateWithURL(photoURL(id) as CFURL, nil),
                  let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: 480, kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { return nil }
            image = UIImage(cgImage: cg)
        } else {
            guard let full = UIImage(contentsOfFile: photoURL(id).path) else { return nil }
            image = full
        }
        imageCache.setObject(image, forKey: cacheKey, cost: Int(image.size.width * image.size.height * image.scale * image.scale * 4))
        return image
    }

    // MARK: Voice journal audio (kept in the app sandbox, per entry, deletable)
    @discardableResult
    func attachAudio(from temporary: URL, to entryID: UUID) throws -> URL {
        let folder = audioURL.appendingPathComponent(entryID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        try FileManager.default.moveItem(at: temporary, to: target)
        return target
    }

    func audioFiles(for entryID: UUID) -> [URL] {
        let folder = audioURL.appendingPathComponent(entryID.uuidString, isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return files.filter { $0.pathExtension == "m4a" }.sorted {
            let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return a < b
        }
    }

    func deleteAudio(_ url: URL) {
        guard url.standardizedFileURL.path.hasPrefix(audioURL.standardizedFileURL.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func photoURL(_ id: String) -> URL { photosURL.appendingPathComponent(id).appendingPathExtension("jpg") }
    private func allPhotoIDs(_ db: JournalDatabase) -> Set<String> { Set((db.entries + db.drafts.map(\.entry) + db.trash.map(\.entry)).flatMap(\.photoIDs)) }

    private func cleanUnusedPhotos() {
        let used = allPhotoIDs(database)
        guard let files = try? FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil) else { return }
        for file in files where !used.contains(file.deletingPathExtension().lastPathComponent) { try? FileManager.default.removeItem(at: file) }
        // Cached images remain bounded; avoid flushing every thumbnail on each autosave.
    }

    func exportBackup() throws -> Data {
        guard !isReadOnly else { throw JournalError.persistence("Restore or reopen your journal before exporting a backup.") }
        var photos: [String: Data] = [:]
        for id in allPhotoIDs(database) {
            guard let data = try? Data(contentsOf: photoURL(id)) else { throw JournalError.missingPhoto }
            photos[id] = data
        }
        let data = try encoder.encode(JournalBackup(database: database, photos: photos))
        guard data.count <= 150 * 1_024 * 1_024 else { throw JournalError.fileTooLarge }
        return data
    }

    func importBackup(from url: URL) throws -> Int {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 150 * 1_024 * 1_024 else { throw JournalError.fileTooLarge }
        let data = try Data(contentsOf: url)
        guard data.count <= 150 * 1_024 * 1_024 else { throw JournalError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(JournalBackup.self, from: data)
        guard backup.format == "com.stillnote.backup" else { throw JournalError.invalidBackup }
        guard (1...2).contains(backup.version) else { throw JournalError.unsupportedVersion }
        try Self.validate(backup.database)
        var db = backup.database
        db.version = 2
        var mapping: [String: String] = [:]
        var written: [URL] = []
        do {
            for id in allPhotoIDs(db) {
                guard let data = backup.photos[id], data.count <= 15 * 1_024 * 1_024,
                      let image = UIImage(data: data), let normalized = PhotoProcessor.jpeg(from: image) else { throw JournalError.invalidBackup }
                let name = UUID().uuidString
                let target = photoURL(name)
                try normalized.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                mapping[id] = name
                written.append(target)
            }
            for i in db.entries.indices { db.entries[i].photoIDs = db.entries[i].photoIDs.compactMap { mapping[$0] } }
            for i in db.drafts.indices { db.drafts[i].entry.photoIDs = db.drafts[i].entry.photoIDs.compactMap { mapping[$0] } }
            for i in db.trash.indices { db.trash[i].entry.photoIDs = db.trash[i].entry.photoIDs.compactMap { mapping[$0] } }
            try persist(db)
            apply(db)
            isReadOnly = false
            cleanUnusedPhotos()
            return entries.count
        } catch {
            written.forEach { try? FileManager.default.removeItem(at: $0) }
            throw error
        }
    }

    func readableExport(book: Fieldbook? = nil) -> Data {
        let selected = book.map { entries(in: $0) } ?? entries
        var lines = ["DAYGRAIN — \(book?.name ?? "PERSONAL JOURNAL")", "Exported \(EnglishDate.string(Date(), template: "MMMM d yyyy"))", ""]
        if let book = book { lines += ["Focus: \(book.intention)", ""] }
        for entry in selected.sorted(by: { $0.date < $1.date }) {
            lines += ["────────────────────────", entry.title, "\(EnglishDate.string(entry.date, template: "MMMM d yyyy h:mm a")) · \(entry.kind.title)", "ID: \(entry.id)"]
            if !entry.location.isEmpty { lines.append("Place: \(entry.location)") }
            for item in entry.observations { lines.append("\(item.sense.title): \(item.text)") }
            if entry.kind == .emotion {
                lines += ["Labels: \(tags(for: entry).map(\.name).joined(separator: ", "))", "Event: \(entry.trigger)", "Context: \(entry.context)", "Energy: \(entry.energy)/5"]
            }
            lines += ["Intensity: \(entry.intensity)/5", entry.notes]
            let books = fieldbooks.filter { entry.fieldbookIDs.contains($0.id) }.map(\.name)
            if !books.isEmpty { lines.append("Fieldbooks: \(books.joined(separator: ", "))") }
            if !entry.linkedEntryIDs.isEmpty { lines.append("Linked notes: \(entry.linkedEntryIDs.map(\.uuidString).joined(separator: ", "))") }
            lines += ["Attached photos: \(entry.photoIDs.count) (included in JSON backup)", ""]
        }
        if book == nil {
            lines += ["WEEKLY REVIEWS", ""]
            for review in reviews.reversed() {
                lines += ["Week of \(EnglishDate.string(review.weekStart, template: "MMMM d yyyy"))", "Summary: \(review.summary)", "Detail to keep: \(review.detailToKeep)", "Next focus: \(review.nextFocus)", "Highlights: \(review.highlightedEntryIDs.map(\.uuidString).joined(separator: ", "))", ""]
            }
        }
        return Data(lines.joined(separator: "\n").utf8)
    }

    func eraseJournal() throws {
        let db = JournalDatabase()
        try persist(db)
        apply(db)
        isReadOnly = false
        imageCache.removeAllObjects()
        cleanUnusedPhotos()
    }

    private static func validate(_ db: JournalDatabase) throws {
        guard (1...2).contains(db.version) else { throw JournalError.unsupportedVersion }
        func unique<T: Hashable>(_ values: [T]) -> Bool { Set(values).count == values.count }
        let all = db.entries + db.trash.map(\.entry)
        let noteIDs = Set(all.map(\.id))
        let tagIDs = Set(db.emotionTags.map(\.id))
        let bookIDs = Set(db.fieldbooks.map(\.id))
        let activeIDs = Set(db.entries.map(\.id))
        guard all.allSatisfy({ !$0.title.trimmed.isEmpty }), unique(all.map(\.id)), unique(db.drafts.map(\.id)), unique(db.emotionTags.map(\.id)),
              unique(db.emotionTags.map { $0.name.trimmed.lowercased() }), unique(db.fieldbooks.map(\.id)),
              unique(db.fieldbooks.map { $0.name.trimmed.lowercased() }), unique(db.revisits.map(\.id)), unique(db.reviews.map(\.id)) else { throw JournalError.invalidBackup }
        for tag in db.emotionTags {
            guard !tag.name.trimmed.isEmpty, tag.name.count <= 30, tag.colorHex.count == 6,
                  UInt32(tag.colorHex, radix: 16) != nil, EmotionTag.symbols.contains(tag.symbol) else { throw JournalError.invalidBackup }
        }
        for book in db.fieldbooks {
            guard !book.name.trimmed.isEmpty, book.name.count <= 60, book.colorHex.count == 6,
                  UInt32(book.colorHex, radix: 16) != nil, EmotionTag.symbols.contains(book.symbol), !book.focusSenses.isEmpty, unique(book.focusSenses) else { throw JournalError.invalidBackup }
        }
        for draft in db.drafts {
            guard (draft.isEditingExisting ? activeIDs.contains(draft.id) : !noteIDs.contains(draft.id)) else { throw JournalError.invalidBackup }
        }
        for entry in all + db.drafts.map(\.entry) {
            let isDraft = db.drafts.contains { $0.id == entry.id }
            guard (isDraft || !entry.title.trimmed.isEmpty), (1...5).contains(entry.intensity), (1...5).contains(entry.energy),
                  entry.photoIDs.count <= 6, unique(entry.photoIDs), entry.photoIDs.allSatisfy({ UUID(uuidString: $0) != nil }),
                  unique(entry.emotionTagIDs), entry.emotionTagIDs.allSatisfy({ tagIDs.contains($0) }),
                  unique(entry.fieldbookIDs), entry.fieldbookIDs.allSatisfy({ bookIDs.contains($0) }),
                  unique(entry.observations.map(\.sense)), unique(entry.linkedEntryIDs), !entry.linkedEntryIDs.contains(entry.id),
                  entry.linkedEntryIDs.allSatisfy({ noteIDs.contains($0) }) else { throw JournalError.invalidBackup }
        }
        for task in db.revisits {
            guard noteIDs.contains(task.sourceEntryID), !task.question.trimmed.isEmpty,
                  task.completedEntryID.map({ noteIDs.contains($0) }) ?? true else { throw JournalError.invalidBackup }
        }
        for review in db.reviews {
            guard unique(review.highlightedEntryIDs), review.highlightedEntryIDs.allSatisfy({ noteIDs.contains($0) }) else { throw JournalError.invalidBackup }
        }
    }
}
