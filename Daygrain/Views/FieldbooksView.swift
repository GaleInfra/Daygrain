import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct FieldbooksView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var showNew = false
    @State private var showArchived = false
    @State private var query = ""
    private var books: [Fieldbook] {
        store.fieldbooks.filter { $0.isArchived == showArchived && (query.trimmed.isEmpty || ($0.name + " " + $0.intention).localizedCaseInsensitiveContains(query.trimmed)) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeading(title: "Follow a thread through your days.", subtitle: "Collect repeated observations of a place, a season, or an everyday ritual.")
                    Picker("Fieldbooks", selection: $showArchived) { Text("Active").tag(false); Text("Archived").tag(true) }.pickerStyle(.segmented)
                    if books.isEmpty {
                        EmptyState(symbol: "books.vertical", title: showArchived ? "A shelf for finished chapters" : "Start a fieldbook", message: showArchived ? "Archived fieldbooks keep their notes and can be reopened anytime." : "Give a personal theme a home. Add notes over time, then compare what you noticed.")
                        if !showArchived { Button { showNew = true } label: { Label("Create a fieldbook", systemImage: "plus") }.buttonStyle(FilledButtonStyle(tone: .sage)) }
                    }
                    ForEach(books) { book in
                        NavigationLink { FieldbookDetailView(bookID: book.id) } label: { FieldbookCard(book: book) }.buttonStyle(.plain)
                    }
                    NavigationLink { ReviewLibraryView() } label: {
                        SettingsRow(symbol: "rectangle.stack", title: "Weekly reviews", subtitle: "Keep a summary and carry a focus forward", color: Palette.plum)
                    }.buttonStyle(.plain).surface(tint: Palette.plum)
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.pageBackground().navigationTitle("Fieldbooks").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "Search fieldbooks")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showNew = true } label: { Image(systemName: "plus.circle.fill").accessibilityLabel("Create fieldbook") } } }
                .sheet(isPresented: $showNew) { FieldbookEditor() }
        }.navigationViewStyle(.stack)
    }
}

@MainActor
struct FieldbookCard: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.colorScheme) private var colorScheme
    let book: Fieldbook
    var body: some View {
        let notes = store.entries(in: book)
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                IconBadge(symbol: book.symbol, color: Color(hex: book.colorHex), size: 49)
                Spacer()
                if book.isArchived { Image(systemName: "archivebox").foregroundColor(Palette.secondary) }
                Image(systemName: "arrow.up.right").foregroundColor(Color(hex: book.colorHex).readableInk(in: colorScheme))
            }
            Text(book.name).font(.system(.title3, design: .serif).weight(.medium)).foregroundColor(Palette.text)
            if !book.intention.isEmpty { Text(book.intention).font(.subheadline).foregroundColor(Palette.secondary).lineLimit(3) }
            HStack(spacing: 13) {
                Label("\(notes.count) notes", systemImage: "book.closed")
                Label("\(Set(notes.map { Calendar.current.startOfDay(for: $0.date) }).count) days", systemImage: "calendar")
                Spacer()
            }.font(.caption).foregroundColor(Palette.secondary)
            HStack(spacing: 9) {
                ForEach(book.focusSenses) { sense in Image(systemName: sense.symbol).font(.caption).foregroundColor(sense.tint).accessibilityLabel(sense.title) }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).surface(padding: 21, tint: Color(hex: book.colorHex))
    }
}

