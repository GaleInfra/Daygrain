import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@MainActor
struct SettingsView: View {
    @EnvironmentObject private var store: JournalStore
    @EnvironmentObject private var privacy: AppPrivacy
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("appLock") private var appLock = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var updatingReminder = false
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDocument = BackupDocument()
    @State private var exportType = UTType.json
    @State private var restoreURL: URL?
    @State private var confirmRestore = false
    @State private var confirmErase = false
    @State private var notice: String?
    @State private var error: String?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    brandCard
                    VStack(alignment: .leading, spacing: 13) {
                        sectionCaption("MAKE IT YOURS")
                        VStack(spacing: 12) {
                            NavigationLink { EmotionTagsView() } label: {
                                SettingsRow(symbol: "tag", title: "Emotion labels", subtitle: "\(store.emotionTags.count) personal labels", color: Palette.plum)
                            }.buttonStyle(.plain)
                            Divider()
                            HStack {
                                SettingsRow(symbol: "circle.lefthalf.filled", title: "Appearance", color: Palette.rose, chevron: false)
                                Picker("Appearance", selection: $appearance) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }.pickerStyle(.menu).labelsHidden()
                            }
                        }.surface(tint: Palette.plum)
                    }
                    reminderCard
                    libraryCard
                    privacyCard
                    backupCard
                    VStack(alignment: .leading, spacing: 13) {
                        sectionCaption("A FRESH PAGE")
                        Button(role: .destructive) { confirmErase = true } label: {
                            SettingsRow(symbol: "trash", title: "Erase journal", subtitle: "Delete all journal data, drafts, and trash", color: Palette.rose, chevron: false)
                        }.buttonStyle(.plain).surface()
                    }
                    VStack(spacing: 8) {
                        Text("Made for the moments in between.").font(.system(.subheadline, design: .serif)).foregroundColor(Palette.secondary)
                        Text("DAYGRAIN · VERSION 1.0").font(.system(size: 9, weight: .medium, design: .rounded)).tracking(1.6).foregroundColor(Palette.secondary.opacity(0.75))
                    }.frame(maxWidth: .infinity).padding(.vertical, 12)
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .pageBackground().navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .fileExporter(isPresented: $showExporter, document: backupDocument, contentType: exportType, defaultFilename: "Daygrain-\(exportType == .json ? "Backup" : "Journal")-\(backupDate)") { result in
                switch result {
                case .success: notice = exportType == .json ? "Your full backup was saved, including fieldbooks, reviews, revisits, drafts, Recently Deleted, labels, and attached photos." : "Your readable journal was saved. Use a JSON backup to preserve photos and restore the complete journal."
                case .failure(let failure): if !isUserCancellation(failure) { error = failure.localizedDescription }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): restoreURL = url; confirmRestore = true
                case .failure(let failure): if !isUserCancellation(failure) { error = failure.localizedDescription }
                }
            }
            .confirmationDialog("Replace your journal with this backup?", isPresented: $confirmRestore, titleVisibility: .visible) {
                Button("Restore and replace", role: .destructive) { restore() }
                Button("Cancel", role: .cancel) { restoreURL = nil }
            } message: { Text("The backup replaces notes, photos, fieldbooks, reviews, revisit plans, drafts, Recently Deleted, and labels. Export your current journal first to keep it. An invalid backup leaves your current data unchanged.") }
            .confirmationDialog("Erase your entire journal?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase all journal data", role: .destructive) {
                    do { try store.eraseJournal(); notice = "Your journal has been cleared. The default emotion labels have been restored." }
                    catch { self.error = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Notes, photo copies, fieldbooks, reviews, revisit plans, drafts, Recently Deleted, and custom labels will be permanently removed. Exported files and original library photos will remain.") }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
            .alert("All set", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("OK", role: .cancel) { notice = nil }
            } message: { Text(notice ?? "") }
            .task { await syncNotificationPermission() }
            .onChange(of: scenePhase) { phase in if phase == .active { Task { await syncNotificationPermission() } } }
        }.navigationViewStyle(.stack)
    }

    private var brandCard: some View {
        HStack(spacing: 17) {
            BrandMark(size: 58)
            VStack(alignment: .leading, spacing: 6) {
                Text("Daygrain").font(.system(size: 31, weight: .medium, design: .serif)).foregroundColor(Palette.text)
                Text("A little of the day, kept.").font(.caption).foregroundColor(Palette.secondary)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 8)
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionCaption("A MOMENT EACH DAY")
            VStack(spacing: 15) {
                Toggle(isOn: Binding(get: { reminderEnabled }, set: setReminder)) {
                    SettingsRow(symbol: "bell", title: "Daily reminder", subtitle: "A quiet invitation to write", color: Palette.gold, chevron: false)
                }.tint(JournalTone.honey.action).disabled(updatingReminder)
                if reminderEnabled {
                    Divider()
                    DatePicker("Reminder time", selection: Binding(get: {
                        Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
                    }, set: { date in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                        reminderHour = parts.hour ?? 20
                        reminderMinute = parts.minute ?? 0
                        setReminder(true)
                    }), displayedComponents: .hourAndMinute).font(.subheadline).foregroundColor(Palette.text).disabled(updatingReminder)
                }
                if updatingReminder { ProgressView().frame(maxWidth: .infinity) }
            }.surface(tint: Palette.gold)
        }
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionCaption("YOUR SPACE")
            VStack(spacing: 14) {
                Toggle(isOn: Binding(get: { appLock }, set: { enabled in
                    do {
                        if enabled { try AppPrivacy.checkAvailability(); privacy.isUnlocked = true }
                        appLock = enabled
                    } catch { self.error = error.localizedDescription }
                })) {
                    SettingsRow(symbol: "lock", title: "App Lock", subtitle: "Use Face ID, Touch ID, or passcode", color: Palette.sage, chevron: false)
                }
                Divider()
                NavigationLink { PrivacyInfoView() } label: {
                    SettingsRow(symbol: "hand.raised", title: "Privacy & local storage", subtitle: "Your journal, in your hands", color: Palette.sage)
                }.buttonStyle(.plain)
                Divider()
                Button { LegalRoute.open(.privacy) } label: {
                    SettingsRow(symbol: "doc.plaintext", title: "Privacy Policy", subtitle: "How Daygrain handles your data", color: Palette.sage)
                }.buttonStyle(.plain)
                Divider()
                Button { LegalRoute.open(.terms) } label: {
                    SettingsRow(symbol: "doc.text", title: "Terms", subtitle: "Terms of use", color: Palette.sage)
                }.buttonStyle(.plain)
                Divider()
                Button { LegalRoute.open(.support) } label: {
                    SettingsRow(symbol: "questionmark.circle", title: "Support", subtitle: "Get help with Daygrain", color: Palette.sage)
                }.buttonStyle(.plain)
            }.tint(JournalTone.sage.action).surface(tint: Palette.sage)
        }
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionCaption("KEEP YOUR PAGES")
            VStack(spacing: 12) {
                Button {
                    do { backupDocument = BackupDocument(data: try store.exportBackup()); exportType = .json; showExporter = true }
                    catch { self.error = error.localizedDescription }
                } label: {
                    SettingsRow(symbol: "square.and.arrow.up", title: "Export full backup", subtitle: "All journal data and photos in one JSON file", color: Palette.sage)
                }.buttonStyle(.plain).disabled(store.isReadOnly)
                Divider()
                Button {
                    backupDocument = BackupDocument(data: store.readableExport())
                    exportType = .plainText
                    showExporter = true
                } label: { SettingsRow(symbol: "doc.text", title: "Export readable journal", subtitle: "Notes and weekly reviews as a text document", color: Palette.plum) }.buttonStyle(.plain).disabled(store.isReadOnly)
                Divider()
                Button { showImporter = true } label: {
                    SettingsRow(symbol: "square.and.arrow.down", title: "Restore backup", subtitle: "Replace this journal from a saved file", color: Palette.sage)
                }.buttonStyle(.plain)
            }.surface(tint: Palette.sage)
            Text("Backups contain your personal notes and photos. Save them somewhere you trust.").font(.caption).foregroundColor(Palette.secondary)
            if store.isReadOnly {
                Label("Recovery mode: existing files are preserved. Restore a valid backup to reopen your journal.", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundColor(Palette.rose)
            }
        }
    }

    private var libraryCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionCaption("YOUR LIBRARY")
            VStack(spacing: 12) {
                NavigationLink { DraftsView() } label: { SettingsRow(symbol: "square.and.pencil", title: "Drafts", subtitle: "\(store.drafts.count) unfinished notes") }.buttonStyle(.plain)
                Divider()
                NavigationLink { RevisitQueueView() } label: { SettingsRow(symbol: "arrow.triangle.2.circlepath", title: "Revisit queue", subtitle: "\(store.pendingRevisits.count) planned revisits", color: Palette.gold) }.buttonStyle(.plain)
                Divider()
                NavigationLink { ReviewLibraryView() } label: { SettingsRow(symbol: "rectangle.stack", title: "Weekly reviews", subtitle: "\(store.reviews.count) saved chapters", color: Palette.plum) }.buttonStyle(.plain)
                Divider()
                NavigationLink { RecentlyDeletedView() } label: { SettingsRow(symbol: "trash", title: "Recently Deleted", subtitle: "\(store.trash.count) notes · Kept for 30 days", color: Palette.rose) }.buttonStyle(.plain)
            }.surface(tint: Palette.plum)
        }
    }

    private var backupDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func sectionCaption(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(1.5).foregroundColor(Palette.secondary)
    }

    private func setReminder(_ enabled: Bool) {
        guard !updatingReminder else { return }
        if !enabled { ReminderManager.cancel(); reminderEnabled = false; return }
        updatingReminder = true
        Task { @MainActor in
            defer { updatingReminder = false }
            do {
                try await ReminderManager.schedule(hour: reminderHour, minute: reminderMinute)
                reminderEnabled = true
            } catch {
                ReminderManager.cancel()
                reminderEnabled = false
                self.error = error.localizedDescription
            }
        }
    }

    private func syncNotificationPermission() async {
        guard reminderEnabled, !updatingReminder else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .denied {
            reminderEnabled = false
            ReminderManager.cancel()
        }
    }

    private func restore() {
        guard let url = restoreURL else { return }
        defer { restoreURL = nil }
        do {
            let count = try store.importBackup(from: url)
            notice = "Restored \(count) \(count == 1 ? "note" : "notes"), your labels, and attached photos."
        } catch { self.error = error.localizedDescription }
    }

    private func isUserCancellation(_ error: Error) -> Bool {
        let value = error as NSError
        return value.domain == NSCocoaErrorDomain && value.code == NSUserCancelledError
    }
}

