import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(SessionManager.self) private var session
    @Query private var users: [AppUser]

    private var currentUser: AppUser? {
        guard let username = session.currentUsername else { return nil }
        return users.first { $0.username == username && $0.isActive }
    }

    var body: some View {
        Group {
            if let user = currentUser {
                MainTabView(user: user)
                    .transition(.opacity)
            } else if session.isShowingLogin {
                LoginView()
                    .transition(.opacity)
                    .floatingHomeButton(bottomPadding: 24) {
                        session.goHome()
                    }
            } else {
                // Default experience: the public news site, no account needed.
                // This IS the landing page — no home button needed here.
                // Wrapped in NavigationStack so value-based NavigationLinks work.
                NavigationStack {
                    SiteHomeView(user: nil)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.currentUsername)
        .animation(.easeInOut(duration: 0.3), value: session.isShowingLogin)
    }
}

#Preview {
    ContentView()
        .environment(SessionManager())
        .modelContainer(for: [AppUser.self, PostCategory.self, Post.self, SiteSettings.self, Bookmark.self, Internship.self], inMemory: true)
}
