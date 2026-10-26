import SwiftUI
import LocalAuthentication

@MainActor
final class AppPrivacy: ObservableObject {
    @Published var isUnlocked = false
    @Published var isAuthenticating = false
    @Published var message: String?
    private var context: LAContext?

    func lock() {
        context?.invalidate()
        context = nil
        isAuthenticating = false
        isUnlocked = false
        message = nil
    }

    func unlock() {
        guard !isAuthenticating else { return }
        let authContext = LAContext()
        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            message = "Set up a device passcode in iPhone Settings to unlock your journal."
            return
        }
        context = authContext
        isAuthenticating = true
        authContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your private Daygrain journal") { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self, self.context === authContext else { return }
                self.isAuthenticating = false
                self.isUnlocked = success
                if !success, let error = error as? LAError, error.code != .appCancel && error.code != .systemCancel && error.code != .userCancel {
                    self.message = "Could not unlock your journal. Please try again."
                }
            }
        }
    }

    static func checkAvailability() throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw JournalError.persistence("Set up Face ID, Touch ID, or a device passcode in iPhone Settings before enabling App Lock.")
        }
    }
}
