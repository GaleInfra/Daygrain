import SwiftUI

@MainActor
struct EntryEditorView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var entry: JournalEntry
    @State private var selectedSenses: Set<Sense>
    @State private var pendingPhotos: [PendingPhoto] = []
    @State private var showPhotoPicker = false
    @State private var loadingPhotos = false
    @State private var showDiscard = false
    @State private var showTagEditor = false
    @State private var error: String?
    @State private var original: JournalEntry
    @State private var showFieldbookEditor = false
    @State private var draftTask: Task<Void, Never>?
    @State private var draftStatus = ""
    @State private var finished = false
    @State private var loadedDraft = false
    @State private var savedEntryID: UUID?
    @State private var showVoice = false
    @State private var showCamera = false
    @State private var cameraDenied = false
    @State private var voiceRevision = 0
    @State private var sessionAudio: [URL] = []
    @State private var showRecentPhotos = false
    private let isEditing: Bool
    private let startWithVoice: Bool

    init(kind: JournalKind, existing: JournalEntry? = nil, initialDate: Date = Date(), seed: JournalEntry? = nil, draft: JournalDraft? = nil, startWithVoice: Bool = false) {
        self.startWithVoice = startWithVoice
        let initial = draft?.entry ?? existing ?? seed ?? JournalEntry(kind: kind, title: "", date: initialDate)
        _original = State(initialValue: initial)
        isEditing = draft?.isEditingExisting ?? (existing != nil)
        _entry = State(initialValue: initial)
        _selectedSenses = State(initialValue: initial.senses.isEmpty ? [.smell] : Set(initial.senses))
    }

    private var photoCount: Int { entry.photoIDs.count + pendingPhotos.count }
    private var isDirty: Bool { entry != original || !pendingPhotos.isEmpty }
    private var hasDraft: Bool { store.drafts.contains { $0.id == entry.id } }
    private var canSave: Bool {
        let content = entry.kind == .sensory
            ? (!entry.observations.allSatisfy { $0.text.trimmed.isEmpty } || !entry.notes.trimmed.isEmpty || photoCount > 0)
            : !entry.emotionTagIDs.isEmpty
        return !entry.title.trimmed.isEmpty && content && !loadingPhotos && !store.isReadOnly
    }

    var body: some View {
        NavigationView {
            Group {
                if let id = savedEntryID {
                    SavedMomentView(entryID: id) { dismiss() }
                } else { editorContent }
            }
        }.navigationViewStyle(.stack)
    }

    private var editorContent: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    editorHeader
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Give this moment a title", text: $entry.title)
                            .font(.system(size: 24, weight: .medium, design: .serif)).foregroundColor(Palette.text)
                            .accessibilityLabel("Note title")
                            .onChange(of: entry.title) { if $0.count > 120 { entry.title = String($0.prefix(120)) } }
                        Divider()
                        DatePicker("Date & time", selection: $entry.date, in: ...Date())
                            .font(.subheadline).foregroundColor(Palette.text)
                        Divider()
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse").foregroundColor(Palette.secondary)
                            TextField("Place (optional)", text: $entry.location).font(.subheadline).accessibilityLabel("Place, optional")
                        }
                        Divider()
                        workflowFields
                    }.surface()
                    if entry.kind == .sensory { sensoryFields } else { emotionFields }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: entry.kind == .sensory ? "A little more to remember" : "In your own words", subtitle: "Anything else you want to keep. Optional.")
                        EditorTextArea(placeholder: "Let the moment stay on the page…", text: $entry.notes, minHeight: 125).surface(padding: 14)
                    }
                    photoSection
                    VoiceAttachmentsList(entryID: entry.id).id(voiceRevision)
                    Toggle(isOn: $entry.isFavorite) {
                        Label("Keep in favorites", systemImage: "bookmark").font(.subheadline.weight(.medium)).foregroundColor(Palette.text)
                    }.tint(JournalTone.honey.action).surface(tint: Palette.gold)
                    if !canSave && !store.isReadOnly {
                        Text(entry.title.trimmed.isEmpty ? "Add a title to save your note." : entry.kind == .emotion ? "Choose at least one emotion label." : "Add a sensory detail, a note, or a photo.")
                            .font(.caption).foregroundColor(Palette.secondary)
                    }
                    if store.isReadOnly {
                        Text("Your journal is in recovery mode. Restore a backup in Settings before saving notes.").font(.caption).foregroundColor(.red)
                    }
                    Button(action: save) {
                        Label(isEditing ? "Save changes" : "Keep this moment", systemImage: "checkmark")
                    }.buttonStyle(FilledButtonStyle(tone: entry.kind.tone)).disabled(!canSave)
                    VStack(spacing: 8) {
                        if !draftStatus.isEmpty { Text(draftStatus).font(.caption2).foregroundColor(Palette.secondary) }
                        Label("Saved on this device", systemImage: "lock.shield").font(.caption2).foregroundColor(Palette.secondary)
                    }.frame(maxWidth: .infinity)
                }
                .padding(22).padding(.bottom, 12).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .pageBackground().tint(entry.kind.tone.ink)
            .navigationTitle(isEditing ? "Edit note" : "New \(entry.kind.title.lowercased()) note").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismissKeyboard(); if isDirty || hasDraft { showDiscard = true } else { discardSessionAudio(); finished = true; dismiss() } } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).font(.subheadline.weight(.semibold)).disabled(!canSave) }
                ToolbarItem(placement: .primaryAction) {
                    Button { dismissKeyboard(); showVoice = true } label: { Label("Speak", systemImage: "mic") }
                        .accessibilityLabel("Speak a voice journal").disabled(store.isReadOnly)
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { dismissKeyboard() } }
            }
            .interactiveDismissDisabled(isDirty || hasDraft || loadingPhotos)
            .confirmationDialog("Leave this unfinished note?", isPresented: $showDiscard, titleVisibility: .visible) {
                Button("Keep draft") { if persistDraft() { finished = true; draftTask?.cancel(); dismiss() } }
                Button("Discard changes", role: .destructive) {
                    do { try store.deleteDraft(entry.id); discardSessionAudio(); finished = true; draftTask?.cancel(); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
                Button("Keep writing", role: .cancel) {}
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker(limit: 6 - photoCount) { images, failed in
                    showPhotoPicker = false
                    let available = max(0, 6 - photoCount)
                    let processed = images.prefix(available).compactMap { PendingPhoto(image: $0) }
                    pendingPhotos.append(contentsOf: processed)
                    loadingPhotos = false
                    scheduleDraft()
                    if failed > 0 || processed.count < min(images.count, available) { error = "Some photos could not be opened. Please try selecting them again." }
                }.ignoresSafeArea().interactiveDismissDisabled()
            }
            .sheet(isPresented: $showVoice) {
                VoiceJournalSheet { text, audio in
                    let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !words.isEmpty { entry.notes = entry.notes.isEmpty ? words : entry.notes + "\n" + words }
                    if let audio = audio {
                        do { sessionAudio.append(try store.attachAudio(from: audio, to: entry.id)); voiceRevision += 1 }
                        catch { self.error = "The recording could not be saved: \(error.localizedDescription)" }
                    }
                    scheduleDraft()
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    showCamera = false
                    if let image = image, photoCount < 6, let photo = PendingPhoto(image: image) {
                        pendingPhotos.append(photo); scheduleDraft()
                    }
                }.ignoresSafeArea()
            }
            .sheet(isPresented: $showRecentPhotos) {
                RecentPhotosSheet { image in
                    if photoCount < 6, let photo = PendingPhoto(image: image) { pendingPhotos.append(photo); scheduleDraft() }
                }
            }
            .sheet(isPresented: $showTagEditor) { EmotionTagEditor() }
            .sheet(isPresented: $showFieldbookEditor) {
                FieldbookEditor { book in
                    entry.fieldbookIDs.append(book.id)
                    if entry.observations.allSatisfy({ $0.text.trimmed.isEmpty }) { selectedSenses = Set(book.focusSenses) }
                }
            }
            .onAppear {
                guard !loadedDraft else { return }
                loadedDraft = true
                if startWithVoice { showVoice = true }
                if let draft = store.drafts.first(where: { $0.id == entry.id }) {
                    entry = draft.entry
                    selectedSenses = entry.senses.isEmpty ? [.smell] : Set(entry.senses)
                    draftStatus = "Restored your saved draft"
                } else if entry.kind == .sensory, entry.observations.isEmpty,
                          let book = store.fieldbooks.first(where: { entry.fieldbookIDs.contains($0.id) }) {
                    selectedSenses = Set(book.focusSenses)
                }
            }
            .onChange(of: entry) { _ in scheduleDraft() }
            .onChange(of: scenePhase) { if $0 != .active { draftTask?.cancel(); _ = persistDraft() } }
            .onDisappear { draftTask?.cancel() }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
    }

    private var workflowFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fieldbooks").font(.subheadline.weight(.medium)).foregroundColor(Palette.text)
                Spacer()
                Menu {
                    ForEach(store.fieldbooks.filter { !$0.isArchived || entry.fieldbookIDs.contains($0.id) }) { book in
                        Button {
                            if entry.fieldbookIDs.contains(book.id) { entry.fieldbookIDs.removeAll { $0 == book.id } }
                            else { entry.fieldbookIDs.append(book.id) }
                        } label: { Label(book.name, systemImage: entry.fieldbookIDs.contains(book.id) ? "checkmark.circle.fill" : "circle") }
                    }
                    Button("Create fieldbook") { showFieldbookEditor = true }
                } label: { Label("Choose", systemImage: "books.vertical").font(.caption) }
            }
            let selected = store.fieldbooks.filter { entry.fieldbookIDs.contains($0.id) }
            if selected.isEmpty { Text("Optional: collect this note around a place, season, or personal theme.").font(.caption).foregroundColor(Palette.secondary) }
            ForEach(selected) { book in
                VStack(alignment: .leading, spacing: 6) {
                    TagChip(title: book.name, symbol: book.symbol, color: Color(hex: book.colorHex))
                    if !book.intention.isEmpty { Text(book.intention).font(.caption).foregroundColor(Palette.secondary) }
                }
            }
            ForEach(store.entries.filter { entry.linkedEntryIDs.contains($0.id) }) { source in
                Label("Connected to: \(source.title)", systemImage: "link").font(.caption).foregroundColor(Palette.accent)
            }
            if let task = store.revisits.first(where: { $0.id == entry.revisitTaskID }) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your revisit focus", systemImage: "arrow.triangle.2.circlepath").font(.caption.weight(.semibold)).foregroundColor(Palette.accent)
                    Text(task.question).font(.subheadline).foregroundColor(Palette.text)
                    Text("Saving this note completes the revisit and keeps a link to the original.").font(.caption2).foregroundColor(Palette.secondary)
                }
            }
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: entry.kind.symbol, color: entry.kind.tone.ink, size: 48)
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.kind == .sensory ? "Notice the little things." : "Every feeling has a place.")
                    .font(.system(.headline, design: .rounded)).foregroundColor(Palette.text)
                Text(entry.kind == .sensory ? "The world, through your senses." : "A personal record, in your own words.")
                    .font(.caption).foregroundColor(Palette.secondary)
            }
        }
    }

    private var sensoryFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeading(title: "What did you notice?", subtitle: "Choose one sense or collect a few.")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Sense.allCases) { sense in
                        Button {
                            if selectedSenses.contains(sense) {
                                // Keep written observations when hiding a field; the text stays in the note.
                                selectedSenses.remove(sense)
                            } else { selectedSenses.insert(sense) }
                        } label: {
                            TagChip(title: sense.title, symbol: sense.symbol, color: sense.tint, selected: selectedSenses.contains(sense))
                                .frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityAddTraits(selectedSenses.contains(sense) ? .isSelected : [])
                    }
                }
            }
            ForEach(Sense.allCases.filter { selectedSenses.contains($0) }) { sense in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(sense.title, systemImage: sense.symbol).font(.subheadline.weight(.semibold)).foregroundColor(sense.tint)
                        Spacer()
                        if !observationBinding(sense).wrappedValue.trimmed.isEmpty {
                            Button("Clear") { observationBinding(sense).wrappedValue = "" }.font(.caption).foregroundColor(Palette.secondary)
                        }
                    }
                    EditorTextArea(placeholder: sense.prompt, text: observationBinding(sense), minHeight: 85)
                }.surface(padding: 16, tint: sense.tint)
            }
            if !entry.observations.filter({ !selectedSenses.contains($0.sense) && !$0.text.trimmed.isEmpty }).isEmpty {
                Text("Details in hidden sense fields are kept. Select a sense to view or clear its text.").font(.caption).foregroundColor(Palette.secondary)
            }
            LevelSelector(title: "Sensory intensity", low: "Subtle", high: "Vivid", value: $entry.intensity).surface()
        }
    }

    private var emotionFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                SectionHeading(title: "Name the feeling", subtitle: "Choose any labels that fit.")
                Button { showTagEditor = true } label: { Image(systemName: "plus.circle").font(.title3).accessibilityLabel("Create an emotion label") }
            }
            if store.emotionTags.isEmpty {
                Button { showTagEditor = true } label: { Label("Create your first emotion label", systemImage: "plus") }.buttonStyle(FilledButtonStyle(tone: .lavender))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), alignment: .leading)], alignment: .leading, spacing: 10) {
                    ForEach(store.emotionTags) { tag in
                        let selected = entry.emotionTagIDs.contains(tag.id)
                        Button {
                            if selected { entry.emotionTagIDs.removeAll { $0 == tag.id } } else { entry.emotionTagIDs.append(tag.id) }
                        } label: {
                            TagChip(title: tag.name, symbol: tag.symbol, color: Color(hex: tag.colorHex), selected: selected)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Label("What happened?", systemImage: "text.bubble").font(.subheadline.weight(.semibold)).foregroundColor(Palette.text)
                EditorTextArea(placeholder: "A conversation, a change of plans, a small win…", text: $entry.trigger, minHeight: 85)
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2").foregroundColor(Palette.secondary)
                    TextField("Context, e.g. work, home, outdoors", text: $entry.context).font(.subheadline).accessibilityLabel("Context, optional")
                }
            }.surface(padding: 16, tint: Palette.plum)
            VStack(spacing: 23) {
                LevelSelector(title: "Feeling intensity", low: "Gentle", high: "Strong", value: $entry.intensity, color: Palette.plum)
                Divider()
                LevelSelector(title: "Energy", low: "Low", high: "High", value: $entry.energy, color: Palette.sage)
            }.surface(tint: Palette.plum)
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                SectionHeading(title: "A picture of the moment", subtitle: "Take one now or choose from your library. Up to 6 photos.")
                Text("\(photoCount)/6").font(.caption.monospacedDigit()).foregroundColor(Palette.secondary)
            }
            if photoCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(entry.photoIDs, id: \.self) { id in
                            photoThumbnail(store.image(for: id, thumbnail: true)) { entry.photoIDs.removeAll { $0 == id } }
                        }
                        ForEach(pendingPhotos) { photo in
                            photoThumbnail(photo.image) { pendingPhotos.removeAll { $0.id == photo.id }; scheduleDraft() }
                        }
                    }.padding(.vertical, 5)
                }
            }
            if photoCount < 6 {
                HStack(spacing: 10) {
                    if CameraPicker.isAvailable {
                        Button {
                            dismissKeyboard()
                            Task { @MainActor in
                                if await MediaAccess.camera() == .granted { cameraDenied = false; showCamera = true } else { cameraDenied = true }
                            }
                        } label: { photoButtonLabel("Camera", symbol: "camera") }
                    }
                    Button {
                        dismissKeyboard()
                        loadingPhotos = true
                        showPhotoPicker = true
                    } label: { photoButtonLabel(loadingPhotos ? "Opening photos…" : "Photos", symbol: "photo.on.rectangle.angled", busy: loadingPhotos) }
                        .disabled(loadingPhotos)
                }
                Button { dismissKeyboard(); showRecentPhotos = true } label: { photoButtonLabel("Recent Photos", symbol: "clock.arrow.circlepath") }
                if cameraDenied { PermissionDeniedNote(message: "Camera access is off. You can still add photos from your library.") }
            }
        }
    }

    /// Recordings made in this editor session are removed when the user leaves without saving.
    private func discardSessionAudio() {
        sessionAudio.forEach { store.deleteAudio($0) }
        sessionAudio.removeAll()
    }

    private func photoButtonLabel(_ title: String, symbol: String, busy: Bool = false) -> some View {
        HStack(spacing: 9) {
            if busy { ProgressView() } else { Image(systemName: symbol) }
            Text(title)
        }.font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 17)
            .background(Palette.accent.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
    }

    private func photoThumbnail(_ image: UIImage?, remove: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = image { Image(uiImage: image).resizable().scaledToFill() }
                else { Image(systemName: "photo").frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.soft) }
            }.frame(width: 112, height: 118).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
            Button(action: remove) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white).frame(width: 25, height: 25).background(Color.black.opacity(0.55)).clipShape(Circle())
            }.padding(6).accessibilityLabel("Remove photo")
        }
    }

    private func observationBinding(_ sense: Sense) -> Binding<String> {
        Binding(get: { entry.observations.first { $0.sense == sense }?.text ?? "" }, set: { text in
            if let index = entry.observations.firstIndex(where: { $0.sense == sense }) { entry.observations[index].text = text }
            else { entry.observations.append(SensoryObservation(sense: sense, text: text)) }
        })
    }

    private func save() {
        guard canSave else { return }
        dismissKeyboard()
        draftTask?.cancel()
        finished = true
        do {
            try store.save(entry, newPhotos: pendingPhotos)
            if isEditing { dismiss() } else { savedEntryID = entry.id }
        }
        catch { finished = false; self.error = error.localizedDescription }
    }

    private func scheduleDraft() {
        guard !finished, !store.isReadOnly, isDirty || hasDraft else { return }
        draftTask?.cancel()
        draftStatus = "Saving draft…"
        draftTask = Task { @MainActor in
            do { try await Task.sleep(nanoseconds: 800_000_000) } catch { return }
            guard !Task.isCancelled, !finished else { return }
            _ = persistDraft()
        }
    }

    @discardableResult
    private func persistDraft() -> Bool {
        guard !finished, isDirty || hasDraft else { return true }
        guard !store.isReadOnly else {
            error = "Your journal is in recovery mode. Restore a backup or reopen Daygrain before saving a draft."
            return false
        }
        do {
            try store.saveDraft(entry, newPhotos: pendingPhotos, isEditing: isEditing)
            draftStatus = "Draft saved on this device"
            return true
        } catch {
            draftStatus = "Draft could not be saved: \(error.localizedDescription)"
            self.error = error.localizedDescription
            return false
        }
    }
}
