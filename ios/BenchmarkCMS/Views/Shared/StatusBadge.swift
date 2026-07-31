import SwiftUI

/// Small capsule showing a post's workflow state (folding in Scheduled/Expired).
struct StatusBadge: View {
    let post: Post

    private var tint: Color {
        if post.isScheduled { return .benchSteel }
        if post.status == .published && post.isExpired { return .gray }
        return post.status.tint
    }

    private var icon: String {
        if post.isScheduled { return "clock.fill" }
        return post.status.icon
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(post.displayLabel)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .kerning(0.5)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: .capsule)
    }
}
