import SwiftUI
import SwiftData

/// Contributor workspace: drafts, submissions, and status tracking.
struct MyPostsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Post.updatedAt, order: .reverse) private var allPosts: [Post]

    let user: AppUser

    @State private var newPost: Post?
    @State private var filter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case inProgress = "In Progress"
        case awaiting = "Awaiting Review"
        case needsAttention = "Needs Attention"
        case live = "Published"

        var id: String { rawValue }
    }

    private var myPosts: [Post] {
        // Admins and approvers see their own authored posts here too.
        allPosts.filter { $0.author?.username == user.username }
    }

    private var filteredPosts: [Post] {
        switch filter {
        case .all: return myPosts
        case .inProgress: return myPosts.filter { $0.status == .draft }
        case .awaiting: return myPosts.filter { $0.status == .submitted }
        case .needsAttention: return myPosts.filter { $0.status == .changesRequested || $0.status == .rejected }
        case .live: return myPosts.filter { $0.status == .published }
        }
    }

    var body: some View {
        Group {
            if myPosts.isEmpty {
                emptyState
            } else {
                postList
            }
        }
        .background(Color.benchPaper)
        .navigationTitle("My Posts")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BenchmarkLogoMark()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createDraft()
                } label: {
                    Label("New Draft", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .navigationDestination(item: $newPost) { post in
            PostEditorView(post: post, user: user)
        }
        .navigationDestination(for: Post.self) { post in
            PostEditorView(post: post, user: user)
        }
    }

    private var postList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                statsRow

                Picker("Filter", selection: $filter) {
                    ForEach(StatusFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(.benchNavy)

                ForEach(filteredPosts) { post in
                    NavigationLink(value: post) {
                        postRow(post)
                    }
                    .buttonStyle(.plain)
                }

                if filteredPosts.isEmpty {
                    Text("Nothing here yet.")
                        .font(.subheadline)
                        .foregroundStyle(.benchSlate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statChip(count: myPosts.filter { $0.status == .draft }.count, label: "Drafts", tint: .benchSlate)
            statChip(count: myPosts.filter { $0.status == .submitted }.count, label: "In Review", tint: .benchSteel)
            statChip(count: myPosts.filter { $0.isLive }.count, label: "Live", tint: PostStatus.published.tint)
        }
        .padding(.top, 6)
    }

    private func statChip(count: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(.benchSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.benchCard, in: .rect(cornerRadius: 14))
        .shadow(color: Color.benchNavy.opacity(0.05), radius: 6, y: 3)
    }

    private func postRow(_ post: Post) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(post.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.benchNavy)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    StatusBadge(post: post)
                    if let category = post.category {
                        Text(category.name)
                            .font(.caption2)
                            .foregroundStyle(.benchSlate)
                    }
                }

                if post.status == .changesRequested || post.status == .rejected,
                   !post.reviewFeedback.isEmpty {
                    Label(post.reviewFeedback, systemImage: "text.bubble.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }

                Text("Updated \(post.updatedAt, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(.benchSlate.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.benchSlate.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color.benchCard, in: .rect(cornerRadius: 16))
        .shadow(color: Color.benchNavy.opacity(0.05), radius: 6, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image("benchmark_logo_lightblue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 44)
                .foregroundStyle(.benchBlue.opacity(0.6))
            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text("Start a draft, add your story, and submit it for approval.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
                .multilineTextAlignment(.center)
            Button {
                createDraft()
            } label: {
                Label("Start a Draft", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.benchNavy, in: .capsule)
                    .foregroundStyle(.white)
            }
        }
        .padding(32)
    }

    private func createDraft() {
        let post = Post(author: user)
        post.authorName = user.fullName
        context.insert(post)
        try? context.save()
        newPost = post
    }
}
