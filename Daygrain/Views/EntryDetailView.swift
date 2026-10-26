import SwiftUI

@MainActor
struct EntryDetailView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let entryID: UUID
    @State private var showEditor = false
    @State private var showDelete = false
    @State private var gallery: GallerySelection?
    @State private var error: String?
    @State private var companion: ComposerRequest?
    @State private var showRevisit = false
    @State private var showLinks = false
    @State private var comparison: ComparisonRequest?
    private var entry: JournalEntry? { store.entries.first { $0.id == entryID } }

    var body: some View {
        Group {
            if let entry = entry {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            TagChip(title: entry.kind.title, symbol: entry.kind.symbol, color: entry.kind.tone.ink)
                            Spacer()
                            Button { store.toggleFavorite(entry) } label: {
                                Image(systemName: entry.isFavorite ? "bookmark.fill" : "bookmark").font(.title3).foregroundColor(Palette.gold).frame(width: 44, height: 44)
                            }.accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text(entry.title).font(.system(size: 31, weight: .medium, design: .serif)).foregroundColor(Palette.text).textSelection(.enabled)
                            HStack(spacing: 7) {
                                Image(systemName: "calendar")
                                Text(EnglishDate.string(entry.date, template: "MMMM d yyyy"))
                                Text("·")
                                Text(EnglishDate.string(entry.date, template: "h:mm a"))
                            }.font(.caption).foregroundColor(Palette.secondary)
                            if !entry.location.isEmpty {
                                Label(entry.location, systemImage: "mappin.and.ellipse").font(.caption).foregroundColor(Palette.secondary)
                            }
                        }
                        Divider().background(Palette.line)
                        if entry.kind == .sensory { sensoryContent(entry) } else { emotionContent(entry) }
                        if !entry.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeading(title: "In your own words")
                                Text(entry.notes).font(.body).lineSpacing(7).foregroundColor(Palette.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            }.surface()
                        }
                        if !entry.photoIDs.isEmpty { photos(entry) }
                        connections(entry)
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                            Text("Kept on this device · Edited \(EnglishDate.string(entry.updatedAt, template: "MMM d yyyy"))")
                        }.font(.caption2).foregroundColor(Palette.secondary).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
                }
            } else {
                EmptyState(symbol: "book.closed", title: "This page is no longer here", message: "The note may have been deleted or replaced by a restored backup.")
            }
        }
        .pageBackground().navigationTitle("Your moment").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let note = entry {
                    Menu {
                        Button { showEditor = true } label: { Label("Edit note", systemImage: "pencil") }
                        Button { companion = .companion(to: note) } label: { Label(note.kind == .sensory ? "Add an emotion companion" : "Add a sensory companion", systemImage: "link") }
                        Button { showLinks = true } label: { Label("Manage connected notes", systemImage: "link") }
                        Button { showRevisit = true } label: { Label("Plan a revisit", systemImage: "arrow.triangle.2.circlepath") }
                        Button(role: .destructive) { showDelete = true } label: { Label("Delete note", systemImage: "trash") }
                    } label: { Image(systemName: "ellipsis.circle").font(.title3).accessibilityLabel("Note options") }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let entry = entry { EntryEditorView(kind: entry.kind, existing: entry) }
        }
        .sheet(item: $companion) { ComposerSheet(request: $0) }
        .sheet(isPresented: $showRevisit) { RevisitEditor(sourceID: entryID) }
        .sheet(isPresented: $showLinks) { ConnectedNotesEditor(entryID: entryID) }
        .sheet(item: $comparison) { item in NavigationView { ComparisonView(ids: item.ids) }.navigationViewStyle(.stack) }
        .fullScreenCover(item: $gallery) { selection in PhotoGalleryView(photoIDs: selection.photoIDs, startingAt: selection.index) }
        .confirmationDialog("Move this note to Recently Deleted?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Move to Recently Deleted", role: .destructive) {
                guard let entry = entry else { return }
                do { try store.delete(entry); dismiss() } catch { self.error = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You can restore this note and its attached photo copies for 30 days in Settings → Recently Deleted. Original library photos are unchanged.") }
        .alert("Could not delete note", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private func connections(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let books = store.fieldbooks.filter { entry.fieldbookIDs.contains($0.id) }
            if !books.isEmpty {
                SectionHeading(title: "Filed in")
                ForEach(books) { book in
                    NavigationLink { FieldbookDetailView(bookID: book.id) } label: {
                        SettingsRow(symbol: book.symbol, title: book.name, subtitle: book.intention.isEmpty ? nil : book.intention, color: Color(hex: book.colorHex))
                    }.buttonStyle(.plain).surface(padding: 13)
                }
            }
            SectionHeading(title: "Connected moments", subtitle: "Keep sensory details and feelings together, or follow a moment over time.")
            ForEach(store.entries.filter { entry.linkedEntryIDs.contains($0.id) }) { linked in
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink { EntryDetailView(entryID: linked.id) } label: { EntryCard(entry: linked) }.buttonStyle(.plain)
                    Button { comparison = ComparisonRequest(ids: [entry.id, linked.id]) } label: { Label("Compare these moments", systemImage: "rectangle.split.2x1").font(.caption.weight(.medium)) }.padding(.horizontal, 5)
                }
            }
            Button { companion = .companion(to: entry) } label: { Label(entry.kind == .sensory ? "Add an emotion companion" : "Add a sensory companion", systemImage: "plus.circle") }.buttonStyle(FilledButtonStyle(tone: entry.kind == .sensory ? .lavender : .clay))
            HStack {
                Button { showLinks = true } label: { Label("Connect existing notes", systemImage: "link").font(.caption) }
                Spacer()
                Button { showRevisit = true } label: { Label("Plan a revisit", systemImage: "arrow.triangle.2.circlepath").font(.caption) }
            }
            let pending = store.pendingRevisits.filter { $0.sourceEntryID == entry.id }
            if !pending.isEmpty {
                NavigationLink { RevisitQueueView() } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(pending.count) planned revisits", systemImage: "calendar").font(.subheadline.weight(.medium))
                        ForEach(pending) { task in Text(task.question).font(.caption).foregroundColor(Palette.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading).surface(tint: Palette.gold)
                }.buttonStyle(.plain)
            }
        }
    }

    private func sensoryContent(_ entry: JournalEntry) -> some View {
        VStack(spacing: 16) {
            ForEach(Sense.allCases) { sense in
                if let observation = entry.observations.first(where: { $0.sense == sense }) {
                    HStack(alignment: .top, spacing: 14) {
                        IconBadge(symbol: sense.symbol, color: sense.tint)
                        VStack(alignment: .leading, spacing: 9) {
                            Text(sense.title.uppercased()).font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(1.5).foregroundColor(sense.tint)
                            Text(observation.text).font(.body).lineSpacing(5).foregroundColor(Palette.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).surface(tint: sense.tint)
                }
            }
            recordedLevel("Sensory intensity", value: entry.intensity, color: Palette.accent).surface()
        }
    }

    private func emotionContent(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 19) {
            if !store.tags(for: entry).isEmpty {
                SectionHeading(title: "The feelings you named")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)], alignment: .leading, spacing: 10) {
                    ForEach(store.tags(for: entry)) { tag in
                        TagChip(title: tag.name, symbol: tag.symbol, color: Color(hex: tag.colorHex), selected: true).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if !entry.trigger.isEmpty || !entry.context.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: "What happened")
                    if !entry.trigger.isEmpty { Text(entry.trigger).font(.body).lineSpacing(5).textSelection(.enabled) }
                    if !entry.context.isEmpty { Label(entry.context, systemImage: "square.grid.2x2").font(.caption).foregroundColor(Palette.secondary) }
                }.frame(maxWidth: .infinity, alignment: .leading).surface()
            }
            VStack(spacing: 19) {
                recordedLevel("Feeling intensity", value: entry.intensity, color: Palette.plum)
                Divider()
                recordedLevel("Energy", value: entry.energy, color: Palette.sage)
            }.surface(tint: Palette.plum)
        }.foregroundColor(Palette.text)
    }

    private func recordedLevel(_ title: String, value: Int, color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(Palette.text)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in Capsule().fill(level <= value ? color : Palette.line).frame(width: 13, height: 7) }
            }.accessibilityHidden(true)
            Text("\(value)/5").font(.caption.weight(.medium)).foregroundColor(Palette.secondary).padding(.leading, 6)
        }.accessibilityElement(children: .combine)
    }

    private func photos(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "The moment in pictures", subtitle: "Tap to view. Pinch to look closer.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                ForEach(Array(entry.photoIDs.enumerated()), id: \.element) { index, id in
                    Button { gallery = GallerySelection(photoIDs: entry.photoIDs, index: index) } label: {
                        GeometryReader { geometry in
                            Group {
                                if let image = store.image(for: id, thumbnail: true) { Image(uiImage: image).resizable().scaledToFill() }
                                else { Image(systemName: "photo").frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.soft) }
                            }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        }.frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 17))
                    }.buttonStyle(.plain).accessibilityLabel("View photo \(index + 1) of \(entry.photoIDs.count)")
                }
            }
        }
    }
}

