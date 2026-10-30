import SwiftUI

@main
@MainActor
struct DaygrainApp: App {
    @StateObject private var store = JournalStore()
    @StateObject private var privacy = AppPrivacy()
    @AppStorage("appearance") private var appearance = "system"
    @State private var launchRoute: GrainLaunchRoute = .launching

    init() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithTransparentBackground()
        navigation.backgroundColor = .clear
        navigation.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "302722") : UIColor(hex: "FFFCF7") }
        tab.stackedLayoutAppearance.normal.iconColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "C5B19D") : UIColor(hex: "7A6859") }
        tab.stackedLayoutAppearance.selected.iconColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "E4AD91") : UIColor(hex: "974B36") }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITextView.appearance().backgroundColor = .clear
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "694B37") : UIColor(hex: "FFFCF7") }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch launchRoute {
                case .launching:
                    GrainLaunchGateView(route: $launchRoute)
                case .native:
                    RootView()
                        .environmentObject(store)
                        .environmentObject(privacy)
                        .environment(\.locale, Locale(identifier: "en_US"))
                        .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
                        .tint(Palette.accent)
                        .onOpenURL { GrainPageLink.consume($0) }
                case .activity:
                    GrainActivityRepresentable()
                        .ignoresSafeArea()
                }
            }
        }
    }
}
