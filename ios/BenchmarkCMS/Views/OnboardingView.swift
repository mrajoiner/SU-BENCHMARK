import SwiftUI

/// Three-screen carousel shown right after registration,
/// tailored to the role the new user picked.
struct OnboardingView: View {
    let role: UserRole
    let onFinish: () -> Void

    @State private var pageIndex = 0

    private var pages: [OnboardingPage] { OnboardingPage.pages(for: role) }
    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    var body: some View {
        ZStack {
            LinearGradient.benchHeader.ignoresSafeArea()

            Circle()
                .fill(Color.benchBlue.opacity(0.15))
                .frame(width: 340, height: 340)
                .offset(x: 130, y: -300)
                .blur(radius: 4)

            VStack(spacing: 0) {
                HStack {
                    Image("benchmark_logo_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)

                    Spacer()

                    if !isLastPage {
                        Button("Skip") { onFinish() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy, value: pageIndex)

                pageDots
                    .padding(.bottom, 22)

                Button {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation(.snappy) { pageIndex += 1 }
                    }
                } label: {
                    Text(isLastPage ? "Enter Your Workspace" : "Continue")
                        .font(.headline)
                        .foregroundStyle(Color.benchNavyDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.benchYellow, in: .rect(cornerRadius: 16))
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.benchYellow)
            }

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.bullets, id: \.text) { bullet in
                    HStack(spacing: 12) {
                        Image(systemName: bullet.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.benchYellow)
                            .frame(width: 24)
                        Text(bullet.text)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? Color.benchYellow : .white.opacity(0.3))
                    .frame(width: index == pageIndex ? 22 : 7, height: 7)
                    .animation(.snappy, value: pageIndex)
            }
        }
    }
}

/// Content for a single onboarding screen.
struct OnboardingPage {
    struct Bullet {
        let icon: String
        let text: String
    }

    let icon: String
    let title: String
    let subtitle: String
    let bullets: [Bullet]

