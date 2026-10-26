import Foundation

enum JournalKind: String, Codable, CaseIterable, Identifiable {
    case sensory, emotion

    var id: String { rawValue }
    var title: String { self == .sensory ? "Sensory" : "Emotion" }
    var symbol: String { self == .sensory ? "sparkles" : "heart.text.square" }
}

enum Sense: String, Codable, CaseIterable, Identifiable {
    case smell, sound, taste, touch, sight

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .smell: return "wind"
        case .sound: return "waveform"
        case .taste: return "cup.and.saucer.fill"
        case .touch: return "hand.raised.fill"
        case .sight: return "eye.fill"
        }
    }
    var prompt: String {
        switch self {
        case .smell: return "Fresh coffee, rain on pavement, a familiar perfume…"
        case .sound: return "A distant train, leaves in the wind, a favorite song…"
        case .taste: return "Something sweet, something new, a comforting meal…"
        case .touch: return "Warm sunlight, soft linen, cool water…"
        case .sight: return "An unexpected color, a small detail, the evening sky…"
        }
    }
    var colorHex: String {
        switch self {
        case .smell: return "587B50"
        case .sound: return "946C27"
        case .taste: return "AC5D3E"
        case .touch: return "A25C76"
        case .sight: return "7D5E99"
        }
    }
}

struct SensoryObservation: Codable, Identifiable, Equatable {
    var sense: Sense
    var text: String
    var id: String { sense.rawValue }
}

struct EmotionTag: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var symbol: String
    var colorHex: String

    static let palette = ["A1533F", "946C27", "4E735B", "795A91", "A25C76", "587B50", "A76442", "587A78", "8C6A93", "A16661", "6D7550", "786557"]
    static let symbols = ["sun.max.fill", "cloud.fill", "sparkles", "heart.fill", "leaf.fill", "bolt.fill", "moon.fill", "drop.fill", "flame.fill", "star.fill", "wind", "circle.grid.cross.fill"]
    static let defaults: [EmotionTag] = [
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000001")!, name: "Content", symbol: "sun.max.fill", colorHex: "A1533F"),
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000002")!, name: "Excited", symbol: "sparkles", colorHex: "946C27"),
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000003")!, name: "Quiet", symbol: "moon.fill", colorHex: "4E735B"),
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000004")!, name: "Overwhelmed", symbol: "cloud.fill", colorHex: "795A91"),
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000005")!, name: "Frustrated", symbol: "bolt.fill", colorHex: "A25C76"),
        EmotionTag(id: UUID(uuidString: "EF22FCB0-5F4E-4000-A000-000000000006")!, name: "Grateful", symbol: "leaf.fill", colorHex: "587B50")
    ]
}

struct JournalEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: JournalKind
    var title: String
    var date: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var notes: String = ""
    var location: String = ""
    var observations: [SensoryObservation] = []
    var emotionTagIDs: [UUID] = []
    var trigger: String = ""
    var context: String = ""
    var intensity: Int = 3
    var energy: Int = 3
    var photoIDs: [String] = []
    var isFavorite: Bool = false
    var fieldbookIDs: [UUID] = []
    var linkedEntryIDs: [UUID] = []
    var revisitTaskID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, kind, title, date, createdAt, updatedAt, notes, location, observations, emotionTagIDs
        case trigger, context, intensity, energy, photoIDs, isFavorite, fieldbookIDs, linkedEntryIDs, revisitTaskID
    }

    var preview: String {
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return notes }
        if kind == .sensory { return observations.map { "\($0.sense.title): \($0.text)" }.joined(separator: " · ") }
        return trigger.isEmpty ? context : trigger
    }

    var senses: [Sense] { observations.map(\.sense) }
}

struct JournalDatabase: Codable {
    var version = 2
    var entries: [JournalEntry] = []
    var emotionTags: [EmotionTag] = EmotionTag.defaults
    var fieldbooks: [Fieldbook] = []
    var reviews: [WeeklyReview] = []
    var revisits: [RevisitTask] = []
    var drafts: [JournalDraft] = []
    var trash: [TrashedEntry] = []

    enum CodingKeys: String, CodingKey { case version, entries, emotionTags, fieldbooks, reviews, revisits, drafts, trash }
}

struct JournalBackup: Codable {
    var format = "com.stillnote.backup"
    var version = 2
    var exportedAt = Date()
    var database: JournalDatabase
    var photos: [String: Data]
}

// Version-one journals remain readable when new workflow fields are introduced.
extension JournalEntry {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(JournalKind.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title)
        date = try c.decode(Date.self, forKey: .date)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        notes = try c.decode(String.self, forKey: .notes)
        location = try c.decode(String.self, forKey: .location)
        observations = try c.decode([SensoryObservation].self, forKey: .observations)
        emotionTagIDs = try c.decode([UUID].self, forKey: .emotionTagIDs)
        trigger = try c.decode(String.self, forKey: .trigger)
        context = try c.decode(String.self, forKey: .context)
        intensity = try c.decode(Int.self, forKey: .intensity)
        energy = try c.decode(Int.self, forKey: .energy)
        photoIDs = try c.decode([String].self, forKey: .photoIDs)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        fieldbookIDs = try c.decodeIfPresent([UUID].self, forKey: .fieldbookIDs) ?? []
        linkedEntryIDs = try c.decodeIfPresent([UUID].self, forKey: .linkedEntryIDs) ?? []
        revisitTaskID = try c.decodeIfPresent(UUID.self, forKey: .revisitTaskID)
    }
}

extension JournalDatabase {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        entries = try c.decode([JournalEntry].self, forKey: .entries)
        emotionTags = try c.decode([EmotionTag].self, forKey: .emotionTags)
        fieldbooks = try c.decodeIfPresent([Fieldbook].self, forKey: .fieldbooks) ?? []
        reviews = try c.decodeIfPresent([WeeklyReview].self, forKey: .reviews) ?? []
        revisits = try c.decodeIfPresent([RevisitTask].self, forKey: .revisits) ?? []
        drafts = try c.decodeIfPresent([JournalDraft].self, forKey: .drafts) ?? []
        trash = try c.decodeIfPresent([TrashedEntry].self, forKey: .trash) ?? []
    }
}

enum JournalError: LocalizedError {
    case invalidBackup, unsupportedVersion, missingPhoto, invalidPhoto, duplicateTag, emptyTag, missingTag, fileTooLarge, persistence(String)

    var errorDescription: String? {
        switch self {
        case .invalidBackup: return "This file is not a valid Daygrain backup."
        case .unsupportedVersion: return "This backup was created by a newer version of Daygrain."
        case .missingPhoto: return "A photo could not be found. Your backup has not been exported."
        case .invalidPhoto: return "A photo could not be saved. Please choose it again."
        case .duplicateTag: return "A label with this name already exists."
        case .emptyTag: return "Give your emotion label a name."
        case .missingTag: return "An emotion label changed while this note was open. Please choose your labels again."
        case .fileTooLarge: return "Backups are limited to 150 MB. This file exceeds that limit."
        case .persistence(let reason): return reason
        }
    }
}

extension Calendar {
    func daysEndingToday(_ count: Int) -> [Date] {
        let today = startOfDay(for: Date())
        return (0..<count).reversed().compactMap { date(byAdding: .day, value: -$0, to: today) }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