struct PrivacyInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                IconBadge(symbol: "lock.shield", size: 70).frame(maxWidth: .infinity).padding(.vertical, 10)
                Text("A journal that belongs to you.").font(.system(size: 29, weight: .regular, design: .serif)).foregroundColor(Palette.text)
                privacyBlock("Stored locally", symbol: "iphone", text: "Notes, photo copies, fieldbooks, reviews, revisit plans, drafts, and Recently Deleted are saved in this app's private storage on your device. Daygrain has no account system, social feed, advertising, analytics, or automatic cloud sync.")
                privacyBlock("Voice journal stays here", symbol: "mic", text: "Voice journal recordings are saved only in Daygrain's private storage on this iPhone. Transcription uses Apple speech recognition, on device when supported. You can play or delete a recording from its note at any time.")
                privacyBlock("Only the photos you choose", symbol: "photo", text: "Daygrain uses the system photo picker. It receives only the images you select and stores resized copies. Removing a photo from a note does not change your photo library.")
                privacyBlock("Your own record", symbol: "chart.bar", text: "Charts count your entries and labels and show the intensity and energy values you entered. All calculations happen on your device.")
                privacyBlock("Drafts and deleted notes", symbol: "trash", text: "Unfinished notes and their selected photo copies are saved as drafts. Deleted notes stay in Recently Deleted for 30 days before removal while the app is running. You can restore or permanently delete them sooner. Full backups include drafts and Recently Deleted; readable exports include saved notes and reviews.")
                privacyBlock("An extra layer of privacy", symbol: "lock", text: "App Lock uses your device's authentication. When enabled, your journal locks after the app goes into the background. The app switcher hides your journal's contents. Unlocking takes you back to where you left off.")
                privacyBlock("Backups are your choice", symbol: "externaldrive", text: "Exports include your text, labels, and photo copies in a JSON file. You choose the destination. Your device's system backup settings may also include app data. Removing Daygrain removes its local journal, so keep a backup if you want to restore it later.")
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.pageBackground().navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
    }

    private func privacyBlock(_ title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.system(.headline, design: .rounded)).foregroundColor(Palette.accent)
            Text(text).font(.subheadline).lineSpacing(5).foregroundColor(Palette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).surface()
    }
}
