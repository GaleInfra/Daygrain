import SwiftUI
import UIKit

enum GrainLaunchRoute: Equatable {
    case launching
    case native
    case activity
}

struct GrainLaunchGateView: View {
    @Binding var route: GrainLaunchRoute

    var body: some View {
        GrainLaunchRepresentable(
            onNative: { route = .native },
            onActivity: { route = .activity }
        )
        .ignoresSafeArea()
    }
}

struct GrainLaunchRepresentable: UIViewControllerRepresentable {
    var onNative: () -> Void
    var onActivity: () -> Void

    func makeUIViewController(context: Context) -> GrainLaunchController {
        let controller = GrainLaunchController()
        controller.onStayNative = onNative
        controller.onShowActivity = onActivity
        return controller
    }

    func updateUIViewController(_ uiViewController: GrainLaunchController, context: Context) {
        uiViewController.onStayNative = onNative
        uiViewController.onShowActivity = onActivity
    }
}

struct GrainActivityRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GrainActivityController {
        GrainActivityController(paperCover: true)
    }

    func updateUIViewController(_ uiViewController: GrainActivityController, context: Context) {}
}

final class GrainLaunchController: UIViewController {
    var onStayNative: (() -> Void)?
    var onShowActivity: (() -> Void)?
    private var isLaunching = true
    private let started = Date()
    private var handedOff = false
    private var queryAttempts = 0
    private let wheel = CAShapeLayer()
    private let launchWindow: TimeInterval = 15
    private let retryGap: TimeInterval = 0.4
    private let minimumHold: TimeInterval = 0.9

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0x24 / 255, green: 0x18 / 255, blue: 0x0F / 255, alpha: 1)
        if let image = UIImage(named: "DaygrainlaunchShot") {
            let launchImage = UIImageView(image: image)
            launchImage.contentMode = .scaleAspectFill
            launchImage.frame = view.bounds
            launchImage.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(launchImage)
        }

        let side: CGFloat = 72
        wheel.frame = CGRect(x: 0, y: 0, width: side, height: side)
        wheel.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY + 40)
        wheel.path = grainPath(side: side).cgPath
        wheel.strokeColor = UIColor(red: 0.89, green: 0.68, blue: 0.57, alpha: 1).cgColor
        wheel.fillColor = UIColor.clear.cgColor
        wheel.lineWidth = 3
        wheel.lineCap = .round
        view.layer.addSublayer(wheel)
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 1.1
        spin.repeatCount = .infinity
        wheel.add(spin, forKey: "daygrainWheel")

        sendLaunchQuery()
        DispatchQueue.main.asyncAfter(deadline: .now() + launchWindow) { [weak self] in
            self?.stayNative()
        }
    }

    private func grainPath(side: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: side / 2, y: side / 2)
        path.addArc(withCenter: center, radius: side / 2 - 4, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        return path
    }

    private func sendLaunchQuery() {
        guard isLaunching else { return }
        DaygrainVeil.postQuery { [weak self] status in
            guard let self, self.isLaunching else { return }
            if status == 480 {
                self.finishLaunch(activity: true)
                return
            }
            if status == 200 {
                self.finishLaunch(activity: false)
                return
            }
            if self.queryAttempts < 1 {
                self.queryAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryGap) { [weak self] in
                    self?.sendLaunchQuery()
                }
                return
            }
            self.finishLaunch(activity: false)
        }
    }

    private func finishLaunch(activity: Bool) {
        let elapsed = Date().timeIntervalSince(started)
        let hold = max(0, minimumHold - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [weak self] in
            guard let self, self.isLaunching else { return }
            if activity {
                self.showActivity()
            } else {
                self.stayNative()
            }
        }
    }

    private func showActivity() {
        guard !handedOff else { return }
        handedOff = true
        isLaunching = false
        onShowActivity?()
    }

    private func stayNative() {
        guard !handedOff else { return }
        handedOff = true
        isLaunching = false
        onStayNative?()
    }
}
