import SwiftUI

private struct ReviewRequest: Identifiable { let date: Date; var id: Date { date } }

@MainActor
struct ReviewLibraryView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var selectedWeek = ReviewCalendar.start(of: Date())
    @State private var editor: ReviewRequest?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(title: "Turn your notes into a chapter.", subtitle: "Choose highlights, write your own summary, and carry an observation focus into another week.")
                VStack(spacing: 17) {
                    HStack {
                        Button { changeWeek(-1) } label: { Image(systemName: "chevron.left").frame(width: 36, height: 40) }.accessibilityLabel("Previous week")
                        Spacer()
                        Text("Week of \(EnglishDate.string(selectedWeek, template: "MMM d yyyy"))").font(.subheadline.weight(.semibold))
                        Spacer()
                        Button { changeWeek(1) } label: { Image(systemName: "chevron.right").frame(width: 36, height: 40) }.disabled(selectedWeek >= ReviewCalendar.start(of: Date())).accessibilityLabel("Next week")
                    }
                    DatePicker("Choose any week", selection: $selectedWeek, in: ...Date(), displayedComponents: .date).font(.caption)
                        .onChange(of: selectedWeek) { selectedWeek = ReviewCalendar.start(of: $0) }
                    Text("\(store.entries(inWeek: selectedWeek).count) notes in this week").font(.caption).foregroundColor(Palette.secondary)
                    Button { editor = ReviewRequest(date: selectedWeek) } label: { Text(store.review(for: selectedWeek) == nil ? "Write this week's review" : "Open this week's review") }.buttonStyle(FilledButtonStyle(tone: .lavender))
                }.surface(tint: Palette.plum)
                SectionHeading(title: "Your saved reviews", subtitle: "Every review stays editable.")
                if store.reviews.isEmpty { EmptyState(symbol: "rectangle.stack", title: "The chapter is yours to write", message: "A review can be written at any time. There is no minimum number of notes and no waiting period.") }
                ForEach(store.reviews) { review in
                    Button { editor = ReviewRequest(date: review.weekStart) } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Week of \(EnglishDate.string(review.weekStart, template: "MMM d yyyy"))", systemImage: "rectangle.stack").font(.subheadline.weight(.semibold)).foregroundColor(Palette.text)
                            if !review.summary.isEmpty { Text(review.summary).font(.subheadline).foregroundColor(Palette.secondary).lineLimit(3) }
                            if !review.nextFocus.isEmpty { Label(review.nextFocus, systemImage: "arrow.turn.down.right").font(.caption).foregroundColor(Palette.accent).lineLimit(2) }
                            Text("\(review.highlightedEntryIDs.count) highlights").font(.caption2).foregroundColor(Palette.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).surface()
                    }.buttonStyle(.plain)
                }
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Weekly reviews").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editor) { ReviewEditor(week: $0.date) }
    }
    private func changeWeek(_ value: Int) { selectedWeek = ReviewCalendar.calendar.date(byAdding: .day, value: value * 7, to: selectedWeek)! }
}

