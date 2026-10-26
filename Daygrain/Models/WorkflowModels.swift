import Foundation

struct Fieldbook: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = ""
    var intention = ""
    var symbol = "leaf.fill"
    var colorHex = "4E735B"
    var focusSenses: [Sense] = Sense.allCases
    var createdAt = Date()
    var isArchived = false
}

struct WeeklyReview: Codable, Identifiable, Equatable {
    var id = UUID()
    var weekStart: Date
    var summary = ""
    var detailToKeep = ""
    var nextFocus = ""
    var highlightedEntryIDs: [UUID] = []
    var updatedAt = Date()
}

struct RevisitTask: Codable, Identifiable, Equatable {
    var id = UUID()
    var sourceEntryID: UUID
    var dueDate: Date
    var question: String
    var completedEntryID: UUID?
    var createdAt = Date()
}

struct JournalDraft: Codable, Identifiable, Equatable {
    var entry: JournalEntry
    var isEditingExisting: Bool
    var updatedAt = Date()
    var id: UUID { entry.id }
}

struct TrashedEntry: Codable, Identifiable, Equatable {
    var entry: JournalEntry
    var deletedAt = Date()
    var id: UUID { entry.id }
    var expiresAt: Date { Calendar.current.date(byAdding: .day, value: 30, to: deletedAt) ?? deletedAt }
}

enum ReviewCalendar {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
    static func start(of date: Date) -> Date { calendar.dateInterval(of: .weekOfYear, for: date)!.start }
    static func end(of date: Date) -> Date { calendar.date(byAdding: .day, value: 7, to: start(of: date))! }
}

struct ComposerRequest: Identifiable {
    let id = UUID()
    var entry: JournalEntry
    var draft: JournalDraft?

    static func new(kind: JournalKind, book: Fieldbook? = nil) -> ComposerRequest {
        var entry = JournalEntry(kind: kind, title: "")
        if let book = book { entry.fieldbookIDs = [book.id] }
        return ComposerRequest(entry: entry)
    }

    static func companion(to source: JournalEntry) -> ComposerRequest {
        var entry = JournalEntry(kind: source.kind == .sensory ? .emotion : .sensory, title: source.title, date: source.date)
        entry.location = source.location
        entry.fieldbookIDs = source.fieldbookIDs
        entry.linkedEntryIDs = [source.id]
        return ComposerRequest(entry: entry)
    }

    static func revisit(_ task: RevisitTask, source: JournalEntry) -> ComposerRequest {
        var entry = JournalEntry(kind: source.kind, title: "Revisit: \(source.title)")
        entry.location = source.location
        entry.fieldbookIDs = source.fieldbookIDs
        entry.linkedEntryIDs = [source.id]
        entry.revisitTaskID = task.id
        if source.kind == .sensory { entry.observations = source.senses.map { SensoryObservation(sense: $0, text: "") } }
        return ComposerRequest(entry: entry)
    }
}
