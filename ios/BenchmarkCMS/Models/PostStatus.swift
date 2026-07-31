import SwiftUI

/// Editorial workflow states: Draft → Submitted → Approved → Published.
enum PostStatus: String, CaseIterable, Identifiable {
    case draft
    case submitted
    case changesRequested
    case rejected
    case approved
    case published
    case archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .changesRequested: return "Changes Requested"
        case .rejected: return "Rejected"
        case .approved: return "Approved"
        case .published: return "Published"
        case .archived: return "Unpublished"
        }
    }

    var icon: String {
        switch self {
        case .draft: return "pencil.line"
        case .submitted: return "paperplane.fill"
        case .changesRequested: return "arrow.uturn.backward.circle.fill"
        case .rejected: return "xmark.octagon.fill"
        case .approved: return "checkmark.seal.fill"
        case .published: return "dot.radiowaves.left.and.right"
        case .archived: return "archivebox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .draft: return .benchSlate
        case .submitted: return .benchSteel
        case .changesRequested: return .orange
        case .rejected: return .red
        case .approved: return .benchGold
        case .published: return .benchBlue
        case .archived: return .gray
        }
    }

    /// States a contributor is allowed to edit.
    var isEditableByContributor: Bool {
        switch self {
        case .draft, .changesRequested, .rejected: return true
        default: return false
        }
    }
}