@MainActor
struct ReviewEditor: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var review: WeeklyReview
    @State private var original: WeeklyReview
    @State private var loaded = false
    @State private var error: String?
    @State private var confirmDiscard = false
    @State private var confirmDelete = false
    init(week: Date) {
        let review = WeeklyReview(weekStart: ReviewCalendar.start(of: week))
        _review = State(initialValue: review)
        _original = State(initialValue: review)
    }
    private var notes: [JournalEntry] { store.entries(inWeek: review.weekStart) }
    private var canSave: Bool { !review.summary.trimmed.isEmpty || !review.detailToKeep.trimmed.isEmpty || !review.nextFocus.trimmed.isEmpty }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionHeading(title: "Week of \(EnglishDate.string(review.weekStart, template: "MMMM d yyyy"))", subtitle: "\(notes.count) notes · A review written entirely by you.")
                    if let previous = store.reviews.first(where: { $0.weekStart < review.weekStart && !$0.nextFocus.isEmpty }) {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("From your previous review", systemImage: "arrow.turn.down.right").font(.caption.weight(.semibold)).foregroundColor(Palette.accent)
                            Text(previous.nextFocus).font(.subheadline).foregroundColor(Palette.text)
                        }.frame(maxWidth: .infinity, alignment: .leading).surface()
                    }
                    reviewField("The week's summary", placeholder: "The places, events, and details that filled this week…", text: $review.summary)
                    reviewField("A detail to keep", placeholder: "A sound, a flavor, a conversation, or a moment you want to remember…", text: $review.detailToKeep)
                    reviewField("Next observation focus", placeholder: "A detail or place you want to notice next time…", text: $review.nextFocus)
                    SectionHeading(title: "Choose your highlights", subtitle: "Select notes to keep alongside this review. Tap a title to read the original.")
                    if notes.isEmpty { Text("No notes in this week yet. You can still save your own review.").font(.subheadline).foregroundColor(Palette.secondary) }
                    ForEach(notes) { entry in
                        HStack(spacing: 12) {
                            Button {
                                if review.highlightedEntryIDs.contains(entry.id) { review.highlightedEntryIDs.removeAll { $0 == entry.id } }
                                else { review.highlightedEntryIDs.append(entry.id) }
                            } label: { Image(systemName: review.highlightedEntryIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle").font(.title3).frame(width: 36, height: 44) }.accessibilityLabel("Highlight \(entry.title)").accessibilityAddTraits(review.highlightedEntryIDs.contains(entry.id) ? .isSelected : [])
                            NavigationLink { EntryDetailView(entryID: entry.id) } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(entry.title).font(.subheadline.weight(.semibold)).foregroundColor(Palette.text)
                                    Text(EnglishDate.string(entry.date, template: "EEEE MMM d")).font(.caption).foregroundColor(Palette.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.surface(padding: 12)
                    }
                    Button(action: save) { Text("Save review") }.buttonStyle(FilledButtonStyle(tone: .lavender)).disabled(!canSave || store.isReadOnly)
                    if store.reviews.contains(where: { $0.id == review.id }) {
                        Button("Delete this review", role: .destructive) { confirmDelete = true }.font(.caption).frame(maxWidth: .infinity)
                    }
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.pageBackground().navigationTitle("Weekly review").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if review != original { confirmDiscard = true } else { dismiss() } } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave || store.isReadOnly) }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { dismissKeyboard() } }
                }
                .interactiveDismissDisabled(review != original)
                .onAppear {
                    guard !loaded else { return }
                    if let saved = store.review(for: review.weekStart) { review = saved; original = saved }
                    loaded = true
                }
                .confirmationDialog("Discard unsaved review changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                    Button("Discard changes", role: .destructive) { dismiss() }
                    Button("Keep writing", role: .cancel) {}
                }
                .confirmationDialog("Delete this review?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete review", role: .destructive) {
                        do { try store.deleteReview(review); dismiss() } catch { self.error = error.localizedDescription }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { Text("Your journal notes will remain.") }
                .alert("Could not save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }
    private func reviewField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: title)
            EditorTextArea(placeholder: placeholder, text: text).surface(padding: 14, tint: Palette.plum)
        }
    }
    private func save() {
        do { try store.saveReview(review); dismiss() } catch { self.error = error.localizedDescription }
    }
}

@MainActor
struct RevisitEditor: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var task: RevisitTask
    @State private var original: RevisitTask
    @State private var confirmDiscard = false
    @State private var error: String?
    init(sourceID: UUID, existing: RevisitTask? = nil) {
        let initial = existing ?? RevisitTask(sourceEntryID: sourceID, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, question: "")
        _task = State(initialValue: initial)
        _original = State(initialValue: initial)
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    IconBadge(symbol: "arrow.triangle.2.circlepath", size: 65).frame(maxWidth: .infinity)
                    if let source = store.entries.first(where: { $0.id == task.sourceEntryID }) {
                        SectionHeading(title: source.title, subtitle: "Keep the original as a point of comparison.")
                    }
                    DatePicker("Revisit on", selection: $task.dueDate, displayedComponents: .date).surface(tint: Palette.gold)
                    SectionHeading(title: "What would you like to notice again?", subtitle: "Write a concrete detail, question, or place.")
                    EditorTextArea(placeholder: "e.g. How does the same street sound early in the morning?", text: $task.question).surface(tint: Palette.gold)
                    Text("This appears in your revisit queue. You can return early or reschedule at any time.").font(.caption).foregroundColor(Palette.secondary)
                    Button {
                        do { try store.saveRevisit(task); dismiss() } catch { self.error = error.localizedDescription }
                    } label: { Text("Save revisit") }.buttonStyle(FilledButtonStyle(tone: .honey)).disabled(task.question.trimmed.isEmpty || store.isReadOnly)
                }.padding(22).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }.pageBackground().navigationTitle("Plan a revisit").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if task != original { confirmDiscard = true } else { dismiss() } } } }
                .interactiveDismissDisabled(task != original)
                .confirmationDialog("Discard revisit changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                    Button("Discard changes", role: .destructive) { dismiss() }
                    Button("Keep editing", role: .cancel) {}
                }
                .alert("Could not save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }
}

