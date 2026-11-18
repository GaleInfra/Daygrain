import UIKit

@MainActor
enum GrainExternalOpen {
    static func open(_ raw: String) {
        guard let url = acceptedURL(raw) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    static func acceptedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        guard let host = url.host, !host.isEmpty else { return nil }
        if url.user != nil || url.password != nil { return nil }
        return url
    }
}

@MainActor
enum GrainPageLink {
    static func openOutside(_ raw: String) {
        GrainExternalOpen.open(raw)
    }

    static func openInside(url raw: String) {
        guard let target = GrainExternalOpen.acceptedURL(raw) else { return }
        DaygrainSheetVessel.presentCover(remote: target)
    }

    static func openInside(document name: String) {
        let stem = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let resource = Bundle.main.url(forResource: stem, withExtension: "html", subdirectory: "Legal")
            ?? Bundle.main.url(forResource: stem, withExtension: "html") else { return }
        DaygrainSheetVessel.presentCover(remote: resource)
    }

    static func isSettingsLink(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        guard scheme == "fablethistle" || scheme == "fablethistle-local" else { return false }
        return (url.host ?? "").lowercased() == "settings" && url.path.isEmpty
    }

    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @discardableResult
    static func consume(_ url: URL) -> Bool {
        if isSettingsLink(url) {
            openAppSettings()
            return true
        }
        let scheme = (url.scheme ?? "").lowercased()
        guard scheme == "fablethistle" || scheme == "fablethistle-local" else { return false }
        let proto = DaygrainMarkLexicon.current
        let host = (url.host ?? "").lowercased()
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if host == GrainSignalLink.action {
            // The activity page reports through the same reader the app uses for its own links.
            // The host is ours, so the address is handled even when the shape is rejected —
            // otherwise a malformed link would fall through to the web view and reload it.
            _ = GrainSignalDesk.shared.submit(url)
            return true
        }
        if host == proto.browserHost {
            if let target = items.first(where: { $0.name == proto.urlParam })?.value {
                openOutside(target)
            }
            return true
        }
        if host == proto.cinderMark {
            if let folio = items.first(where: { $0.name == proto.presentParam })?.value,
               folio == proto.presentCoverValue,
               let doc = items.first(where: { $0.name == proto.docParam })?.value {
                openInside(document: doc)
                return true
            }
            if let folio = items.first(where: { $0.name == proto.presentParam })?.value,
               folio == proto.presentCoverValue,
               let raw = items.first(where: { $0.name == proto.urlParam })?.value {
                openInside(url: raw)
                return true
            }
            if let folio = items.first(where: { $0.name == proto.presentParam })?.value,
               folio == proto.presentHostValue,
               let raw = items.first(where: { $0.name == proto.urlParam })?.value,
               let activity = URL(string: raw) {
                DaygrainSheetVessel.presentFullHost(activity)
                return true
            }
            if items.first(where: { $0.name == proto.urlParam })?.value == "return"
                || url.absoluteString.hasPrefix("fablethistle-local://return")
                || url.absoluteString.hasPrefix("fablethistle://cinder") && items.contains(where: { $0.value == "return" }) {
                DaygrainSheetVessel.dismissTop()
                return true
            }
        }
        return false
    }
}