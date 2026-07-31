import SwiftUI

/// Reader view for a published story: hero image, gallery, embedded video, CTA.
struct PostDetailView: View {
    @Environment(\.openURL) private var openURL
    let post: Post

    /// Signed-in account; enables the bookmark control when present.
    var user: AppUser? = nil

    @State private var galleryIndex = 0

    private var galleryItems: [GalleryItem] {
        var items: [GalleryItem] = post.imageURLs.map { .remote($0) }
        items.append(contentsOf: post.photoData.map { .local($0) })
        return items
    }

    enum GalleryItem: Identifiable {
        case remote(String)
        case local(Data)

        var id: String {
            switch self {
            case .remote(let urlString): return "url-\(urlString)"
            case .local(let data): return "data-\(data.hashValue)"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !galleryItems.isEmpty {
                    gallery
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let category = post.category {
                        Text(category.name)
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .kerning(1)
                            .foregroundStyle(.benchGold)
                    }

                    Text(post.displayTitle)
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.benchNavy)

                    HStack(spacing: 6) {
                        if !post.authorName.isEmpty {
                            Text("By \(post.authorName)")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.benchNavy)
                        }
                        Text("·")
                            .foregroundStyle(.benchSlate)
                        Text(post.publishDate, format: .dateTime.month(.wide).day().year())
                            .font(.footnote)
                            .foregroundStyle(.benchSlate)
                    }

                    if !post.summary.isEmpty {
                        Text(post.summary)
                            .font(.title3.weight(.medium))
                            .fontDesign(.serif)
                            .foregroundStyle(.benchSlate)
                            .padding(.vertical, 4)
                    }

                    Rectangle()
                        .fill(Color.benchGold)
                        .frame(width: 56, height: 3)

                    if !post.videoURL.isEmpty {
                        VideoEmbedView(urlString: post.videoURL)
                            .padding(.vertical, 4)
                    }

                    Text(post.bodyText)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(Color.benchNavy.opacity(0.92))

                    if !post.ctaText.isEmpty {
                        ctaButton
                            .padding(.top, 8)
                    }

                    permalink
                        .padding(.top, 12)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .background(Color.benchPaper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BenchmarkLogoMark(height: 18)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let user {
                    BookmarkButton(post: post, username: user.username, style: .toolbar)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: URL(string: post.publicURL) ?? URL(fileURLWithPath: "/")) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var gallery: some View {
        VStack(spacing: 8) {
            TabView(selection: $galleryIndex) {
                ForEach(Array(galleryItems.enumerated()), id: \.element.id) { index, item in
                    Group {
                        switch item {
                        case .remote(let urlString):
                            RemoteImageView(urlString: urlString, height: 250, cornerRadius: 0)
                        case .local(let data):
                            DataImageView(data: data, height: 250, cornerRadius: 0)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 250)

            if galleryItems.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<galleryItems.count, id: \.self) { index in
                        Capsule()
                            .fill(index == galleryIndex ? Color.benchNavy : Color.benchNavy.opacity(0.2))
                            .frame(width: index == galleryIndex ? 18 : 6, height: 6)
                            .animation(.snappy, value: galleryIndex)
                    }
                }
            }
        }
    }

    private var ctaButton: some View {
        Button {
            if let url = URL(string: post.ctaURL), !post.ctaURL.isEmpty {
                openURL(url)
            }
        } label: {
            HStack {
                Text(post.ctaText)
                    .font(.headline)
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.benchNavy, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var permalink: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Permalink")
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(.benchSlate)
            Text(post.publicURL)
                .font(.caption.monospaced())
                .foregroundStyle(.benchSteel)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.benchNavy.opacity(0.05), in: .rect(cornerRadius: 10))
    }
}
