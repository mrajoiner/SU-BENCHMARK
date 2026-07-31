import SwiftUI
import SwiftData

/// Approver home: pending submissions plus everything scheduled or live.
struct ReviewQueueView: View {
    @Query(sort: \Post.updatedAt, order: .reverse) private var allPosts: [Post]

    let user: AppUser

    @State private var segment: Segment = .queue

    enum Segment: String, CaseIterable, Identifiable {
        case queue = "Queue"
        case approved = "Approved"
        case scheduled = "Scheduled"
        case live = "Live"
        case resolved = "Resolved"

        var id: String { rawValue }
    }

    private var queue: [Post] {
        allPosts.filter { $0.status == .submitted }
            .sorted { ($0.submittedAt ?? $0.updatedAt) < ($1.submittedAt ?? $1.updatedAt) }
    }

    private var approved: [Post] { allPosts.filter { $0.status == .approved && !$0.isScheduled } }

    private var scheduled: [Post] { allPosts.filter { $0.isScheduled } }

    private var live: [Post] { allPosts.filter { $0.isLive } }

    private var resolved: [Post] {
        allPosts.filter {
            $0.status == .rejected || $0.status == .changesRequested || $0.status == .archived
        }
    }

    private var currentList: [Post] {
        switch segment {
        case .queue: return queue
        case .approved: return approved
        case .scheduled: return scheduled
        case .live: return live
        case .resolved: return resolved
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !queue.isEmpty && segment != .queue {
                    pendingBanner
                }

                if !approved.isEmpty && segment != .approved {
                    approvedBanner
                }

                Picker("Segment", selection: $segment) {
                    ForEach(Segment.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)

                if currentList.isEmpty {
                    emptyState
                } else {
                    ForEach(currentList) { post in
                        NavigationLink(value: post) {
                            reviewRow(post)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.benchPaper)
        .navigationTitle("Review")
        .benchmarkBranded()
        .navigationDestination(for: Post.self) { post in
            ReviewDetailView(post: post, user: user)
        }
    }

    private var pendingBanner: some View {
        Button {
            segment = .queue
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.benchGold)
                Text("\(queue.count) submission\(queue.count == 1 ? "" : "s") awaiting review")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .background(LinearGradient.benchHeader, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private var approvedBanner: some View {
        Button {
            withAnimation(.snappy) { segment = .approved }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.benchGold)
                Text("\(approved.count) approved \(approved.count == 1 ? "post" : "posts") ready for publishing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .background(Color.benchGold.opacity(0.8), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private func reviewRow(_ post: Post) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let firstImage = post.imageURLs.first {
                RemoteImageView(urlString: firstImage, height: 64, cornerRadius: 10)
                    .frame(width: 64)
            } else if let firstData = post.photoData.first {
                DataImageView(data: firstData, height: 64, cornerRadius: 10)
                    .frame(width: 64)
            } else {
                Color.benchNavy.opacity(0.08)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.benchSlate)
                    }
                    .clipShape(.rect(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(post.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.benchNavy)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    StatusBadge(post: post)
                    if let category = post.category {
                        Text(category.name)
                            .font(.caption2)
                            .foregroundStyle(.benchSlate)
                    }
                }

                HStack(spacing: 4) {
                    Text("By \(post.authorName.isEmpty ? "Unknown" : post.authorName)")
                    if post.isScheduled {
                        Text("· goes live \(post.publishDate, format: .relative(presentation: .named))")
                    } else if let submittedAt = post.submittedAt, post.status == .submitted {
                        Text("· submitted \(submittedAt, format: .relative(presentation: .named))")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.benchSlate.opacity(0.8))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.benchCard, in: .rect(cornerRadius: 16))
        .shadow(color: Color.benchNavy.opacity(0.05), radius: 6, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: segment == .queue ? "checkmark.seal" : "tray")
                .font(.system(size: 38))
                .foregroundStyle(.benchSlate.opacity(0.4))
            Text(segment == .queue ? "Queue is clear" : segment == .approved ? "Nothing approved yet" : "Nothing here")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text(segment == .queue ? "New submissions will appear here for review." : segment == .approved ? "Posts you approve will appear here until a publisher publishes them." : "Content in this state will appear here.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
