import SwiftUI

enum AppTab: Int {
    case today, journal, fieldbooks, insights, settings
    var tone: JournalTone {
        switch self {
        case .today: return .clay
        case .journal: return .rose
        case .fieldbooks: return .sage
        case .insights: return .honey
        case .settings: return .lavender
        }
    }
}

@MainActor
struct RootView: View {
    @EnvironmentObject private var store: JournalStore
    @EnvironmentObject private var privacy: AppPrivacy
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appLock") private var appLock = false
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sun.max") }.tag(AppTab.today)
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed") }.tag(AppTab.journal)
            FieldbooksView()
                .tabItem { Label("Fieldbooks", systemImage: "books.vertical") }.tag(AppTab.fieldbooks)
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }.tag(AppTab.insights)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(AppTab.settings)
        }
        .tint(selectedTab.tone.ink)
        .onAppear { if appLock { privacy.unlock() } }
        .onChange(of: scenePhase) { phase in
            if phase == .background && appLock { privacy.lock() }
            if phase == .active && appLock && !privacy.isUnlocked { privacy.unlock() }
            if phase == .active && !store.isReadOnly {
                do { try store.purgeExpiredTrash() } catch { store.storageError = error.localizedDescription }
            }
        }
        .background(PrivacySnapshotShield(locked: appLock && !privacy.isUnlocked))
        .alert("Journal storage", isPresented: Binding(get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } })) {
            Button("OK", role: .cancel) { store.storageError = nil }
        } message: { Text(store.storageError ?? "") }
    }
}

@MainActor
struct LockScreen: View {
    @EnvironmentObject private var privacy: AppPrivacy
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            BrandMark(size: 78)
            VStack(spacing: 10) {
                Text("A space of your own.").font(.system(size: 30, weight: .medium, design: .serif)).multilineTextAlignment(.center)
                Text("Unlock to open your journal.").font(.subheadline).foregroundColor(Palette.secondary)
            }
            if let message = privacy.message {
                Text(message).font(.footnote).foregroundColor(Palette.secondary).multilineTextAlignment(.center)
            }
            Button { privacy.unlock() } label: {
                Label(privacy.isAuthenticating ? "Unlocking…" : "Unlock Daygrain", systemImage: "lock.open")
            }.buttonStyle(FilledButtonStyle()).disabled(privacy.isAuthenticating)
            Spacer()
            Label("Private by nature", systemImage: "lock.shield").font(.caption).foregroundColor(Palette.secondary)
        }
        .padding(32).foregroundColor(Palette.text).pageBackground()
    }
}

// A native window cover also hides sheets and the app-switcher snapshot.
@MainActor
struct PrivacySnapshotShield: UIViewRepresentable {
    @EnvironmentObject private var privacy: AppPrivacy
    let locked: Bool
    func makeUIView(context: Context) -> PrivacyShieldView { PrivacyShieldView() }
    func updateUIView(_ uiView: PrivacyShieldView, context: Context) { uiView.updateLock(locked, privacy: privacy) }
}

final class PrivacyShieldView: UIView {
    private var shield: UIView?
    private var tokens: [NSObjectProtocol] = []
    private var lockWindow: UIWindow?
    private var needsLock = false
    private weak var privacy: AppPrivacy?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.showShield() })
        tokens.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.hideShield() })
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let privacy = privacy { updateLock(needsLock, privacy: privacy) }
    }

    func updateLock(_ locked: Bool, privacy: AppPrivacy) {
        self.privacy = privacy
        needsLock = locked
        guard locked else {
            lockWindow?.isHidden = true
            lockWindow = nil
            return
        }
        guard lockWindow == nil, let scene = window?.windowScene else { return }
        window?.endEditing(true)
        let overlay = UIWindow(windowScene: scene)
        overlay.windowLevel = .alert + 1
        overlay.frame = scene.coordinateSpace.bounds
        overlay.overrideUserInterfaceStyle = window?.traitCollection.userInterfaceStyle ?? .unspecified
        overlay.accessibilityViewIsModal = true
        overlay.rootViewController = UIHostingController(rootView: LockScreen().environmentObject(privacy).environment(\.locale, Locale(identifier: "en_US")))
        overlay.isHidden = false
        lockWindow = overlay
    }

    private func showShield() {
        guard shield == nil, let window = window else { return }
        let cover = UIView(frame: window.bounds)
        cover.backgroundColor = UIColor(hex: "6C3F30")
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let symbol = UIImageView(image: UIImage(named: "BrandGlyph"))
        symbol.contentMode = .scaleAspectFit
        symbol.translatesAutoresizingMaskIntoConstraints = false
        cover.addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
            symbol.widthAnchor.constraint(equalToConstant: 90),
            symbol.heightAnchor.constraint(equalToConstant: 90)
        ])
        window.addSubview(cover)
        shield = cover
    }

    private func hideShield() { shield?.removeFromSuperview(); shield = nil }
}
