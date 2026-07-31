import Foundation
import SwiftData

/// A site navigation category. Admins can add, edit, hide, reorder and delete.
@Model
final class PostCategory {
    @Attribute(.unique) var name: String
    var slug: String
    var details: String
    var sortOrder: Int
    var isHidden: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Post.category)
    var posts: [Post] = []

    init(name: String, details: String = "", sortOrder: Int, isHidden: Bool = false) {
        self.name = name
        self.slug = PostCategory.slugify(name)
        self.details = details
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.createdAt = .now
    }

    static func slugify(_ text: String) -> String {
        let lowered = text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let allowed = CharacterSet.lowercaseLetters.union(.decimalDigits)
        var result = ""
        var lastWasDash = false
        for scalar in lowered.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash && !result.isEmpty {
                result.append("-")
                lastWasDash = true
            }
        }
        while result.hasSuffix("-") { result.removeLast() }
        return result
    }
}
