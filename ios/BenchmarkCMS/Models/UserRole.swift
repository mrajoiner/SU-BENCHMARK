import SwiftUI

/// Access roles for the Benchmark CMS with granular permissions.
///
/// - **Contributor**: Create drafts and submit for approval.
/// - **Approver**: Review submitted content, approve or reject, add feedback.
///   Also carries full contributor capabilities.
/// - **Publisher**: Access approved content and publish it. Also carries
///   full contributor capabilities.
/// - **Admin**: Full access — content, users, categories, settings, approvals,
///   publishing, and the ability to override any permission.
enum UserRole: String, CaseIterable, Identifiable {
    case contributor
    case approver
    case publisher
    case admin

    var id: String { rawValue }

    var label: String {
        switch self {
        case .contributor: return "Contributor"
        case .approver: return "Approver"
        case .publisher: return "Publisher"
        case .admin: return "Administrator"
        }
    }

    var summary: String {
        switch self {
        case .contributor: return "Create drafts and submit for approval"
        case .approver: return "Review, approve or reject submitted content"
        case .publisher: return "Publish approved content and manage publishing"
        case .admin: return "Full access to all content, users, and settings"
        }
    }

    var displayLabel: String {
        switch self {
        case .contributor: return "Contributor"
        case .approver: return "Approver · Contributor"
        case .publisher: return "Publisher · Contributor"
        case .admin: return "Administrator"
        }
    }

    var icon: String {
        switch self {
        case .contributor: return "square.and.pencil"
        case .approver: return "checkmark.seal.fill"
        case .publisher: return "dot.radiowaves.left.and.right"
        case .admin: return "crown.fill"
        }
    }

    var tint: Color {
        switch self {
        case .contributor: return .benchBlue
        case .approver: return .benchYellow
        case .publisher: return .benchLightBlue
        case .admin: return .benchNavy
        }
    }

    // MARK: - Granular permissions

    /// Create, edit, and delete own drafts; submit for approval.
    var canContribute: Bool { true }

    /// Review submitted content — see the Review tab and the queue.
    var canReview: Bool { self == .approver || self == .admin }

    /// Approve or reject submitted content, and add feedback notes.
    var canApprove: Bool { self == .approver || self == .admin }

    /// Publish approved content, schedule, unpublish, and republish.
    var canPublish: Bool { self == .publisher || self == .admin }

    /// Manage users, roles, categories, site settings, and all content.
    var canAdminister: Bool { self == .admin }

    /// Override any permission — admin only.
    var canOverride: Bool { self == .admin }

    /// Whether this role can edit a post in a given status.
    func canEdit(postStatus: PostStatus) -> Bool {
        if canAdminister { return true }
        if postStatus.isEditableByContributor { return true }
        if canApprove && postStatus == .submitted { return true }
        if canPublish && (postStatus == .approved || postStatus == .published || postStatus == .archived) { return true }
        return false
    }

    /// One-line permission checklist for role cards and onboarding.
    var permissions: [(label: String, granted: Bool)] {
        [
            ("Create & submit drafts", granted: canContribute),
            ("Review submitted content", granted: canReview),
            ("Approve or reject with feedback", granted: canApprove),
            ("Publish, schedule & unpublish", granted: canPublish),
            ("Manage users, categories & settings", granted: canAdminister),
        ]
    }
}
