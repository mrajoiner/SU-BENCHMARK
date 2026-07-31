import Foundation
import Observation

/// Tracks the signed-in account across launches.
@Observable
final class SessionManager {
    private static let storageKey = "benchmark.session.username"

    /// The app defaults to the public site; this flips to true when the user
    /// explicitly asks to sign in or register.
    var isShowingLogin: Bool = false

    /// Set when a brand-new account is created so the workspace can show
    /// the role-specific onboarding carousel once.
    var pendingOnboardingRole: UserRole?

    /// Monotonic counter that increments each time the user requests to go
    /// home. ContentView and MainTabView observe this to reset navigation.
    var homeRequestCount: Int = 0

    var currentUsername: String? {
        didSet {
            if let currentUsername {
                UserDefaults.standard.set(currentUsername, forKey: Self.storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.storageKey)
            }
        }
    }

    init() {
        currentUsername = UserDefaults.standard.string(forKey: Self.storageKey)
    }

    func signIn(user: AppUser) {
        isShowingLogin = false
        currentUsername = user.username
    }

    func signOut() {
        currentUsername = nil
        isShowingLogin = false
    }

    /// Called by the floating Home button. Resets to the landing page:
    /// signs out, dismisses login, and clears navigation state.
    func goHome() {
        currentUsername = nil
        isShowingLogin = false
        homeRequestCount += 1
    }
}
