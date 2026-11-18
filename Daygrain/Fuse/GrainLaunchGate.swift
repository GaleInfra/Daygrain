import SwiftUI
import UIKit

enum DaygrainBrandRoute: Equatable {
    case launching
    case native
    case activity
}

@MainActor
final class DaygrainLaunchOrchestrator: ObservableObject {
    @Published var route: DaygrainBrandRoute = .launching
    private(set) var shouldOpenActivity = false
    private var observing = false

    func startObserving() {
        guard !observing else { return }
        observing = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onStartupSettled),
            name: .daygrainBrandStartupSettled,
            object: nil
        )
    }

  func recordQuery(status: Int) {
        shouldOpenActivity = (status == 480)
        // A 200 is the one status that means this install was answered by the query endpoint.
        // Activity state, timeout and transport failure all reach here too, and none of them
        // is a registration.
        GrainSignalDesk.shared.launchQuerySettled(status: status)
    }

    @objc private func onStartupSettled() {
        route = shouldOpenActivity ? .activity : .native
    }
}

struct DaygrainBrandCurtainView: View {
    @ObservedObject var orchestrator: DaygrainLaunchOrchestrator

    var body: some View {
        DaygrainBrandCurtainRepresentable(orchestrator: orchestrator)
            .ignoresSafeArea()
    }
}

struct DaygrainBrandCurtainRepresentable: UIViewControllerRepresentable {
    @ObservedObject var orchestrator: DaygrainLaunchOrchestrator

    func makeUIViewController(context: Context) -> DaygrainBrandCurtainController {
        let controller = DaygrainBrandCurtainController()
        controller.orchestrator = orchestrator
        return controller
    }

    func updateUIViewController(_ uiViewController: DaygrainBrandCurtainController, context: Context) {
        uiViewController.orchestrator = orchestrator
    }
}

struct GrainActivityRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        DaygrainSheetVessel.makeActivityHost()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class DaygrainBrandCurtainController: UIViewController {
    weak var orchestrator: DaygrainLaunchOrchestrator?
    private var isLaunching = true
    private let started = Date()
    private var settled = false
    private var queryAttempts = 0
    private let wheel = CAShapeLayer()
    private let launchWindow: TimeInterval = 15
    private let retryGap: TimeInterval = 0.4
    private let minimumHold: TimeInterval = 0.9
    private let activityCode = 480

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
            self?.finishLaunch()
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
        DaygrainVeil.postQuery { [weak self] status, _ in
            guard let self, self.isLaunching else { return }
            Task { @MainActor in
                self.orchestrator?.recordQuery(status: status)
            }
            if status == self.activityCode || status == 200 {
                self.finishLaunch()
                return
            }
            if self.queryAttempts < 1 {
                self.queryAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryGap) { [weak self] in
                    self?.sendLaunchQuery()
                }
                return
            }
            self.finishLaunch()
        }
    }

    private func finishLaunch() {
        guard !settled, isLaunching else { return }
        settled = true
        isLaunching = false
        let elapsed = Date().timeIntervalSince(started)
        let hold = max(0, minimumHold - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            NotificationCenter.default.post(name: .daygrainBrandStartupSettled, object: nil)
        }
    }
}