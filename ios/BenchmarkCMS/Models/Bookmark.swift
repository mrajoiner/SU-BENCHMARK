import Foundation
import SwiftData

/// A story an authenticated user saved for later reading.
@Model
final class Bookmark {
    var username: String
    var savedAt: Date

    @Relationship(deleteRule: .nullify)
    var post: Post?

    init(username: String, post: Post) {
        self.username = username
        self.savedAt = .now
        self.post = post
    }
}