@MainActor
private struct ConnectedNotesEditor: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let entryID: UUID
    @State private var selected: Set<UUID> = []
    @State private var query = ""
    @State private var loaded = false
    @State private var error: String?
    var body: some View {
        NavigationView {
            List {
                Text("Connect another view of the same event, a repeat observation, or a moment you want to compare. Connections work in both directions.").font(.caption).foregroundColor(Palette.secondary)
                ForEach(store.entries.filter { $0.id != entryID && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)) }) { entry in
                    Button {
                        if selected.contains(entry.id) { selected.remove(entry.id) } else { selected.insert(entry.id) }
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: selected.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.title).foregroundColor(Palette.text)
                                Text("\(entry.kind.title) · \(EnglishDate.string(entry.date, template: "MMM d yyyy"))").font(.caption).foregroundColor(Palette.secondary)
                            }
                        }
                    }.accessibilityAddTraits(selected.contains(entry.id) ? .isSelected : [])
                }
            }.searchable(text: $query, prompt: "Find a note").navigationTitle("Connected notes").navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    guard !loaded else { return }
                    selected = Set(store.entries.first { $0.id == entryID }?.linkedEntryIDs ?? [])
                    loaded = true
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        do { try store.setLinks(entryID: entryID, linkedIDs: selected); dismiss() } catch { self.error = error.localizedDescription }
                    } }
                }
                .alert("Could not connect notes", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK", role: .cancel) { error = nil } } message: { Text(error ?? "") }
        }.navigationViewStyle(.stack)
    }
}

