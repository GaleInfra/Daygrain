import SwiftUI

@MainActor
struct DraftsView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var composer: ComposerRequest?
    @State private var removing: JournalDraft?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                SectionHeading(title: "Pick up where you left off.", subtitle: "Note text and selected photo copies are saved as you write. Drafts are separate from your finished journal.")
                if store.drafts.isEmpty { EmptyState(symbol: "square.and.pencil", title: "No unfinished pages", message: "Leave an unfinished note as a draft and return to it here.") }
                ForEach(store.drafts) { draft in
                    HStack(spacing: 11) {
                        Button { composer = ComposerRequest(entry: draft.entry, draft: draft) } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(draft.entry.title.trimmed.isEmpty ? "Untitled \(draft.entry.kind.title.lowercased()) note" : draft.entry.title, systemImage: draft.entry.kind.symbol).font(.headline).foregroundColor(Palette.text)
                                Text(draft.entry.preview).font(.subheadline).foregroundColor(Palette.secondary).lineLimit(2)
                                Text("\(draft.isEditingExisting ? "Unsaved edits" : "New note") · \(draft.entry.photoIDs.count) photos · \(EnglishDate.string(draft.updatedAt, template: "MMM d h:mm a"))").font(.caption2).foregroundColor(Palette.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                        Button(role: .destructive) { removing = draft } label: { Image(systemName: "trash").frame(width: 38, height: 44) }.accessibilityLabel("Discard draft")
                    }.surface()
                }
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Drafts").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $composer) { ComposerSheet(request: $0) }
            .confirmationDialog("Discard this draft?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }), titleVisibility: .visible) {
                Button("Discard draft", role: .destructive) {
                    guard let draft = removing else { return }
                    do { try store.deleteDraft(draft.id) } catch { self.error = error.localizedDescription }
                    removing = nil
                }
                Button("Cancel", role: .cancel) { removing = nil }
            } message: { Text("Unfinished changes and draft-only photo copies will be deleted. An existing saved note will remain.") }
            .alert("Could not discard", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
    }
}

@MainActor
struct RecentlyDeletedView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var deleting: Set<UUID> = []
    @State private var confirm = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeading(title: "Room to change your mind.", subtitle: "Deleted notes and their photo copies stay here for 30 days. Restore them or delete them permanently.")
                if store.trash.isEmpty { EmptyState(symbol: "trash", title: "Nothing here", message: "Notes moved to Recently Deleted will appear here.") }
                ForEach(store.trash) { item in
                    VStack(alignment: .leading, spacing: 15) {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(item.entry.preview).font(.subheadline).textSelection(.enabled)
                                ForEach(item.entry.observations) { observation in Text("\(observation.sense.title): \(observation.text)").font(.caption).textSelection(.enabled) }
                            }.padding(.top, 10).foregroundColor(Palette.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.entry.title).font(.headline).foregroundColor(Palette.text)
                                Text("Expires \(EnglishDate.string(item.expiresAt, template: "MMM d yyyy")) · \(item.entry.photoIDs.count) photos").font(.caption).foregroundColor(Palette.secondary)
                            }
                        }
                        HStack {
                            Button { do { try store.restoreFromTrash(item) } catch { self.error = error.localizedDescription } } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.font(.subheadline.weight(.medium))
                            Spacer()
                            Button("Delete permanently", role: .destructive) { deleting = [item.id]; confirm = true }.font(.caption)
                        }
                    }.surface()
                }
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Recently Deleted").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Empty", role: .destructive) { deleting = Set(store.trash.map(\.id)); confirm = true }.disabled(store.trash.isEmpty) } }
            .onAppear { do { try store.purgeExpiredTrash() } catch { self.error = error.localizedDescription } }
            .confirmationDialog("Permanently delete \(deleting.count) \(deleting.count == 1 ? "note" : "notes")?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Delete permanently", role: .destructive) {
                    do { try store.permanentlyDelete(deleting) } catch { self.error = error.localizedDescription }
                    deleting = []
                }
                Button("Cancel", role: .cancel) { deleting = [] }
            } message: { Text("These notes and unused attached photo copies will be removed. This cannot be undone.") }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
    }
}

@MainActor
struct ComposerSheet: View {
    let request: ComposerRequest
    var body: some View { EntryEditorView(kind: request.entry.kind, seed: request.entry, draft: request.draft) }
}
