import Foundation
import SwiftData

/// Singleton site configuration managed by admins.
@Model
final class SiteSettings {
    var siteTitle: String
    var tagline: String
    var siteURL: String
    var contactEmail: String
    var footerText: String
    var showSearch: Bool
    var showFeaturedPost: Bool
    var updatedAt: Date

    init(
        siteTitle: String = "Benchmark",
        tagline: String = "Showcasing Southern University's excellence to the world.",
        siteURL: String = "https://subenchmark.blooksy.com",
        contactEmail: String = "benchmark@sus.edu",
        footerText: String = "© Southern University and A&M College",
        showSearch: Bool = true,
        showFeaturedPost: Bool = true
    ) {
        self.siteTitle = siteTitle
        self.tagline = tagline
        self.siteURL = siteURL
        self.contactEmail = contactEmail
        self.footerText = footerText
        self.showSearch = showSearch
        self.showFeaturedPost = showFeaturedPost
        self.updatedAt = .now
    }
}