private struct GallerySelection: Identifiable {
    let id = UUID()
    let photoIDs: [String]
    let index: Int
}

@MainActor
struct PhotoGalleryView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    let photoIDs: [String]
    @State private var index: Int

    init(photoIDs: [String], startingAt index: Int) {
        self.photoIDs = photoIDs
        _index = State(initialValue: index)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(index + 1) / \(photoIDs.count)").font(.subheadline.monospacedDigit())
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title).frame(width: 48, height: 48) }.accessibilityLabel("Close photos")
            }.foregroundColor(.white).padding(.horizontal, 18)
            TabView(selection: $index) {
                ForEach(Array(photoIDs.enumerated()), id: \.element) { number, id in
                    Group {
                        if let image = store.image(for: id) { ZoomablePhoto(image: image) }
                        else { Label("Photo unavailable", systemImage: "photo").foregroundColor(.white) }
                    }.tag(number)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never))
            Text("Pinch or double-tap to zoom").font(.caption).foregroundColor(.white.opacity(0.6)).padding(.bottom, 15)
        }.background(Color.black.ignoresSafeArea()).preferredColorScheme(.dark)
    }
}

private struct ZoomablePhoto: UIViewRepresentable {
    let image: UIImage
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        let imageView = context.coordinator.imageView
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Journal photo. Pinch to zoom."
        scroll.addSubview(imageView)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        tap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(tap)
        context.coordinator.scroll = scroll
        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView.image = image
        DispatchQueue.main.async {
            guard uiView.zoomScale == 1 else { return }
            context.coordinator.imageView.frame = uiView.bounds
            uiView.contentSize = uiView.bounds.size
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        weak var scroll: UIScrollView?
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
        @objc func doubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scroll = scroll else { return }
            if scroll.zoomScale > 1 { scroll.setZoomScale(1, animated: true) }
            else {
                let point = recognizer.location(in: imageView)
                let size = CGSize(width: scroll.bounds.width / 2.5, height: scroll.bounds.height / 2.5)
                scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
            }
        }
    }
}
