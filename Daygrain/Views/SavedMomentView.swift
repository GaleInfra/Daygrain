import SwiftUI

@MainActor
struct SavedMomentView: View {
    @EnvironmentObject private var store: JournalStore
    let entryID: UUID
    let onDone: () -> Void
    @State private var companion: ComposerRequest?
    @State private var planning = false
    @State private var organizing = false
    private var entry: JournalEntry? { store.entries.first { $0.id == entryID } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                if let entry = entry {
                    receipt(entry)
                    SectionHeading(title: "Keep the thread going", subtitle: "Choose a next step, or simply leave this moment here.")
                    nextSteps(entry)
                } else {
                    EmptyState(symbol: "book.closed", title: "Your journal is up to date", message: "This moment may have been moved or restored from a backup.")
                }
                Button(action: onDone) { Label("Done for now", systemImage: "checkmark") }.buttonStyle(FilledButtonStyle(tone: .sage))
            }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Moment kept").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: onDone) } }
            .sheet(item: $companion) { ComposerSheet(request: $0) }
            .sheet(isPresented: $planning) { RevisitEditor(sourceID: entryID) }
            .sheet(isPresented: $organizing) { if let entry = entry { EntryEditorView(kind: entry.kind, existing: entry) } }
    }

    private func receipt(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack {
                BrandMark(size: 61)
                Spacer()
                Label("SAVED ON THIS DEVICE", systemImage: "checkmark.circle.fill").font(.system(size: 9, weight: .semibold)).foregroundColor(Palette.sage)
            }
            Text("A little of the day,\nkept.").font(.system(size: 33, weight: .regular, design: .serif)).foregroundColor(Palette.text)
            Divider()
            NavigationLink { EntryDetailView(entryID: entry.id) } label: {
                HStack(spacing: 13) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.title).font(.system(.headline, design: .serif)).foregroundColor(Palette.text)
                        Text("\(entry.kind.title) · \(EnglishDate.string(entry.date, template: "MMM d h:mm a"))").font(.caption).foregroundColor(Palette.secondary)
                        if !entry.photoIDs.isEmpty { Label("\(entry.photoIDs.count) photos kept", systemImage: "photo").font(.caption2).foregroundColor(Palette.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.up.right").foregroundColor(Palette.accent)
                }
            }.buttonStyle(.plain)
        }.surface(padding: 24, tint: Palette.sage)
    }

    private func nextSteps(_ entry: JournalEntry) -> some View {
        VStack(spacing: 12) {
            if let linked = store.entries.first(where: { entry.linkedEntryIDs.contains($0.id) && $0.kind != entry.kind }) {
                NavigationLink { EntryDetailView(entryID: linked.id) } label: {
                    SettingsRow(symbol: "link", title: "Your companion note", subtitle: linked.title, color: linked.kind.tone.ink)
                }.buttonStyle(.plain).surface(padding: 14, tint: linked.kind.tone.ink)
            } else {
                Button { companion = .companion(to: entry) } label: {
                    SettingsRow(symbol: entry.kind == .sensory ? "heart" : "sparkles", title: entry.kind == .sensory ? "Add the feeling" : "Add a sensory detail", subtitle: "Keep another view of this same moment", color: entry.kind == .sensory ? Palette.plum : Palette.accent)
                }.buttonStyle(.plain).surface(padding: 14, tint: entry.kind == .sensory ? Palette.plum : Palette.accent)
            }
            if store.pendingRevisits.contains(where: { $0.sourceEntryID == entry.id }) {
                NavigationLink { RevisitQueueView() } label: {
                    SettingsRow(symbol: "calendar", title: "Your revisit is planned", subtitle: "Open the queue or return whenever you like", color: Palette.gold)
                }.buttonStyle(.plain).surface(padding: 14, tint: Palette.gold)
            } else {
                Button { planning = true } label: {
                    SettingsRow(symbol: "arrow.triangle.2.circlepath", title: "Notice it again", subtitle: "Choose a detail and a date to revisit", color: Palette.gold)
                }.buttonStyle(.plain).surface(padding: 14, tint: Palette.gold)
            }
            if let book = store.fieldbooks.first(where: { entry.fieldbookIDs.contains($0.id) }) {
                NavigationLink { FieldbookDetailView(bookID: book.id) } label: {
                    SettingsRow(symbol: book.symbol, title: book.name, subtitle: "See this moment in your fieldbook", color: Color(hex: book.colorHex))
                }.buttonStyle(.plain).surface(padding: 14, tint: Color(hex: book.colorHex))
            } else {
                Button { organizing = true } label: {
                    SettingsRow(symbol: "books.vertical", title: "Give it a home", subtitle: "Choose or create a personal fieldbook", color: Palette.sage)
                }.buttonStyle(.plain).surface(padding: 14, tint: Palette.sage)
            }
        }
    }
}
