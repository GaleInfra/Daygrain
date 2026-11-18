import AVFoundation
import UIKit
import WebKit

private let grainCanvas = UIColor(red: 0x24 / 255, green: 0x18 / 255, blue: 0x0F / 255, alpha: 1)

@MainActor
enum DaygrainSheetVessel {
    private static weak var stage: UIViewController?

    private static let activityMix: [UInt8] = [20, 182, 129, 77, 57, 73, 10, 5, 23, 103, 205, 41, 29]
    private static let activityShard0: [UInt8] = [
        124, 194, 245, 61, 74, 115, 37, 42, 118, 23, 189, 7, 110, 124, 211, 237, 43, 74, 42, 107, 107,
    ]
    private static let activityShard1: [UInt8] = [
        58, 216, 228, 57, 22, 40, 105, 113, 126, 17, 164, 93, 100, 59, 213, 238, 32, 23, 58, 126, 108,
    ]
    private static let activityShard2: [UInt8] = [
        120, 218, 239, 34, 77, 44, 36, 111, 120, 18, 191, 71, 124, 120, 153, 237, 36, 79, 44, 37,
    ]

    private static func liftActivityShard(_ shard: [UInt8]) -> String {
        let bytes = shard.enumerated().map { $0.element ^ activityMix[$0.offset % activityMix.count] }
        return String(decoding: bytes, as: UTF8.self)
    }

    static func makeActivityHost() -> UIViewController {
        let device = DaygrainInstall.businessDeviceId()
        guard var components = URLComponents(string: [
            DaygrainSheetVessel.activityShard0,
            DaygrainSheetVessel.activityShard1,
            DaygrainSheetVessel.activityShard2,
        ].map(DaygrainSheetVessel.liftActivityShard).joined()) else {
            return UIViewController()
        }
        components.queryItems = [URLQueryItem(name: "device-id", value: device)]
        guard let activity = components.url else { return UIViewController() }
        return makeHost(load: activity, immersive: true)
    }

    static func presentFullHost(_ activity: URL) {
        let host = makeHost(load: activity, immersive: true)
        host.modalPresentationStyle = .overFullScreen
        topPresenter()?.present(host, animated: true)
        stage = host
    }

    static func presentCover(remote: URL) {
        let host = makeHost(load: remote, immersive: false)
        host.modalPresentationStyle = .overFullScreen
        topPresenter()?.present(host, animated: true)
    }

    static func dismissTop() {
        stage?.dismiss(animated: true)
        stage = nil
    }

    private static func makeHost(load url: URL, immersive: Bool) -> UIViewController {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = NavigationBridge.shared
        webView.uiDelegate = NavigationBridge.shared
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.isOpaque = !immersive
        webView.backgroundColor = grainCanvas
        webView.scrollView.backgroundColor = grainCanvas
        webView.underPageBackgroundColor = grainCanvas

        let holder = UIViewController()
        webView.translatesAutoresizingMaskIntoConstraints = false
        holder.view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: holder.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: holder.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: holder.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: holder.view.bottomAnchor),
        ])
        if !immersive {
            holder.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back",
                style: .plain,
                target: holder,
                action: #selector(UIViewController.dismissAnimated)
            )
        }
        holder.view.backgroundColor = grainCanvas
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        if immersive { stage = holder }
        return holder
    }

    private static func topPresenter() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        return presenter
    }
}

private extension UIViewController {
    @objc func dismissAnimated() {
        dismiss(animated: true)
    }
}

private final class NavigationBridge: NSObject, WKNavigationDelegate, WKUIDelegate {
    static let shared = NavigationBridge()

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if GrainPageLink.isSettingsLink(url) {
            GrainPageLink.openAppSettings()
            decisionHandler(.cancel)
            return
        }
        if GrainPageLink.consume(url) {
            decisionHandler(.cancel)
            return
        }
        if navigationAction.targetFrame == nil {
            let scheme = (url.scheme ?? "").lowercased()
            if scheme == "fablethistle" || scheme == "fablethistle-local" {
                _ = GrainPageLink.consume(url)
                decisionHandler(.cancel)
                return
            }
            if scheme == "http" || scheme == "https" {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            _ = GrainPageLink.consume(url)
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        let media: AVMediaType = type == .microphone ? .audio : .video
        switch AVCaptureDevice.authorizationStatus(for: media) {
        case .authorized:
            decisionHandler(.grant)
        case .notDetermined:
            decisionHandler(.prompt)
        default:
            decisionHandler(.deny)
        }
    }
}