@MainActor
struct RevisitQueueView: View {
    @EnvironmentObject private var store: JournalStore
    var fieldbookID: UUID? = nil
    @State private var completed = false
    @State private var composer: ComposerRequest?
    @State private var editing: RevisitTask?
    @State private var removing: RevisitTask?
    @State private var error: String?
    private var tasks: [RevisitTask] {
        let candidates = completed ? store.revisits.filter { task in task.completedEntryID.map { id in store.entries.contains { $0.id == id } } ?? false } : store.pendingRevisits
        return candidates.filter { task in
            guard let id = fieldbookID else { return true }
            return store.entries.first { $0.id == task.sourceEntryID }?.fieldbookIDs.contains(id) ?? false
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                SectionHeading(title: "Go back with fresh eyes.", subtitle: "Return to a moment, record again, and compare the original details.")
                Picker("Revisits", selection: $completed) { Text("Planned").tag(false); Text("Completed").tag(true) }.pickerStyle(.segmented)
                if tasks.isEmpty { EmptyState(symbol: "arrow.triangle.2.circlepath", title: completed ? "More chapters to come" : "A detail worth revisiting?", message: completed ? "A revisit is completed when its new note is saved." : "Open any note and choose Plan a revisit. Give it a date and a detail to look for next time.") }
                ForEach(tasks) { task in
                    if let source = store.entries.first(where: { $0.id == task.sourceEntryID }) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Label(EnglishDate.string(task.dueDate, template: "MMM d yyyy"), systemImage: "calendar").font(.caption).foregroundColor(Palette.secondary)
                                Spacer()
                                Menu {
                                    Button("Reschedule or edit") { editing = task }
                                    Button("Remove revisit", role: .destructive) { removing = task }
                                } label: { Image(systemName: "ellipsis").frame(width: 36, height: 30).accessibilityLabel("Revisit options") }
                            }
                            Text(task.question).font(.system(.headline, design: .rounded)).foregroundColor(Palette.text)
                            NavigationLink { EntryDetailView(entryID: source.id) } label: { Label(source.title, systemImage: "link").font(.caption).foregroundColor(Palette.accent) }
                            if completed, let resultID = task.completedEntryID {
                                NavigationLink { ComparisonView(ids: [source.id, resultID]) } label: { Label("Compare original & revisit", systemImage: "rectangle.split.2x1").font(.subheadline.weight(.medium)) }
                                NavigationLink("Open revisit note") { EntryDetailView(entryID: resultID) }.font(.caption)
                            } else {
                                Button {
                                    if let draft = store.drafts.first(where: { $0.entry.revisitTaskID == task.id }) { composer = ComposerRequest(entry: draft.entry, draft: draft) }
                                    else { composer = .revisit(task, source: source) }
                                } label: { Label("Record a revisit", systemImage: "square.and.pencil") }.buttonStyle(FilledButtonStyle(tone: .honey))
                            }
                        }.surface(tint: Palette.gold)
                    }
                }
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Revisit queue").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $composer) { ComposerSheet(request: $0) }
            .sheet(item: $editing) { RevisitEditor(sourceID: $0.sourceEntryID, existing: $0) }
            .confirmationDialog("Remove this revisit?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }), titleVisibility: .visible) {
                Button("Remove revisit", role: .destructive) {
                    guard let task = removing else { return }
                    do { try store.deleteRevisit(task) } catch { self.error = error.localizedDescription }
                    removing = nil
                }
                Button("Cancel", role: .cancel) { removing = nil }
            } message: { Text("The original note and any completed revisit note will remain.") }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
    }
}
