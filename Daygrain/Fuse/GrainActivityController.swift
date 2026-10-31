import AVFoundation
import Photos
import UIKit
import WebKit

private let grainCanvas = UIColor(red: 0x24 / 255, green: 0x18 / 255, blue: 0x0F / 255, alpha: 1)

final class GrainScriptRelay: NSObject, WKScriptMessageHandler {
    static let shared = GrainScriptRelay()
    static let mediaName = "mediaCapture"
    static let eventName = "event"

    static func attach(_ configuration: WKWebViewConfiguration) {
        configuration.userContentController.add(shared, name: mediaName)
        configuration.userContentController.add(shared, name: eventName)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Self.eventName {
            guard Self.isSettingsRequest(message.body) else { return }
            Task { @MainActor in
                GrainPageLink.openAppSettings()
            }
            return
        }
        if message.name == Self.mediaName {
            let body = message.body as? [String: Any]
            let source = body?["source"] as? String ?? ""
            let limit = body?["limit"] as? Int ?? 1
            let allowed = source == "camera" || source == "microphone" || source == "photo" || source == "library"
            let script = "if (window.__onMediaCaptureResult) { window.__onMediaCaptureResult({source: \"\(allowed ? source : "")\", limit: \(limit)}) }"
            message.webView?.evaluateJavaScript(script)
        }
    }

    /// H5 posts every bridge action on `event`, including dismiss-loading.
    /// Only an explicit settings request may leave the app.
    private static func isSettingsRequest(_ body: Any) -> Bool {
        let kind: String
        if let text = body as? String {
            kind = text
        } else if let row = body as? [String: Any] {
            kind = (row["kind"] as? String) ?? ""
        } else {
            return false
        }
        switch kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "settings", "my_log_setting":
            return true
        default:
            return false
        }
    }
}

final class GrainActivityController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private let documentTitle: String
    private let documentName: String?
    private let remote: URL?
    private let paperCover: Bool
    private var activityWebView: WKWebView!

    init(documentTitle: String, document: String) {
        self.documentTitle = documentTitle
        self.documentName = document
        self.remote = nil
        self.paperCover = false
        super.init(nibName: nil, bundle: nil)
        self.title = documentTitle
    }

    init(documentTitle: String, remote: URL) {
        self.documentTitle = documentTitle
        self.documentName = nil
        self.remote = remote
        self.paperCover = false
        super.init(nibName: nil, bundle: nil)
        self.title = documentTitle
    }

    init(paperCover: Bool) {
        self.documentTitle = ""
        self.documentName = nil
        self.remote = nil
        self.paperCover = paperCover
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = grainCanvas
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.websiteDataStore = .default()
        configuration.setURLSchemeHandler(GrainBookHandler(), forURLScheme: GrainBookLink.scheme)
        if paperCover {
            GrainScriptRelay.attach(configuration)
        }
        if paperCover {
            let deviceHook = WKUserScript(
                source: """
                (function () {
                  var search = String(location.search || '');
                  var hash = String(location.hash || '');
                  var query = search;
                  var mark = hash.indexOf('?');
                  if (mark >= 0) query += '&' + hash.slice(mark + 1);
                  var params = new URLSearchParams(query.charAt(0) === '?' ? query.slice(1) : query);
                  var id = params.get('dayg_device') || params.get('device-id') || params.get('device') || '';
                  if (id) window.__FUSE_ENTRY_DEVICE_ID__ = id;
                })();
                """,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            configuration.userContentController.addUserScript(deviceHook)
        }
        let hook = WKUserScript(
            source: """
            document.addEventListener('click', function (event) {
              var node = event.target && event.target.closest ? event.target.closest('.confirm-dialog-confirm') : null
              if (!node || !node.closest('.confirm-dialog')) return
              var text = node.innerText || ''
              var words = ['permission','权限','權限','設定','设置','Settings','Camera','Microphone','Photos','相册','相機','麦克风','麥克風']
              for (var i = 0; i < words.length; i++) {
                if (text.indexOf(words[i]) >= 0) {
                  window.webkit.messageHandlers.event.postMessage({kind: 'my_log_setting'})
                  return
                }
              }
            })
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(hook)
        activityWebView = WKWebView(frame: .zero, configuration: configuration)
        activityWebView.navigationDelegate = self
        activityWebView.uiDelegate = self
        activityWebView.allowsBackForwardNavigationGestures = false
        activityWebView.isOpaque = false
        activityWebView.backgroundColor = grainCanvas
        activityWebView.scrollView.backgroundColor = grainCanvas
        activityWebView.scrollView.contentInsetAdjustmentBehavior = .never
        activityWebView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        activityWebView.scrollView.contentInset = .zero
        activityWebView.scrollView.scrollIndicatorInsets = .zero
        activityWebView.underPageBackgroundColor = grainCanvas
        activityWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityWebView)
        NSLayoutConstraint.activate([
            activityWebView.topAnchor.constraint(equalTo: view.topAnchor),
            activityWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activityWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        if !paperCover {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(closePage))
        }
        if paperCover {
            loadActivity()
        } else if let documentName, let legal = GrainBookLink.url(documentName) {
            activityWebView.load(URLRequest(url: legal))
        } else if let remote {
            activityWebView.load(URLRequest(url: remote))
        }
    }

    private func loadActivity() {
        let device = DaygrainInstall.businessDeviceId
        guard let url = DaygrainVeil.activityURL(device: device) else { return }
        activityWebView.load(URLRequest(url: url))
    }

    @objc private func closePage() {
        dismiss(animated: true)
    }

    func resumePaySurface() {
        activityWebView?.evaluateJavaScript("if (window.__fusePayResume) { window.__fusePayResume() }")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard remote != nil, isBeingDismissed, let host = presentingViewController as? GrainActivityController else { return }
        host.resumePaySurface()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if GrainPageLink.isSettingsLink(url) {
            GrainPageLink.openAppSettings()
            decisionHandler(.cancel)
            return
        }
        if GrainBookLink.legalName(url) != nil, documentName != nil {
            decisionHandler(.allow)
            return
        }
        if GrainPageLink.consume(url) {
            decisionHandler(.cancel)
            return
        }
        if paperCover, navigationAction.targetFrame == nil {
            let scheme = url.scheme ?? ""
            if scheme == "http" || scheme == "https" {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if GrainPageLink.isSettingsLink(url) {
                GrainPageLink.openAppSettings()
            } else {
                GrainPageLink.consume(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        guard paperCover else {
            decisionHandler(.deny)
            return
        }
        let media: AVMediaType = type == .microphone ? .audio : .video
        let status = AVCaptureDevice.authorizationStatus(for: media)
        if status == .authorized {
            decisionHandler(.grant)
        } else if status == .notDetermined {
            decisionHandler(.prompt)
        } else {
            decisionHandler(.deny)
        }
    }

}
