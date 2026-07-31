import SwiftUI
import SwiftData

/// Role-aware tab shell: everyone sees the Site; tabs expand with permissions.
/// Contributors see Site, Internships, My Posts, Account.
/// Approvers also see Review.
/// Publishers also see Publish.
/// Admins see everything including Manage.
struct MainTabView: View {
    @Environment(SessionManager.self) private var session
    let user: AppUser

    @State private var selectedTab: Tab = .site
    @State private var sitePath = NavigationPath()
    @State private var internshipsPath = NavigationPath()
    @State private var myPostsPath = NavigationPath()
    @State private var reviewPath = NavigationPath()
    @State private var publishPath = NavigationPath()
    @State private var managePath = NavigationPath()

    enum Tab: String, Hashable {
        case site, internships, myPosts, review, publish, manage, account
    }

    var body: some View {
        @Bindable var session = session
        return TabView(selection: $selectedTab) {
            siteTab
                .tabItem { Label("Site", systemImage: "globe.americas.fill") }
                .tag(Tab.site)

            internshipsTab
                .tabItem { Label("Internships", systemImage: "briefcase.fill") }
                .tag(Tab.internships)

            myPostsTab
                .tabItem { Label("My Posts", systemImage: "square.and.pencil") }
                .tag(Tab.myPosts)

            if user.role.canReview {
                reviewTab
                    .tabItem { Label("Review", systemImage: "checkmark.seal") }
                    .tag(Tab.review)
            }

            if user.role.canPublish {
                publishTab
                    .tabItem { Label("Publish", systemImage: "dot.radiowaves.left.and.right") }
                    .tag(Tab.publish)
            }

            if user.role.canAdminister {
                manageTab
                    .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
                    .tag(Tab.manage)
            }

            AccountView(user: user)
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(Tab.account)
        }
        .tint(.benchNavy)
        .fullScreenCover(item: $session.pendingOnboardingRole) { role in
            OnboardingView(role: role) {
                session.pendingOnboardingRole = nil
            }
        }
        // When the floating Home button fires, reset everything.
        .onChange(of: session.homeRequestCount) { _, _ in
            sitePath = NavigationPath()
            internshipsPath = NavigationPath()
            myPostsPath = NavigationPath()
            reviewPath = NavigationPath()
            publishPath = NavigationPath()
            managePath = NavigationPath()
            selectedTab = .site
        }
        // Pervasive floating Home button — visible on every tab.
        .floatingHomeButton(bottomPadding: 88) {
            session.goHome()
        }
    }

    // MARK: - Tab views

    private var siteTab: some View {
        NavigationStack(path: $sitePath) {
            SiteHomeView(user: user)
        }
    }

    private var internshipsTab: some View {
        NavigationStack(path: $internshipsPath) {
            InternshipsView(user: user, isTabRoot: true)
        }
    }

    private var myPostsTab: some View {
        NavigationStack(path: $myPostsPath) {
            MyPostsView(user: user)
        }
    }

    private var reviewTab: some View {
        NavigationStack(path: $reviewPath) {
            ReviewQueueView(user: user)
        }
    }

    private var publishTab: some View {
        NavigationStack(path: $publishPath) {
            PublishQueueView(user: user)
        }
    }

    private var manageTab: some View {
        NavigationStack(path: $managePath) {
            AdminView(user: user)
        }
    }
}

/// Simple profile + sign-out screen.
struct AccountView: View {
    @Environment(SessionManager.self) private var session
    @Query(sort: \PostCategory.sortOrder) private var categories: [PostCategory]
    let user: AppUser

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(user.role.tint.opacity(0.15))
                            Text(user.initials)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(user.role.tint)
                        }
                        .frame(width: 58, height: 58)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.fullName).font(.headline)
                            Text(user.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !user.email.isEmpty {
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.benchSlate)
                            }
                            Label(user.role.displayLabel, systemImage: user.role.icon)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(user.role.tint)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Reading List") {
                    NavigationLink {
                        SavedPostsView(user: user)
                    } label: {
                        Label {
                            Text("Saved Stories")
                        } icon: {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.benchYellow)
                        }
                    }
                }

                Section("Permissions") {
                    ForEach(user.role.permissions, id: \.label) { perm in
                        Label(perm.label, systemImage: perm.granted ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(perm.granted ? Color.benchNavy : .secondary)
                    }
                }

                if user.hasAssignedCategories {
                    Section("Assigned Categories") {
                        Text(user.categoryAssignmentLabel(from: categories))
                            .font(.subheadline)
                            .foregroundStyle(.benchSlate)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        session.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("About") {
                    VStack(spacing: 12) {
                        Image("benchmark_logo_black")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 28)
                            .frame(maxWidth: .infinity)

                        Text("Showcasing Southern University's excellence to the world.")
                            .font(.caption)
                            .foregroundStyle(.benchSlate)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Account")
            .benchmarkBranded()
            .scrollContentBackground(.hidden)
            .background(Color.benchPaper)
        }
    }
}
