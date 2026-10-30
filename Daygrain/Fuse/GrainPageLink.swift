import UIKit

@MainActor
enum GrainExternalOpen {
    static func open(_ raw: String) {
        guard let url = acceptedURL(raw) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    static func open(_ url: URL) {
        guard url.scheme == "http" || url.scheme == "https", url.host != nil, url.user == nil else { return }
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

/// Single entry point for legal pages: builds daygrain-local://page?doc=… and hands it
/// to this app's own -local router (GrainPageLink.consume).
@MainActor
enum LegalRoute {
    enum Doc: String { case privacy, terms, support }

    static func url(_ doc: Doc) -> URL {
        var components = URLComponents()
        components.scheme = GrainPageLink.scheme
        components.host = "page"
        components.queryItems = [URLQueryItem(name: "doc", value: doc.rawValue)]
        return components.url!
    }

    static func open(_ doc: Doc) {
        GrainPageLink.consume(url(doc))
    }
}

@MainActor
enum GrainPageLink {
    static let scheme = "daygrain-local"

    static func openOutside(_ raw: String) {
        GrainExternalOpen.open(raw)
    }

    static func openInside(url raw: String) {
        guard let target = GrainExternalOpen.acceptedURL(raw) else { return }
        presentPage(remote: target)
    }

    static func openInside(document name: String) {
        presentPage(document: name)
    }

    @discardableResult
    static func consume(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        if isSettingsLink(url) {
            openAppSettings()
            return true
        }
        guard scheme == Self.scheme else { return false }
        let host = (url.host ?? "").lowercased()
        if host == "browser" {
            if let target = queryValue(url, "url") {
                openOutside(target)
            }
            return true
        }
        if host == "page" {
            if let doc = queryValue(url, "doc"), ["privacy", "terms", "support"].contains(doc) {
                openInside(document: doc)
                return true
            }
            if let raw = queryValue(url, "url") {
                openInside(url: raw)
                return true
            }
            return true
        }
        return false
    }

    static func isSettingsLink(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        guard scheme == Self.scheme else { return false }
        let host = (url.host ?? "").lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return host == "settings" && path.isEmpty && url.query == nil && url.fragment == nil
    }

    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private static func queryValue(_ url: URL, _ name: String) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    private static func presentPage(document: String) {
        let title = document == "privacy" ? "Privacy" : (document == "terms" ? "Terms" : "Support")
        let page = GrainActivityController(documentTitle: title, document: document)
        present(page)
    }

    private static func presentPage(remote: URL) {
        let page = GrainActivityController(documentTitle: "Page", remote: remote)
        present(page)
    }

    static func presentActivityCover() {
        let page = GrainActivityController(paperCover: true)
        page.modalPresentationStyle = .overFullScreen
        topPresenter().present(page, animated: false)
    }

    private static func present(_ page: GrainActivityController) {
        page.modalPresentationStyle = .overFullScreen
        topPresenter().present(page, animated: true)
    }

    static func topPresenter() -> UIViewController {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        var top = root
        while let next = top?.presentedViewController {
            top = next
        }
        return top ?? UIViewController()
    }
}
