import SwiftUI

private enum JournalFilter: String, CaseIterable {
    case all = "All notes", sensory = "Sensory", emotion = "Emotion", favorites = "Favorites", photos = "With photos"
    var tone: JournalTone {
        switch self {
        case .all: return .rose
        case .sensory: return .clay
        case .emotion: return .lavender
        case .favorites: return .honey
        case .photos: return .sage
        }
    }
}

@MainActor
struct JournalView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var query = ""
    @State private var filter: JournalFilter = .all
    @State private var sense: Sense?
    @State private var tagID: UUID?
    @State private var oldestFirst = false
    @State private var showCalendar = false
    @State private var selectedDate: Date?
    @State private var editor: JournalKind?

    private var filteredEntries: [JournalEntry] {
        store.entries.filter { entry in
            let kindMatch: Bool
            switch filter {
            case .all: kindMatch = true
            case .sensory: kindMatch = entry.kind == .sensory
            case .emotion: kindMatch = entry.kind == .emotion
            case .favorites: kindMatch = entry.isFavorite
            case .photos: kindMatch = !entry.photoIDs.isEmpty
            }
            let books = store.fieldbooks.filter { entry.fieldbookIDs.contains($0.id) }.map(\.name)
            let haystack = ([entry.title, entry.notes, entry.location, entry.trigger, entry.context] + entry.observations.map(\.text) + store.tags(for: entry).map(\.name) + books).joined(separator: " ")
            return kindMatch && (sense == nil || entry.senses.contains(sense!)) && (tagID == nil || entry.emotionTagIDs.contains(tagID!)) && (query.trimmed.isEmpty || haystack.localizedCaseInsensitiveContains(query.trimmed))
        }.sorted { oldestFirst ? $0.date < $1.date : $0.date > $1.date }
    }

    private var visibleEntries: [JournalEntry] {
        guard showCalendar, let selectedDate = selectedDate else { return filteredEntries }
        return filteredEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var sections: [(date: Date, entries: [JournalEntry])] {
        let grouped = Dictionary(grouping: visibleEntries) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted { oldestFirst ? $0 < $1 : $0 > $1 }.map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your collected moments.").font(.system(size: 27, weight: .regular, design: .serif)).foregroundColor(Palette.text)
                        Text("\(store.entries.count) notes, all in your own words.").font(.subheadline).foregroundColor(Palette.secondary)
                    }
                    filterBar
                    HStack(spacing: 20) {
                        NavigationLink { DraftsView() } label: { Label("Drafts \(store.drafts.count)", systemImage: "square.and.pencil") }
                        NavigationLink { RevisitQueueView() } label: { Label("Revisits \(store.pendingRevisits.count)", systemImage: "arrow.triangle.2.circlepath") }
                    }.font(.caption).foregroundColor(Palette.accent)
                    HStack {
                        Button { withAnimation { showCalendar.toggle(); selectedDate = nil } } label: {
                            Label(showCalendar ? "Hide calendar" : "Calendar", systemImage: "calendar").font(.caption.weight(.medium))
                        }
                        Spacer()
                        Menu {
                            Button { sense = nil; tagID = nil } label: { Label("All details", systemImage: "line.3.horizontal.decrease") }
                            Section("Senses") {
                                ForEach(Sense.allCases) { item in
                                    Button { sense = item; tagID = nil } label: { Label(item.title, systemImage: item.symbol) }
                                }
                            }
                            Section("Emotion labels") {
                                ForEach(store.emotionTags) { tag in
                                    Button { tagID = tag.id; sense = nil } label: { Label(tag.name, systemImage: tag.symbol) }
                                }
                            }
                        } label: {
                            Label(detailFilterTitle, systemImage: "line.3.horizontal.decrease").font(.caption.weight(.medium))
                        }
                        Menu {
                            Button { oldestFirst = false } label: { Label("Newest first", systemImage: oldestFirst ? "circle" : "checkmark.circle.fill") }
                            Button { oldestFirst = true } label: { Label("Oldest first", systemImage: oldestFirst ? "checkmark.circle.fill" : "circle") }
                        } label: { Image(systemName: "arrow.up.arrow.down").font(.caption).padding(.leading, 8).accessibilityLabel("Sort notes") }
                    }.foregroundColor(Palette.accent)
                    if showCalendar {
                        MonthCalendar(selectedDate: $selectedDate, entries: filteredEntries).surface(padding: 16)
                        if selectedDate != nil {
                            Button { selectedDate = nil } label: { Label("Show all dates", systemImage: "xmark.circle.fill").font(.caption) }
                        }
                    }
                    if visibleEntries.isEmpty {
                        EmptyState(symbol: query.isEmpty && filter == .all ? "book.closed" : "magnifyingglass", title: store.entries.isEmpty ? "Your story starts here" : "No matching notes", message: store.entries.isEmpty ? "Save a sensory detail or an emotion. Each little note becomes part of your journal." : "Try another search, label, or date.")
                        if store.entries.isEmpty {
                            Button { editor = .sensory } label: { Label("Create your first note", systemImage: "plus") }.buttonStyle(FilledButtonStyle())
                        } else {
                            Button("Clear filters") { query = ""; filter = .all; sense = nil; tagID = nil; selectedDate = nil }.font(.subheadline).frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(sections, id: \.date) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(dayTitle(section.date)).font(.caption.weight(.semibold)).foregroundColor(Palette.secondary)
                                    Rectangle().fill(Palette.line).frame(height: 1)
                                    Text("\(section.entries.count)").font(.caption2).foregroundColor(Palette.secondary)
                                }.padding(.top, 3)
                                ForEach(section.entries) { entry in
                                    NavigationLink { EntryDetailView(entryID: entry.id) } label: { EntryCard(entry: entry) }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .pageBackground()
            .navigationTitle("Journal").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search moments, labels, places")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { editor = .sensory } label: { Label("Sensory note", systemImage: JournalKind.sensory.symbol) }
                        Button { editor = .emotion } label: { Label("Emotion note", systemImage: JournalKind.emotion.symbol) }
                    } label: { Image(systemName: "plus.circle.fill").font(.title3).accessibilityLabel("New note") }
                }
            }
            .sheet(item: $editor) { kind in EntryEditorView(kind: kind, initialDate: selectedDate ?? Date()) }
            .onChange(of: store.emotionTags) { tags in if let id = tagID, !tags.contains(where: { $0.id == id }) { tagID = nil } }
        }.navigationViewStyle(.stack)
    }

    private var detailFilterTitle: String {
        if let sense = sense { return sense.title }
        if let id = tagID, let tag = store.emotionTags.first(where: { $0.id == id }) { return tag.name }
        return "Details"
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JournalFilter.allCases, id: \.self) { item in
                    Button { filter = item } label: {
                        Text(item.rawValue).font(.system(.caption, design: .rounded).weight(.semibold))
                            .frame(minHeight: 22)
                            .padding(.horizontal, 15).padding(.vertical, 11)
                            .foregroundColor(filter == item ? .white : item.tone.ink)
                            .background {
                                if filter == item { item.tone.gradient } else { item.tone.wash }
                            }.clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(filter == item ? Color.white.opacity(0.18) : item.tone.ink.opacity(0.20), lineWidth: 1))
                    }.buttonStyle(.plain).accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }
        }
    }

    private func dayTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "TODAY" }
        if Calendar.current.isDateInYesterday(date) { return "YESTERDAY" }
        return EnglishDate.string(date, template: "MMMM d yyyy").uppercased()
    }
}