@MainActor
struct FieldbookDetailView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var editing = false
    @State private var managing = false
    @State private var deleting = false
    @State private var comparing = false
    @State private var selection: [UUID] = []
    @State private var comparison: ComparisonRequest?
    @State private var composer: ComposerRequest?
    @State private var error: String?
    @State private var export = false
    @State private var document = ReadableDocument()
    private var book: Fieldbook? { store.fieldbooks.first { $0.id == bookID } }

    var body: some View {
        Group {
            if let book = book {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        FieldbookCard(book: book)
                        summary(book)
                        ObservationMatrix(book: book)
                        if book.isArchived {
                            Button {
                                var reopened = book
                                reopened.isArchived = false
                                do { try store.saveFieldbook(reopened) } catch { self.error = error.localizedDescription }
                            } label: { Label("Reopen to add observations", systemImage: "archivebox") }.buttonStyle(QuietButtonStyle(tone: .sage))
                        } else { HStack(spacing: 10) {
                            Menu {
                                Button("Sensory note") { composer = .new(kind: .sensory, book: book) }
                                Button("Emotion note") { composer = .new(kind: .emotion, book: book) }
                            } label: { Label("New note", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(FilledButtonStyle(tone: .sage))
                            Button { managing = true } label: { Image(systemName: "text.badge.plus") }.buttonStyle(RoundIconButtonStyle(tone: .sage)).accessibilityLabel("Add or remove existing notes")
                        } }
                        HStack {
                            SectionHeading(title: "Observation timeline")
                            Button(comparing ? "Cancel" : "Compare") { comparing.toggle(); selection = [] }.font(.caption.weight(.semibold)).disabled(store.entries(in: book).count < 2)
                        }
                        if comparing {
                            Text("Choose two notes to place their original details side by side.").font(.caption).foregroundColor(Palette.secondary)
                            Button { comparison = ComparisonRequest(ids: selection) } label: { Text("Compare \(selection.count) / 2 notes") }.buttonStyle(FilledButtonStyle(tone: .lavender)).disabled(selection.count != 2)
                        }
                        if store.entries(in: book).isEmpty {
                            EmptyState(symbol: "leaf", title: "The first observation is yours", message: "Add an existing note or make a new one. Your timeline and sense coverage grow with your own observations.")
                        }
                        ForEach(store.entries(in: book)) { entry in
                            if comparing {
                                Button { toggle(entry.id) } label: {
                                    HStack(alignment: .top, spacing: 9) {
                                        Image(systemName: selection.contains(entry.id) ? "checkmark.circle.fill" : "circle").padding(.top, 20)
                                        EntryCard(entry: entry)
                                    }
                                }.buttonStyle(.plain).accessibilityAddTraits(selection.contains(entry.id) ? .isSelected : [])
                            } else {
                                NavigationLink { EntryDetailView(entryID: entry.id) } label: { EntryCard(entry: entry) }.buttonStyle(.plain)
                            }
                        }
                    }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
                }
            } else { EmptyState(symbol: "books.vertical", title: "Fieldbook removed", message: "Your notes are still in Journal.") }
        }.pageBackground().navigationTitle(book?.name ?? "Fieldbook").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { if let book = book { bookMenu(book) } } }
            .sheet(isPresented: $editing) { if let book = book { FieldbookEditor(book: book) } }
            .sheet(isPresented: $managing) { if let book = book { FieldbookMembershipView(book: book) } }
            .sheet(item: $composer) { ComposerSheet(request: $0) }
            .sheet(item: $comparison) { item in NavigationView { ComparisonView(ids: item.ids) }.navigationViewStyle(.stack) }
            .fileExporter(isPresented: $export, document: document, contentType: .plainText, defaultFilename: "Daygrain-Fieldbook") { result in
                if case .failure(let failure) = result, (failure as NSError).code != NSUserCancelledError { error = failure.localizedDescription }
            }
            .confirmationDialog("Delete this fieldbook?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete fieldbook", role: .destructive) {
                    guard let book = book else { return }
                    do { try store.deleteFieldbook(book); dismiss() } catch { self.error = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Its notes remain in Journal. Only the fieldbook and its membership are removed.") }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
    }

    private func toggle(_ id: UUID) {
        if selection.contains(id) { selection.removeAll { $0 == id } }
        else if selection.count < 2 { selection.append(id) }
    }

    private func bookMenu(_ book: Fieldbook) -> some View {
        Menu {
            Button("Edit fieldbook") { editing = true }
            Button("Manage notes") { managing = true }
            Button(book.isArchived ? "Reopen fieldbook" : "Archive fieldbook") {
                var updated = book
                updated.isArchived.toggle()
                do { try store.saveFieldbook(updated) } catch { self.error = error.localizedDescription }
            }
            Button("Export readable fieldbook") { document = ReadableDocument(data: store.readableExport(book: book)); export = true }
            Button("Delete fieldbook", role: .destructive) { deleting = true }
        } label: { Image(systemName: "ellipsis.circle").accessibilityLabel("Fieldbook options") }
    }

    private func summary(_ book: Fieldbook) -> some View {
        let notes = store.entries(in: book)
        let sensoryCount = notes.filter { $0.kind == .sensory }.count
        return VStack(alignment: .leading, spacing: 16) {
            SectionHeading(title: "Sense coverage", subtitle: "Sensory notes containing each of your focus senses.")
            ForEach(book.focusSenses) { sense in
                let count = notes.filter { $0.senses.contains(sense) }.count
                HStack {
                    Image(systemName: sense.symbol).foregroundColor(sense.tint).frame(width: 22)
                    Text(sense.title).font(.caption).frame(width: 48, alignment: .leading)
                    GeometryReader { proxy in
                        Capsule().fill(sense.tint.opacity(0.12)).overlay(alignment: .leading) { Capsule().fill(LinearGradient(colors: [sense.tint.opacity(0.65), sense.tint], startPoint: .leading, endPoint: .trailing)).frame(width: proxy.size.width * CGFloat(count) / CGFloat(max(1, sensoryCount))) }
                    }.frame(height: 6)
                    Text("\(count)").font(.caption.monospacedDigit()).foregroundColor(Palette.secondary).frame(width: 26, alignment: .trailing)
                }.accessibilityElement(children: .combine)
            }
            let linked = notes.filter { !store.linkedEntries(for: $0).isEmpty }.count
            Label("\(linked) notes connected to another moment", systemImage: "link").font(.caption).foregroundColor(Palette.secondary)
        }.foregroundColor(Palette.text).surface(tint: Palette.sage)
    }
}

