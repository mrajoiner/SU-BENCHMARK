import Foundation
import SwiftData

/// A CMS account with a role-based permission set.
@Model
final class AppUser {
    @Attribute(.unique) var username: String
    var fullName: String
    var title: String
    var roleRaw: String
    var isActive: Bool
    var createdAt: Date

    /// Optional contact email (admins set this from the user manager).
    var email: String

    /// Slugs of categories this user is assigned to. Admins can assign
    /// categories to any user; when non-empty, the user's editor picker
    /// is filtered to these categories so contributors stay in scope.
    var assignedCategorySlugs: [String]

    init(
        username: String,
        fullName: String,
        title: String,
        role: UserRole,
        isActive: Bool = true,
        email: String = "",
        assignedCategorySlugs: [String] = []
    ) {
        self.username = username
        self.fullName = fullName
        self.title = title
        self.roleRaw = role.rawValue
        self.isActive = isActive
        self.email = email
        self.assignedCategorySlugs = assignedCategorySlugs
        self.createdAt = .now
    }

    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .contributor }
        set { roleRaw = newValue.rawValue }
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        return String(first + last).uppercased()
    }

    /// Whether the user is restricted to specific categories.
    var hasAssignedCategories: Bool { !assignedCategorySlugs.isEmpty }

    /// Human-readable summary of assigned categories (or "All" if unrestricted).
    func categoryAssignmentLabel(from allCategories: [PostCategory]) -> String {
        guard hasAssignedCategories else { return "All categories" }
        let names = allCategories
            .filter { assignedCategorySlugs.contains($0.slug) }
            .map(\.name)
        return names.isEmpty ? "All categories" : names.joined(separator: ", ")
    }
}
