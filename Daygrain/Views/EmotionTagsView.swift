import SwiftUI

@MainActor
struct EmotionTagsView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var editingTag: EmotionTag?
    @State private var addingTag = false
    @State private var deletingTag: EmotionTag?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(title: "Your words for your feelings.", subtitle: "Choose the names, colors, and icons that feel like you.")
                if store.emotionTags.isEmpty {
                    EmptyState(symbol: "tag", title: "Make it personal", message: "Create an emotion label to use in your notes.")
                }
                ForEach(store.emotionTags) { tag in
                    HStack(spacing: 13) {
                        IconBadge(symbol: tag.symbol, color: Color(hex: tag.colorHex))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(tag.name).font(.subheadline.weight(.semibold)).foregroundColor(Palette.text)
                            let count = store.entries.filter { $0.emotionTagIDs.contains(tag.id) }.count
                            Text("\(count) \(count == 1 ? "note" : "notes")").font(.caption).foregroundColor(Palette.secondary)
                        }
                        Spacer()
                        Button { editingTag = tag } label: { Image(systemName: "pencil").frame(width: 34, height: 40) }.accessibilityLabel("Edit \(tag.name)")
                        Button(role: .destructive) { deletingTag = tag } label: { Image(systemName: "trash").frame(width: 30, height: 40) }.accessibilityLabel("Delete \(tag.name)")
                    }.surface(padding: 14)
                }
                Button { addingTag = true } label: { Label("Create a label", systemImage: "plus") }.buttonStyle(FilledButtonStyle(tone: .lavender)).disabled(store.isReadOnly)
                Text("Deleting a label removes it from your notes. The notes themselves are kept.").font(.caption).foregroundColor(Palette.secondary)
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .pageBackground().navigationTitle("Emotion labels").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTag) { tag in EmotionTagEditor(tag: tag) }
        .sheet(isPresented: $addingTag) { EmotionTagEditor() }
        .confirmationDialog("Delete \(deletingTag?.name ?? "label")?", isPresented: Binding(get: { deletingTag != nil }, set: { if !$0 { deletingTag = nil } }), titleVisibility: .visible) {
            Button("Delete label", role: .destructive) {
                guard let tag = deletingTag else { return }
                do { try store.deleteTag(tag) } catch { self.error = error.localizedDescription }
                deletingTag = nil
            }
            Button("Cancel", role: .cancel) { deletingTag = nil }
        } message: { Text("This label will be removed from all notes. Your notes will remain.") }
        .alert("Could not update labels", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }
}

@MainActor
struct EmotionTagEditor: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var tag: EmotionTag
    @State private var original: EmotionTag
    @State private var confirmDiscard = false
    @State private var error: String?
    private let isEditing: Bool

    init(tag: EmotionTag? = nil) {
        let initial = tag ?? EmotionTag(name: "", symbol: "heart.fill", colorHex: EmotionTag.palette[0])
        _tag = State(initialValue: initial)
        _original = State(initialValue: initial)
        isEditing = tag != nil
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
                        Spacer()
                        VStack(spacing: 15) {
                            IconBadge(symbol: tag.symbol, color: Color(hex: tag.colorHex), size: 82)
                            TagChip(title: tag.name.trimmed.isEmpty ? "Your label" : tag.name.trimmed, symbol: tag.symbol, color: Color(hex: tag.colorHex), selected: true)
                        }.padding(.vertical, 12)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Label name").font(.subheadline.weight(.semibold))
                        TextField("e.g. Hopeful, Restless, Inspired", text: $tag.name).textInputAutocapitalization(.words)
                            .onChange(of: tag.name) { if $0.count > 30 { tag.name = String($0.prefix(30)) } }
                            .padding(16).background(Palette.surface).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Color").font(.subheadline.weight(.semibold))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                            ForEach(EmotionTag.palette, id: \.self) { hex in
                                Button { tag.colorHex = hex } label: {
                                    Circle().fill(Color(hex: hex)).frame(width: 43, height: 43)
                                        .overlay(Image(systemName: "checkmark").font(.subheadline.weight(.bold)).foregroundColor(.white).opacity(tag.colorHex == hex ? 1 : 0))
                                        .frame(maxWidth: .infinity)
                                }.accessibilityLabel(colorName(hex)).accessibilityAddTraits(tag.colorHex == hex ? .isSelected : [])
                            }
                        }.surface()
                    }
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Icon").font(.subheadline.weight(.semibold))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(EmotionTag.symbols, id: \.self) { symbol in
                                Button { tag.symbol = symbol } label: {
                                    Image(systemName: symbol).font(.title3).frame(maxWidth: .infinity).frame(height: 48)
                                        .foregroundColor(tag.symbol == symbol ? Color(hex: tag.colorHex).readableForeground(in: colorScheme) : Color(hex: tag.colorHex).readableInk(in: colorScheme))
                                        .background(tag.symbol == symbol ? Color(hex: tag.colorHex) : Palette.soft).clipShape(RoundedRectangle(cornerRadius: 13))
                                }.accessibilityLabel(symbolName(symbol)).accessibilityAddTraits(tag.symbol == symbol ? .isSelected : [])
                            }
                        }.surface()
                    }
                    Button(action: save) { Text(isEditing ? "Save label" : "Create label") }.buttonStyle(FilledButtonStyle(tone: .lavender)).disabled(tag.name.trimmed.isEmpty || store.isReadOnly)
                }.padding(22).foregroundColor(Palette.text).frame(maxWidth: 650).frame(maxWidth: .infinity)
            }
            .pageBackground().navigationTitle(isEditing ? "Edit label" : "New label").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if tag != original { confirmDiscard = true } else { dismiss() } } } }
            .interactiveDismissDisabled(tag != original)
            .confirmationDialog("Discard label changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Could not save label", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }

    private func save() {
        do { try store.saveTag(tag); dismiss() } catch { self.error = error.localizedDescription }
    }

    private func colorName(_ hex: String) -> String {
        let names = ["Terracotta", "Honey", "Sage", "Lavender", "Rose", "Fern", "Apricot", "Sea glass", "Heather", "Blush", "Olive", "Walnut"]
        guard let index = EmotionTag.palette.firstIndex(of: hex), names.indices.contains(index) else { return "Custom color" }
        return names[index]
    }

    private func symbolName(_ symbol: String) -> String {
        let names = ["Sun", "Cloud", "Sparkles", "Heart", "Leaf", "Lightning", "Moon", "Drop", "Flame", "Star", "Wind", "Pattern"]
        return EmotionTag.symbols.firstIndex(of: symbol).map { names[$0] } ?? "Custom icon"
    }
}
