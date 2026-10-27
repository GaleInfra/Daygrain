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
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.websiteDataStore = .default()
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
        } else if let documentName {
            activityWebView.loadHTMLString(pageHTML(documentName), baseURL: nil)
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

    private func pageHTML(_ name: String) -> String {
        let heading = name == "privacy" ? "Privacy" : (name == "terms" ? "Terms" : "Support")
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(heading)</title></head><body style="background:#24180F;color:#F4E7D4;font-family:-apple-system">
        <h1>\(heading)</h1>
        <p>Daygrain is a private journal. This \(heading.lowercased()) page explains how the app handles an entry, a reminder, and messages you send from Settings.</p>
        <p>Journal notes stay on this device. A business install id is stored in the Keychain and is separate from any sign-in name. Daygrain does not sell that id.</p>
        <p>Questions about an entry or this page go through Support in Settings.</p>
        </body></html>
        """
    }
}