@MainActor
struct FieldbookEditor: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var book: Fieldbook
    @State private var original: Fieldbook
    @State private var confirmDiscard = false
    @State private var error: String?
    private let onSave: ((Fieldbook) -> Void)?
    init(book: Fieldbook = Fieldbook(), onSave: ((Fieldbook) -> Void)? = nil) {
        _book = State(initialValue: book)
        _original = State(initialValue: book)
        self.onSave = onSave
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    IconBadge(symbol: book.symbol, color: Color(hex: book.colorHex), size: 70).frame(maxWidth: .infinity)
                    TextField("Fieldbook name", text: $book.name).font(.title2).padding(16).background(Palette.surface).cornerRadius(14)
                        .onChange(of: book.name) { book.name = String($0.prefix(60)) }
                    SectionHeading(title: "What are you following?", subtitle: "A place, a changing season, or a detail you want to notice again.")
                    EditorTextArea(placeholder: "e.g. The sounds and smells along my walk to work", text: $book.intention).surface()
                    SectionHeading(title: "Focus senses")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading) {
                        ForEach(Sense.allCases) { sense in
                            Button {
                                if book.focusSenses.contains(sense) { book.focusSenses.removeAll { $0 == sense } }
                                else { book.focusSenses.append(sense) }
                            } label: { TagChip(title: sense.title, symbol: sense.symbol, color: sense.tint, selected: book.focusSenses.contains(sense)).frame(minHeight: 44).contentShape(Rectangle()) }.buttonStyle(.plain)
                        }
                    }
                    SectionHeading(title: "Cover color & icon")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(EmotionTag.palette, id: \.self) { color in
                            Button { book.colorHex = color } label: {
                                Circle().fill(Color(hex: color)).frame(width: 38, height: 38).overlay(Image(systemName: "checkmark").foregroundColor(.white).opacity(book.colorHex == color ? 1 : 0))
                            }.accessibilityLabel("Cover color \(EmotionTag.palette.firstIndex(of: color)! + 1)").accessibilityAddTraits(book.colorHex == color ? .isSelected : [])
                        }
                        ForEach(EmotionTag.symbols, id: \.self) { symbol in
                            Button { book.symbol = symbol } label: {
                                    Image(systemName: symbol).frame(maxWidth: .infinity).frame(height: 46).foregroundColor(book.symbol == symbol ? .white : Palette.sage).background(book.symbol == symbol ? JournalTone.sage.action : JournalTone.sage.wash).cornerRadius(12)
                            }.accessibilityLabel(symbol.replacingOccurrences(of: ".fill", with: "")).accessibilityAddTraits(book.symbol == symbol ? .isSelected : [])
                        }
                    }.surface()
                    Button {
                        do { try store.saveFieldbook(book); onSave?(book); dismiss() } catch { self.error = error.localizedDescription }
                    } label: { Text("Save fieldbook") }.buttonStyle(FilledButtonStyle(tone: .sage)).disabled(book.name.trimmed.isEmpty || book.focusSenses.isEmpty || store.isReadOnly)
                }.padding(22).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }.pageBackground().navigationTitle("Your fieldbook").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if book != original { confirmDiscard = true } else { dismiss() } } } }
                .interactiveDismissDisabled(book != original)
                .confirmationDialog("Discard fieldbook changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                    Button("Discard changes", role: .destructive) { dismiss() }
                    Button("Keep editing", role: .cancel) {}
                }
                .alert("Could not save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }
}

