import SwiftUI
import SwiftData

/// Personal reading list: every story the user bookmarked, newest first.
struct SavedPostsView: View {
    @Environment(\.modelContext) private var context
    @Query private var bookmarks: [Bookmark]

    let user: AppUser

    init(user: AppUser) {
        self.user = user
        let username = user.username
        _bookmarks = Query(
            filter: #Predicate<Bookmark> { $0.username == username },
            sort: \Bookmark.savedAt,
            order: .reverse
        )
    }

    private var validBookmarks: [Bookmark] {
        bookmarks.filter { $0.post != nil }
    }

    var body: some View {
        Group {
            if validBookmarks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(validBookmarks) { bookmark in
                        if let post = bookmark.post {
                            NavigationLink {
                                PostDetailView(post: post, user: user)
                            } label: {
                                row(post: post, savedAt: bookmark.savedAt)
                            }
                        }
                    }
                    .onDelete(perform: remove)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.benchPaper)
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.large)
        .benchmarkBranded()
    }

    private func row(post: Post, savedAt: Date) -> some View {
        HStack(spacing: 12) {
            thumbnail(for: post)

            VStack(alignment: .leading, spacing: 4) {
                if let category = post.category {
                    Text(category.name)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(0.6)
                        .foregroundStyle(.benchGold)
                }

                Text(post.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.benchNavy)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("Saved \(savedAt, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption2)
                        .foregroundStyle(.benchSlate)

                    if !post.isLive {
                        Text("No longer live")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumbnail(for post: Post) -> some View {
        if let firstImage = post.imageURLs.first {
            RemoteImageView(urlString: firstImage, height: 56, cornerRadius: 10)
                .frame(width: 72)
        } else if let firstData = post.photoData.first {
            DataImageView(data: firstData, height: 56, cornerRadius: 10)
                .frame(width: 72)
        } else {
            Color.benchNavy.opacity(0.07)
                .frame(width: 72, height: 56)
                .overlay {
                    Image(systemName: "newspaper")
                        .font(.callout)
                        .foregroundStyle(.benchSlate.opacity(0.5))
                }
                .clipShape(.rect(cornerRadius: 10))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image("benchmark_logo_lightblue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
                .foregroundStyle(.benchBlue.opacity(0.5))
            Text("Nothing saved yet")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text("Tap the bookmark on any story to build your personal reading list.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func remove(at offsets: IndexSet) {
        for index in offsets {
            context.delete(validBookmarks[index])
        }
        try? context.save()
    }
}