struct MonthCalendar: View {
    @Binding var selectedDate: Date?
    let entries: [JournalEntry]
    @State private var month = Date()
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.locale = Locale(identifier: "en_US")
        result.firstWeekday = 1
        return result
    }
    private var start: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: month))! }
    private var offset: Int { calendar.component(.weekday, from: start) - 1 }
    private var days: Int { calendar.range(of: .day, in: .month, for: month)!.count }
    private var counts: [Date: Int] { Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) }).mapValues(\.count) }

    var body: some View {
        VStack(spacing: 17) {
            HStack {
                Text(EnglishDate.string(month, template: "MMMM yyyy")).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(Palette.text)
                Spacer()
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 32, height: 32) }.accessibilityLabel("Previous month")
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 32, height: 32) }.accessibilityLabel("Next month")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 7) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, label in
                    Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(Palette.secondary).frame(maxWidth: .infinity).accessibilityHidden(true)
                }
                ForEach(0..<(offset + days), id: \.self) { index in
                    if index < offset { Color.clear.frame(height: 44) }
                    else { dayCell(index - offset + 1) }
                }
            }
        }
        .onAppear { if let selectedDate = selectedDate { month = selectedDate } }
    }

    private func dayCell(_ day: Int) -> some View {
        let date = calendar.date(byAdding: .day, value: day - 1, to: start)!
        let selected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let count = counts[calendar.startOfDay(for: date)] ?? 0
        return Button { selectedDate = selected ? nil : date } label: {
            VStack(spacing: 4) {
                Text("\(day)").font(.system(size: 12, weight: selected || calendar.isDateInToday(date) ? .bold : .regular, design: .rounded))
                Circle().fill(count == 0 ? Color.clear : (selected ? .white : Palette.accent)).frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity).frame(height: 44)
            .foregroundColor(selected ? .white : Palette.text)
            .background(selected ? Palette.action : (count > 0 ? Palette.accent.opacity(0.07) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain)
            .accessibilityLabel("\(EnglishDate.string(date, template: "MMMM d yyyy")), \(count) notes")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func changeMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) { month = calendar.date(byAdding: .month, value: delta, to: month)! }
    }
}
