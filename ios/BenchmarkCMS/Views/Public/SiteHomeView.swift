import SwiftUI
import SwiftData

/// Live preview of subenchmark.blooksy.com: category top navigation,
/// featured story, search, and the published feed.
struct SiteHomeView: View {
    @Environment(SessionManager.self) private var session
    @Query(sort: \PostCategory.sortOrder) private var categories: [PostCategory]
    @Query(sort: \Post.publishDate, order: .reverse) private var posts: [Post]
    @Query private var settingsList: [SiteSettings]

    /// Signed-in account, or nil when browsing publicly as a guest.
    var user: AppUser?

    @State private var selectedCategory: PostCategory?
    @State private var searchText = ""

    private var settings: SiteSettings? { settingsList.first }

    private var visibleCategories: [PostCategory] {
        categories.filter { !$0.isHidden }
    }

    private var livePosts: [Post] {
        posts.filter { post in
            guard post.isLive else { return false }
            guard let category = post.category else { return true }
            return !category.isHidden
        }
    }

    private var filteredPosts: [Post] {
        var result = livePosts
        if let selectedCategory {
            result = result.filter { $0.category?.slug == selectedCategory.slug }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedStandardContains(query)
                    || $0.summary.localizedStandardContains(query)
                    || $0.bodyText.localizedStandardContains(query)
                    || ($0.category?.name.localizedStandardContains(query) ?? false)
            }
        }
        return result
    }

    private var featuredPost: Post? {
        guard settings?.showFeaturedPost ?? true,
              selectedCategory == nil,
              searchText.isEmpty else { return nil }
        return filteredPosts.first
    }

    private var feedPosts: [Post] {
        if let featuredPost {
            return filteredPosts.filter { $0.persistentModelID != featuredPost.persistentModelID }
        }
        return filteredPosts
    }

    var body: some View {
        VStack(spacing: 0) {
            // Masthead (logo + search) stays fixed while stories scroll beneath it.
            masthead

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    categoryNav

                    // Internship promo banner
                    NavigationLink {
                        InternshipsView(user: user, isTabRoot: false)
                    } label: {
                        internshipBanner
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    if let featuredPost {
                        NavigationLink(value: featuredPost) {
                            PostCardView(post: featuredPost, featured: true, user: user)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }

                    if feedPosts.isEmpty && featuredPost == nil {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(feedPosts) { post in
                                NavigationLink(value: post) {
                                    PostCardView(post: post, user: user)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    footer
                }
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .background(Color.benchPaper)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post, user: user)
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Spacer()

                if user != nil {
                    Link(destination: URL(string: settings?.siteURL ?? "https://subenchmark.blooksy.com") ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: 4) {
                            Image(systemName: "safari.fill")
                            Text("Visit Site")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.benchGold)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(settings?.siteTitle ?? "Benchmark")
                    .font(.title.weight(.bold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)

                Text("powered by the College of Sciences and Engineering")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.benchGold)
            }

            Text(settings?.tagline ?? "Showcasing Southern University's excellence to the world.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))

            if user == nil {
                Button {
                    session.isShowingLogin = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                        Text("Sign In")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.benchNavyDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.benchGold, in: .capsule)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if settings?.showSearch ?? true {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.6))
                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("Search stories…").foregroundStyle(.white.opacity(0.5))
                    )
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12), in: .capsule)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient.benchHeader
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.benchSteel.opacity(0.16))
                        .frame(width: 260, height: 260)
                        .offset(x: 100, y: -110)
                }
                .clipped()
        )
        .clipShape(.rect(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Category navigation

    private var categoryNav: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.snappy) { selectedCategory = nil }
                }
                ForEach(visibleCategories) { category in
                    categoryChip(
                        label: category.name,
                        isSelected: selectedCategory?.slug == category.slug
                    ) {
                        withAnimation(.snappy) { selectedCategory = category }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
    }

    private func categoryChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : Color.benchNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.benchNavy : Color.benchNavy.opacity(0.07),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty & footer

    private var emptyState: some View {
        VStack(spacing: 14) {
            if searchText.isEmpty {
                Image("benchmark_logo_lightblue")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38))
                    .foregroundStyle(.benchBlue.opacity(0.5))
            }
            Text(searchText.isEmpty ? "No published stories yet" : "No matches for “\(searchText)”")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text(searchText.isEmpty
                 ? "Approved content appears here automatically."
                 : "Try a different search term or category.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Internship banner

    @Query private var internships: [Internship]

    private var openInternshipCount: Int {
        internships.filter { $0.isPublished && !$0.isExpired }.count
    }

    private var internshipBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.benchGold.opacity(0.15))
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.benchGold)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Internship Board")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.benchNavy)
                Text(openInternshipCount > 0
                     ? "\(openInternshipCount) open opportunities for students"
                     : "Browse opportunities for Southern University students")
                    .font(.caption)
                    .foregroundStyle(.benchSlate)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.benchGold)
        }
        .padding(16)
        .background(Color.benchCard)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.benchNavy.opacity(0.06), radius: 8, y: 3)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(Color.benchNavy.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 40)
            Text(settings?.footerText ?? "")
                .font(.caption2)
                .foregroundStyle(.benchSlate)
            Text(settings?.siteURL.replacingOccurrences(of: "https://", with: "") ?? "")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.benchSteel)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}
