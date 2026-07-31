import SwiftUI

/// Editorial card used on the public site feed.
struct PostCardView: View {
    let post: Post
    var featured: Bool = false

    /// Signed-in account; enables the bookmark control when present.
    var user: AppUser? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let firstImage = post.imageURLs.first {
                RemoteImageView(
                    urlString: firstImage,
                    height: featured ? 220 : 170,
                    cornerRadius: 0
                )
            } else if let firstData = post.photoData.first {
                DataImageView(data: firstData, height: featured ? 220 : 170, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let category = post.category {
                        Text(category.name)
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .kerning(0.8)
                            .foregroundStyle(.benchGold)
                    }
                    Spacer()
                    Text(post.publishDate, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption2)
                        .foregroundStyle(.benchSlate)
                }

                Text(post.displayTitle)
                    .font(featured ? .title2.weight(.bold) : .headline)
                    .fontDesign(.serif)
                    .foregroundStyle(Color.benchNavy)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Label(post.readingTimeLabel, systemImage: "clock")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.benchSlate)

                if !post.summary.isEmpty {
                    Text(post.summary)
                        .font(.subheadline)
                        .foregroundStyle(.benchSlate)
                        .lineLimit(featured ? 3 : 2)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 6) {
                    if !post.videoURL.isEmpty {
                        Label("Video", systemImage: "play.rectangle.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.benchSteel)
                    }
                    if !post.authorName.isEmpty {
                        Text("By \(post.authorName)")
                            .font(.caption2)
                            .foregroundStyle(.benchSlate)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.benchGold)
                }
                .padding(.top, 2)
            }
            .padding(16)
        }
        .background(Color.benchCard)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(alignment: .topTrailing) {
            if let user {
                BookmarkButton(post: post, username: user.username)
                    .padding(10)
            }
        }
        .shadow(color: Color.benchNavy.opacity(0.08), radius: 12, y: 5)
    }
}
