import SwiftUI
import SwiftData

/// Admin: every post in the system, searchable, with quick actions.
struct ContentManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Post.updatedAt, order: .reverse) private var posts: [Post]

    let user: AppUser

    @State private var searchText = ""
    @State private var statusFilter: PostStatus?

    private var filteredPosts: [Post] {
        var result = posts
        if let statusFilter {
            result = result.filter { $0.status == statusFilter }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedStandardContains(query)
                    || $0.summary.localizedStandardContains(query)
                    || $0.authorName.localizedStandardContains(query)
            }
        }
        return result
    }

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $statusFilter) {
                    Text("All Statuses").tag(nil as PostStatus?)
                    ForEach(PostStatus.allCases) { status in
                        Text(status.label).tag(status as PostStatus?)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("\(filteredPosts.count) post\(filteredPosts.count == 1 ? "" : "s")") {
                ForEach(filteredPosts) { post in
                    NavigationLink(value: post) {
                        contentRow(post)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            context.delete(post)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        if post.isLive {
                            Button {
                                post.status = .archived
                                post.touch()
                                try? context.save()
                            } label: {
                                Label("Unpublish", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search title, summary, author")
        .navigationTitle("All Content")
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
        .navigationDestination(for: Post.self) { post in
            ReviewDetailView(post: post, user: user)
        }
    }

    private func contentRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(post.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.benchNavy)
                .lineLimit(2)

            HStack(spacing: 8) {
                StatusBadge(post: post)
                if let category = post.category {
                    Text(category.name)
                        .font(.caption2)
                        .foregroundStyle(.benchSlate)
                }
            }

            Text("By \(post.authorName.isEmpty ? "Unknown" : post.authorName) · updated \(post.updatedAt, format: .relative(presentation: .named))")
                .font(.caption2)
                .foregroundStyle(.benchSlate.opacity(0.8))
        }
        .padding(.vertical, 2)
    }
}
