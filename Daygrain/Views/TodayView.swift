import SwiftUI

@MainActor
struct TodayView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.scenePhase) private var scenePhase
    @Binding var selectedTab: AppTab
    @State private var selectedDate = Date()
    @State private var followsToday = true
    @State private var editor: JournalKind?
    @State private var voiceEditor = false
    @State private var showDatePicker = false
    @State private var composer: ComposerRequest?
    @State private var showReview = false
    private var dayEntries: [JournalEntry] { store.entries(on: selectedDate) }
    private var dueRevisit: RevisitTask? {
        store.pendingRevisits.first { Calendar.current.startOfDay(for: $0.dueDate) <= Calendar.current.startOfDay(for: Date()) }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    hero
                    weekStrip
                    captureActions
                    dailyPages
                    workflowBoard
                    Label("A little of the day, kept.", systemImage: "lock.shield")
                        .font(.caption2).foregroundColor(Palette.secondary).frame(maxWidth: .infinity).padding(.vertical, 8)
                }.padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 22)
                    .frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.pageBackground().navigationBarHidden(true)
                .sheet(item: $editor) { EntryEditorView(kind: $0, initialDate: selectedDate) }
                .sheet(isPresented: $voiceEditor) { EntryEditorView(kind: .sensory, initialDate: selectedDate, startWithVoice: true) }
                .sheet(item: $composer) { ComposerSheet(request: $0) }
                .sheet(isPresented: $showReview) { ReviewEditor(week: Date()) }
                .sheet(isPresented: $showDatePicker) {
                    NavigationView {
                        DatePicker("Journal date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical).padding().pageBackground()
                            .navigationTitle("Choose a day").navigationBarTitleDisplayMode(.inline)
                            .onChange(of: selectedDate) { followsToday = Calendar.current.isDateInToday($0) }
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showDatePicker = false } } }
                    }.navigationViewStyle(.stack)
                }
                .onChange(of: scenePhase) { if $0 == .active && followsToday { selectedDate = Date() } }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in if followsToday { selectedDate = Date() } }
        }.navigationViewStyle(.stack)
    }

    private var header: some View {
        HStack(spacing: 11) {
            BrandMark(size: 41)
            VStack(alignment: .leading, spacing: 2) {
                Text("Daygrain").font(.system(size: 27, weight: .medium, design: .serif)).foregroundColor(Palette.text)
                Text("YOUR FIELD JOURNAL").tracking(1.5).font(.system(size: 8, weight: .semibold)).foregroundColor(Palette.secondary)
            }
            Spacer()
            Button { showDatePicker = true } label: { Image(systemName: "calendar") }
                .buttonStyle(RoundIconButtonStyle(tone: .honey)).accessibilityLabel("Choose journal date")
        }
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(LinearGradient(colors: [Palette.hero, Palette.pageApricot, Palette.pageLavender], startPoint: .topLeading, endPoint: .bottomTrailing))
            GeometryReader { proxy in
                GrainBloom().fill(LinearGradient(colors: [Palette.gold.opacity(0.20), Palette.plum.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 172, height: 172).rotationEffect(.degrees(12))
                    .position(x: proxy.size.width - 15, y: proxy.size.height - 29)
                Circle().stroke(Palette.gold.opacity(0.12), lineWidth: 1).frame(width: 210, height: 210).position(x: proxy.size.width - 15, y: proxy.size.height - 29)
            }.clipped().accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 17) {
                Label {
                    Text(EnglishDate.string(selectedDate, template: "EEEE MMM d").uppercased()).tracking(1.2)
                } icon: { Image(systemName: Calendar.current.isDateInToday(selectedDate) ? "sun.max" : "calendar") }
                .font(.system(size: 10, weight: .medium)).foregroundColor(Palette.secondary)
                Text("Let the day\nleave a trace.").font(.system(size: 33, weight: .regular, design: .serif)).lineSpacing(1).foregroundColor(Palette.text)
                HStack(spacing: 15) {
                    Label("\(dayEntries.count) kept", systemImage: "book.closed").foregroundColor(Palette.accent)
                        .padding(.horizontal, 10).padding(.vertical, 7).background(Palette.surface.opacity(0.75)).clipShape(Capsule())
                    Label("\(Set(dayEntries.flatMap(\.senses)).count) senses", systemImage: "sparkles").foregroundColor(Palette.sage)
                        .padding(.horizontal, 10).padding(.vertical, 7).background(Palette.surface.opacity(0.75)).clipShape(Capsule())
                }.font(.caption)
            }.padding(24)
        }.fixedSize(horizontal: false, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 27, style: .continuous).stroke(Palette.gold.opacity(0.18), lineWidth: 1))
    }

    private var captureActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "Keep a moment", subtitle: "Start with a detail or a feeling.")
            HStack(spacing: 11) {
                Button { editor = .sensory } label: { Label("Sensory note", systemImage: "sparkles") }.buttonStyle(FilledButtonStyle())
                Button { editor = .emotion } label: { Label("Emotion note", systemImage: "heart") }.buttonStyle(FilledButtonStyle(tone: .lavender))
            }
            Button { voiceEditor = true } label: { Label("Speak", systemImage: "mic") }
                .buttonStyle(QuietButtonStyle(tone: .honey)).accessibilityLabel("Speak a voice journal")
        }
    }

    private var dailyPages: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeading(title: Calendar.current.isDateInToday(selectedDate) ? "Today's pages" : EnglishDate.string(selectedDate, template: "MMMM d"))
                Button { selectedTab = .journal } label: { Label("Journal", systemImage: "arrow.up.right").font(.caption.weight(.semibold)) }
            }
            if dayEntries.isEmpty {
                EmptyState(symbol: "text.book.closed", title: "An open page", message: "Choose a sense or name a feeling. The details you keep will find a home here.").surface(padding: 0, tint: Palette.sage)
            } else {
                ForEach(dayEntries) { entry in
                    NavigationLink { EntryDetailView(entryID: entry.id) } label: { EntryCard(entry: entry) }.buttonStyle(.plain)
                }
            }
        }
    }

    private var workflowBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Pick up the thread", subtitle: "A small next step for your journal.")
            if !store.drafts.isEmpty {
                NavigationLink { DraftsView() } label: {
                    SettingsRow(symbol: "square.and.pencil", title: "An unfinished page", subtitle: "\(store.drafts.count) saved \(store.drafts.count == 1 ? "draft" : "drafts") to return to")
                }.buttonStyle(.plain).surface(padding: 15)
            }
            if let task = dueRevisit, let source = store.entries.first(where: { $0.id == task.sourceEntryID }) {
                VStack(alignment: .leading, spacing: 13) {
                    Label("READY TO REVISIT", systemImage: "arrow.triangle.2.circlepath").font(.system(size: 10, weight: .semibold)).foregroundColor(Palette.gold)
                    Text(task.question).font(.system(.headline, design: .serif)).foregroundColor(Palette.text)
                    Text(source.title).font(.caption).foregroundColor(Palette.secondary)
                    Button {
                        if let draft = store.drafts.first(where: { $0.entry.revisitTaskID == task.id }) { composer = ComposerRequest(entry: draft.entry, draft: draft) }
                        else { composer = .revisit(task, source: source) }
                    } label: { Label("Return to this detail", systemImage: "square.and.pencil") }.buttonStyle(QuietButtonStyle(tone: .honey))
                }.surface(tint: Palette.gold)
            }
            if let focus = store.reviews.first(where: { !$0.nextFocus.isEmpty })?.nextFocus {
                VStack(alignment: .leading, spacing: 12) {
                    Label { Text("YOUR NEXT OBSERVATION FOCUS").tracking(0.8) } icon: { Image(systemName: "arrow.turn.down.right") }
                        .font(.system(size: 10, weight: .medium)).foregroundColor(Palette.sage)
                    Text(focus).font(.system(.headline, design: .serif)).foregroundColor(Palette.text)
                    Button { composer = ComposerRequest(entry: JournalEntry(kind: .sensory, title: String(focus.prefix(120)))) } label: { Label("Follow this focus", systemImage: "plus") }.buttonStyle(QuietButtonStyle(tone: .sage))
                }.surface(tint: Palette.sage)
            }
            Button { showReview = true } label: {
                SettingsRow(symbol: "rectangle.stack", title: "Gather the week", subtitle: "\(store.entries(inWeek: Date()).count) notes · \(store.review(for: Date()) == nil ? "Write your review" : "Your review is saved")", color: Palette.plum)
            }.buttonStyle(.plain).surface(padding: 15, tint: Palette.plum)
            if let book = store.fieldbooks.first(where: { !$0.isArchived }) {
                NavigationLink { FieldbookDetailView(bookID: book.id) } label: {
                    SettingsRow(symbol: book.symbol, title: book.name, subtitle: "Continue your fieldbook · \(store.entries(in: book).count) notes", color: Color(hex: book.colorHex))
                }.buttonStyle(.plain).surface(padding: 15, tint: Color(hex: book.colorHex))
            } else {
                Button { selectedTab = .fieldbooks } label: { Label("Start a personal fieldbook", systemImage: "books.vertical") }.buttonStyle(QuietButtonStyle(tone: .sage))
            }
            HStack {
                NavigationLink { RevisitQueueView() } label: { Label("Revisits \(store.pendingRevisits.count)", systemImage: "arrow.triangle.2.circlepath").foregroundColor(Palette.gold) }
                Spacer()
                NavigationLink { ReviewLibraryView() } label: { Label("Past reviews", systemImage: "rectangle.stack").foregroundColor(Palette.plum) }
            }.font(.caption).foregroundColor(Palette.accent).padding(.vertical, 5)
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 5) {
            ForEach(Calendar.current.daysEndingToday(7), id: \.self) { date in
                let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let count = store.entries(on: date).count
                Button { selectedDate = date; followsToday = Calendar.current.isDateInToday(date) } label: {
                    VStack(spacing: 8) {
                        Text(EnglishDate.string(date, template: "EEEEE")).font(.system(size: 10, weight: .medium))
                        Text(EnglishDate.string(date, template: "d")).font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Circle().fill(count > 0 ? (selected ? .white : Palette.accent) : Color.clear).frame(width: 4, height: 4)
                    }.foregroundColor(selected ? .white : Palette.secondary).frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background {
                            if selected { JournalTone.clay.gradient } else { Palette.surface }
                        }.clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(selected ? Color.white.opacity(0.20) : Palette.line.opacity(0.75), lineWidth: 1))
                }.buttonStyle(.plain).accessibilityLabel("\(EnglishDate.string(date, template: "MMMM d EEEE")), \(count) notes").accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