@MainActor
private struct FieldbookMembershipView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let book: Fieldbook
    @State private var ids: Set<UUID> = []
    @State private var query = ""
    @State private var error: String?
    @State private var loaded = false
    var body: some View {
        NavigationView {
            List {
                Text("Choose the notes that belong in this fieldbook. Notes can belong to more than one fieldbook.").font(.caption).foregroundColor(Palette.secondary)
                ForEach(store.entries.filter { query.isEmpty || ($0.title + " " + $0.preview).localizedCaseInsensitiveContains(query) }) { entry in
                    Button {
                        if ids.contains(entry.id) { ids.remove(entry.id) } else { ids.insert(entry.id) }
                    } label: {
                        HStack {
                            Image(systemName: ids.contains(entry.id) ? "checkmark.circle.fill" : "circle").foregroundColor(Palette.accent)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.title).foregroundColor(Palette.text)
                                Text(EnglishDate.string(entry.date, template: "MMM d yyyy")).font(.caption).foregroundColor(Palette.secondary)
                            }
                        }
                    }.accessibilityAddTraits(ids.contains(entry.id) ? .isSelected : [])
                }
            }.searchable(text: $query, prompt: "Find notes").navigationTitle("Manage notes").navigationBarTitleDisplayMode(.inline)
                .onAppear { if !loaded { ids = Set(store.entries(in: book).map(\.id)); loaded = true } }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        do { try store.setMembership(entryIDs: ids, bookID: book.id); dismiss() } catch { self.error = error.localizedDescription }
                    } }
                }
                .alert("Could not save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }
}

private struct MatrixSelection: Identifiable {
    let id = UUID()
    let title: String
    let noteIDs: [UUID]
}

