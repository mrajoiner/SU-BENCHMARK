import Foundation
import SwiftData

/// A CMS submission that moves through Draft → Submitted → Approved → Published.
@Model
final class Post {
    var title: String
    var slug: String
    var summary: String
    var bodyText: String
    var imageURLs: [String]
    var photoData: [Data]
    var videoURL: String
    var ctaText: String
    var ctaURL: String
    var publishDate: Date
    var expirationDate: Date?
    var notes: String
    var statusRaw: String
    var reviewFeedback: String
    var authorName: String
    var createdAt: Date
    var updatedAt: Date
    var submittedAt: Date?
    var publishedAt: Date?

    var category: PostCategory?

    @Relationship(deleteRule: .nullify)
    var author: AppUser?

    init(
        title: String = "",
        summary: String = "",
        bodyText: String = "",
        imageURLs: [String] = [],
        videoURL: String = "",
        ctaText: String = "",
        ctaURL: String = "",
        publishDate: Date = .now,
        expirationDate: Date? = nil,
        notes: String = "",
        status: PostStatus = .draft,
        author: AppUser? = nil,
        category: PostCategory? = nil
    ) {
        self.title = title
        self.slug = PostCategory.slugify(title)
        self.summary = summary
        self.bodyText = bodyText
        self.imageURLs = imageURLs
        self.photoData = []
        self.videoURL = videoURL
        self.ctaText = ctaText
        self.ctaURL = ctaURL
        self.publishDate = publishDate
        self.expirationDate = expirationDate
        self.notes = notes
        self.statusRaw = status.rawValue
        self.reviewFeedback = ""
        self.authorName = author?.fullName ?? ""
        self.createdAt = .now
        self.updatedAt = .now
        self.submittedAt = nil
        self.publishedAt = nil
        self.author = author
        self.category = category
    }

    var status: PostStatus {
        get { PostStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate <= .now
    }

    /// Scheduled = published with a future go-live date.
    var isScheduled: Bool {
        status == .published && publishDate > .now
    }

    /// Live = published, past the publish date, and not expired.
    /// Note: `.approved` is NOT live — it means an approver has approved the
    /// content and it's waiting for a publisher to publish it.
    var isLive: Bool {
        status == .published && publishDate <= .now && !isExpired
    }

    /// User-facing status that folds in scheduling and expiration.
    var displayLabel: String {
        if isScheduled { return "Scheduled" }
        if status == .published && isExpired { return "Expired" }
        return status.label
    }

    /// SEO-friendly public path, e.g. /cse-news/robotics-team-wins
    var publicPath: String {
        let categorySlug = category?.slug ?? "news"
        let postSlug = slug.isEmpty ? "untitled" : slug
        return "/\(categorySlug)/\(postSlug)"
    }

    var publicURL: String { "https://subenchmark.blooksy.com\(publicPath)" }

    var displayTitle: String { title.isEmpty ? "Untitled Draft" : title }

    /// Estimated minutes to read the story at ~200 words per minute,
    /// with a small allowance for images and embedded video.
    var readingMinutes: Int {
        let words = bodyText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            + summary.split(whereSeparator: { $0.isWhitespace }).count
        var seconds = Double(words) / 200.0 * 60.0
        seconds += Double(imageURLs.count + photoData.count) * 8.0
        if !videoURL.isEmpty { seconds += 20.0 }
        return max(1, Int((seconds / 60.0).rounded()))
    }

    /// User-facing label, e.g. "3 min read".
    var readingTimeLabel: String { "\(readingMinutes) min read" }

    var hasMedia: Bool { !imageURLs.isEmpty || !photoData.isEmpty }

    func refreshSlug() {
        slug = PostCategory.slugify(title)
    }

    func touch() {
        updatedAt = .now
    }
}
