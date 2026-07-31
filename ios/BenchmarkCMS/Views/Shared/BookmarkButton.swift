import SwiftUI
import SwiftData

/// Toggleable bookmark control shown to authenticated users on story
/// cards and in the reader toolbar.
struct BookmarkButton: View {
    enum Style {
        case card
        case toolbar
    }

    @Environment(\.modelContext) private var context
    @Query private var bookmarks: [Bookmark]

    let post: Post
    let username: String
    var style: Style = .card

    init(post: Post, username: String, style: Style = .card) {
        self.post = post
        self.username = username
        self.style = style
        _bookmarks = Query(filter: #Predicate<Bookmark> { $0.username == username })
    }

    private var existingBookmark: Bookmark? {
        bookmarks.first { $0.post?.persistentModelID == post.persistentModelID }
    }

    private var isSaved: Bool { existingBookmark != nil }

    var body: some View {
        Button {
            toggle()
        } label: {
            switch style {
            case .card:
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSaved ? .benchGold : Color.benchNavy)
                    .frame(width: 34, height: 34)
                    .background(.regularMaterial, in: .circle)
                    .shadow(color: Color.benchNavy.opacity(0.15), radius: 4, y: 2)
                    .contentTransition(.symbolEffect(.replace))
            case .toolbar:
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isSaved ? .benchGold : Color.benchNavy)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
        .accessibilityLabel(isSaved ? "Remove from Saved" : "Save story")
    }

    private func toggle() {
        withAnimation(.snappy) {
            if let existingBookmark {
                context.delete(existingBookmark)
            } else {
                context.insert(Bookmark(username: username, post: post))
            }
            try? context.save()
        }
    }
}