@MainActor
private struct ObservationMatrix: View {
    @EnvironmentObject private var store: JournalStore
    let book: Fieldbook
    @State private var selected: MatrixSelection?
    private var notes: [JournalEntry] { store.entries(in: book) }
    private var dates: [Date] { Array(Set(notes.map { Calendar.current.startOfDay(for: $0.date) }).sorted().suffix(7)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            SectionHeading(title: "Observation map", subtitle: "Your last seven recorded days, across your focus senses. Tap a filled cell to open the notes.")
            if dates.isEmpty {
                Text("Each recorded day will become a row in your map.").font(.caption).foregroundColor(Palette.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("DAY").font(.system(size: 9, weight: .semibold)).foregroundColor(Palette.secondary).frame(width: 53, alignment: .leading)
                    ForEach(book.focusSenses) { sense in Image(systemName: sense.symbol).font(.caption).foregroundColor(sense.tint).frame(maxWidth: .infinity).accessibilityLabel(sense.title) }
                }
                ForEach(dates, id: \.self) { date in
                    HStack(spacing: 4) {
                        Text(EnglishDate.string(date, template: "M/d")).font(.caption2.monospacedDigit()).foregroundColor(Palette.secondary).frame(width: 53, alignment: .leading)
                        ForEach(book.focusSenses) { sense in
                            let matched = notes.filter { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.senses.contains(sense) }
                            Button {
                                selected = MatrixSelection(title: "\(sense.title) · \(EnglishDate.string(date, template: "MMM d"))", noteIDs: matched.map(\.id))
                            } label: {
                                Text(matched.isEmpty ? "–" : "\(matched.count)").font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundColor(matched.isEmpty ? Palette.secondary.opacity(0.4) : sense.tint)
                                    .frame(maxWidth: .infinity).frame(height: 34)
                                    .background(matched.isEmpty ? Palette.soft : sense.tint.opacity(0.18)).cornerRadius(9)
                            }.buttonStyle(.plain).disabled(matched.isEmpty)
                                .accessibilityLabel("\(EnglishDate.string(date, template: "MMMM d yyyy")), \(sense.title), \(matched.count) notes")
                        }
                    }
                }
            }
        }.surface()
            .sheet(item: $selected) { item in
                NavigationView {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(store.entries.filter { item.noteIDs.contains($0.id) }) { entry in
                                NavigationLink { EntryDetailView(entryID: entry.id) } label: { EntryCard(entry: entry) }.buttonStyle(.plain)
                            }
                        }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }.pageBackground().navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { selected = nil } } }
                }.navigationViewStyle(.stack)
            }
    }
}

struct ComparisonRequest: Identifiable { let id = UUID(); let ids: [UUID] }

@MainActor
struct ComparisonView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let ids: [UUID]
    private var notes: [JournalEntry] { ids.compactMap { id in store.entries.first { $0.id == id } } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(title: "Look closer, side by side.", subtitle: "Original observations and self-recorded values. Nothing is inferred.")
                if notes.count == 2 {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(notes) { entry in
                            VStack(alignment: .leading, spacing: 10) {
                                TagChip(title: entry.kind.title, symbol: entry.kind.symbol)
                                Text(entry.title).font(.headline)
                                Text(EnglishDate.string(entry.date, template: "MMM d yyyy h:mm a")).font(.caption).foregroundColor(Palette.secondary)
                                if !entry.location.isEmpty { Text(entry.location).font(.caption).foregroundColor(Palette.secondary) }
                            }.frame(maxWidth: .infinity, alignment: .leading).surface(padding: 14)
                        }
                    }
                    ForEach(Sense.allCases) { sense in
                        if notes.contains(where: { $0.senses.contains(sense) }) {
                            compareRow(sense.title, symbol: sense.symbol, values: notes.map { $0.observations.first { $0.sense == sense }?.text ?? "Not recorded" })
                        }
                    }
                    compareRow("Emotion labels", symbol: "tag", values: notes.map { store.tags(for: $0).isEmpty ? "Not recorded" : store.tags(for: $0).map(\.name).joined(separator: ", ") })
                    compareRow("Event & context", symbol: "text.bubble", values: notes.map { [$0.trigger, $0.context].filter { !$0.isEmpty }.joined(separator: "\n") })
                    compareRow("Recorded intensity", symbol: "waveform", values: notes.map { "\($0.intensity) / 5" })
                    compareRow("Recorded energy", symbol: "bolt", values: notes.map { $0.kind == .emotion ? "\($0.energy) / 5" : "Not recorded" })
                    compareRow("Personal notes", symbol: "text.alignleft", values: notes.map(\.notes))
                } else { EmptyState(symbol: "rectangle.split.2x1", title: "Choose two available notes", message: "A selected note may be in Recently Deleted.") }
            }.padding(22).foregroundColor(Palette.text).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Compare moments").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    private func compareRow(_ title: String, symbol: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold)).foregroundColor(Palette.accent)
            HStack(alignment: .top, spacing: 15) {
                ForEach(values.indices, id: \.self) { index in
                    Text(values[index].isEmpty ? "Not recorded" : values[index]).font(.subheadline).lineSpacing(5).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).surface()
    }
}