    /// Role-specific decks: three screens each.
    static func pages(for role: UserRole) -> [OnboardingPage] {
        switch role {
        case .contributor:
            return [
                OnboardingPage(
                    icon: "square.and.pencil",
                    title: "Welcome, Contributor",
                    subtitle: "You're part of the Benchmark newsroom. Here's how your account works.",
                    bullets: [
                        Bullet(icon: "doc.badge.plus", text: "Start drafts anytime from the My Posts tab"),
                        Bullet(icon: "externaldrive.badge.checkmark", text: "Everything autosaves as you write"),
                        Bullet(icon: "photo.on.rectangle.angled", text: "Add photos, video links, and calls to action"),
                    ]
                ),
                OnboardingPage(
                    icon: "paperplane.fill",
                    title: "Submit for Review",
                    subtitle: "When your story is ready, send it to the approval team.",
                    bullets: [
                        Bullet(icon: "checkmark.seal", text: "An approver reviews every submission"),
                        Bullet(icon: "text.bubble", text: "You'll see feedback if changes are requested"),
                        Bullet(icon: "arrow.triangle.2.circlepath", text: "Revise and resubmit as many times as needed"),
                    ]
                ),
                OnboardingPage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Every Story",
                    subtitle: "Follow your work from draft to the live site.",
                    bullets: [
                        Bullet(icon: "tag", text: "Status badges show where each post stands"),
                        Bullet(icon: "globe.americas", text: "Approved stories appear on the public site"),
                        Bullet(icon: "bell", text: "Check My Posts for anything needing attention"),
                    ]
                ),
            ]
        case .approver:
            return [
                OnboardingPage(
                    icon: "checkmark.seal.fill",
                    title: "Welcome, Approver",
                    subtitle: "You carry two roles: contributor and approver. Here's what that unlocks.",
                    bullets: [
                        Bullet(icon: "square.and.pencil", text: "Write and submit your own stories"),
                        Bullet(icon: "tray.full", text: "Review every submission in the Review tab"),
                        Bullet(icon: "person.2", text: "Guide contributors with clear feedback"),
                    ]
                ),
                OnboardingPage(
                    icon: "calendar.badge.clock",
                    title: "Publish & Schedule",
                    subtitle: "You decide what goes live on the Benchmark site — and when.",
                    bullets: [
                        Bullet(icon: "bolt.fill", text: "Approve and publish stories instantly"),
                        Bullet(icon: "clock", text: "Schedule posts for a future date and time"),
                        Bullet(icon: "eye.slash", text: "Unpublish or archive content at any point"),
                    ]
                ),
                OnboardingPage(
                    icon: "text.bubble.fill",
                    title: "Keep Quality High",
                    subtitle: "Your review keeps the Benchmark accurate and polished.",
                    bullets: [
                        Bullet(icon: "arrow.uturn.backward", text: "Request changes with notes for the author"),
                        Bullet(icon: "xmark.circle", text: "Reject submissions that miss the mark"),
                        Bullet(icon: "bell.badge", text: "The queue banner alerts you to new submissions"),
                    ]
                ),
            ]
        case .publisher:
            return [
                OnboardingPage(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Welcome, Publisher",
                    subtitle: "You carry two roles: contributor and publisher. Here's what that unlocks.",
                    bullets: [
                        Bullet(icon: "square.and.pencil", text: "Write and submit your own stories"),
                        Bullet(icon: "checkmark.seal", text: "See approved content in the Publish tab"),
                        Bullet(icon: "dot.radiowaves.left.and.right", text: "Make approved stories live on the site"),
                    ]
                ),
                OnboardingPage(
                    icon: "calendar.badge.clock",
                    title: "Publish & Schedule",
                    subtitle: "You control when approved content goes live on the Benchmark.",
                    bullets: [
                        Bullet(icon: "bolt.fill", text: "Publish approved stories instantly"),
                        Bullet(icon: "clock", text: "Schedule posts for a future date and time"),
                        Bullet(icon: "eye.slash", text: "Unpublish or archive content at any point"),
                    ]
                ),
                OnboardingPage(
                    icon: "rectangle.stack.fill.badge.plus",
                    title: "Keep the Site Fresh",
                    subtitle: "Your publishing decisions shape what readers see.",
                    bullets: [
                        Bullet(icon: "tray.full", text: "The Ready tab shows everything approved and waiting"),
                        Bullet(icon: "arrow.up.circle", text: "Republish archived content when needed"),
                        Bullet(icon: "person.2", text: "Work alongside approvers in the workflow"),
                    ]
                ),
            ]
        case .admin:
            return [
                OnboardingPage(
                    icon: "crown.fill",
                    title: "Welcome, Administrator",
                    subtitle: "You have full control of the Benchmark — content, people, and the site itself.",
                    bullets: [
                        Bullet(icon: "square.and.pencil", text: "Write, submit, review, and publish stories"),
                        Bullet(icon: "slider.horizontal.3", text: "The Manage tab is your command center"),
                        Bullet(icon: "chart.bar", text: "See live stats on everything at a glance"),
                    ]
                ),
                OnboardingPage(
                    icon: "person.2.fill",
                    title: "Manage People & Sections",
                    subtitle: "Shape who contributes and how the site is organized.",
                    bullets: [
                        Bullet(icon: "person.badge.plus", text: "Add users and assign their roles"),
                        Bullet(icon: "square.grid.2x2", text: "Create, reorder, and hide categories"),
                        Bullet(icon: "person.badge.minus", text: "Deactivate accounts when needed"),
                    ]
                ),
                OnboardingPage(
                    icon: "gearshape.fill",
                    title: "Run the Site",
                    subtitle: "Everything readers see is yours to configure.",
                    bullets: [
                        Bullet(icon: "doc.text.magnifyingglass", text: "Search and manage all content in every status"),
                        Bullet(icon: "textformat", text: "Edit the site title, tagline, and footer"),
                        Bullet(icon: "eye", text: "Toggle search and the featured story display"),
                    ]
                ),
            ]
        }
    }
}
