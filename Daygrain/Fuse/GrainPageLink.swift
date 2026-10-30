import UIKit
import WebKit

@MainActor
enum GrainBookLink {
    static let scheme = "grainbook"

    static func url(_ name: String) -> URL? {
        URL(string: "\(scheme)://entry/\(name)")
    }

    static func legalName(_ url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        guard (url.host ?? "").lowercased() == "entry" else { return nil }
        let name = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        return ["privacy", "terms", "support"].contains(name) ? name : nil
    }
}

final class GrainBookHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let name = GrainBookLink.legalName(url) else {
            urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
            return
        }
        let body = Data(GrainLegalPages.html(name).utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html; charset=utf-8", "Content-Length": "\(body.count)"]
        )!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(body)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

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

@MainActor
enum GrainPageLink {
    static func openOutside(_ raw: String) {
        GrainExternalOpen.open(raw)
    }

    static func openInside(url raw: String) {
        guard let target = GrainExternalOpen.acceptedURL(raw) else { return }
        presentPage(remote: target)
    }

    static func openLegal(_ name: String) {
        guard let url = GrainBookLink.url(name) else { return }
        _ = consume(url)
    }

    static func openInside(document name: String) {
        openLegal(name)
    }

    @discardableResult
    static func consume(_ url: URL) -> Bool {
        if isSettingsLink(url) {
            openAppSettings()
            return true
        }
        if let name = GrainBookLink.legalName(url) {
            presentPage(document: name)
            return true
        }
        let scheme = (url.scheme ?? "").lowercased()
        guard scheme == GrainBookLink.scheme else { return false }
        let host = (url.host ?? "").lowercased()
        if host == "browser" {
            if let target = queryValue(url, "url") {
                openOutside(target)
            }
            return true
        }
        if host == "page" {
            if let raw = queryValue(url, "url") {
                openInside(url: raw)
            }
            return true
        }
        return false
    }

    static func isSettingsLink(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        guard scheme == GrainBookLink.scheme else { return false }
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
