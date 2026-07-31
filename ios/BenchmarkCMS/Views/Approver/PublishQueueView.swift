import SwiftUI
import SwiftData

/// Publisher workspace: approved content ready to publish, plus live/scheduled
/// content that can be unpublished or rescheduled.
///
/// Publishers can:
/// - Publish approved content immediately or on a schedule.
/// - Unpublish live or scheduled content.
/// - Republish archived content.
///
/// Publishers cannot approve/reject submissions or access admin settings.
struct PublishQueueView: View {
    @Query(sort: \Post.updatedAt, order: .reverse) private var allPosts: [Post]

    let user: AppUser

    @State private var segment: Segment = .ready

    enum Segment: String, CaseIterable, Identifiable {
        case ready = "Ready"
        case scheduled = "Scheduled"
        case live = "Live"
        case archived = "Archived"

        var id: String { rawValue }
    }

    private var ready: [Post] {
        allPosts.filter { $0.status == .approved }
            .sorted { ($0.updatedAt) > ($1.updatedAt) }
    }

    private var scheduled: [Post] { allPosts.filter { $0.isScheduled } }
    private var live: [Post] { allPosts.filter { $0.isLive } }
    private var archived: [Post] { allPosts.filter { $0.status == .archived } }

    private var currentList: [Post] {
        switch segment {
        case .ready: return ready
        case .scheduled: return scheduled
        case .live: return live
        case .archived: return archived
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !ready.isEmpty && segment != .ready {
                    readyBanner
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
                            publishRow(post)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.benchPaper)
        .navigationTitle("Publish")
        .benchmarkBranded()
        .navigationDestination(for: Post.self) { post in
            ReviewDetailView(post: post, user: user)
        }
    }

    private var readyBanner: some View {
        Button {
            withAnimation(.snappy) { segment = .ready }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.benchGold)
                Text("\(ready.count) approved \(ready.count == 1 ? "post" : "posts") ready to publish")
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

    private func publishRow(_ post: Post) -> some View {
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
                    } else if post.status == .approved {
                        Text("· approved \(post.updatedAt, format: .relative(presentation: .named))")
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
            Image(systemName: segment == .ready ? "checkmark.seal" : "tray")
                .font(.system(size: 38))
                .foregroundStyle(.benchSlate.opacity(0.4))
            Text(segment == .ready ? "Nothing ready to publish" : "Nothing here")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text(segment == .ready
                 ? "Approved posts will appear here for publishing."
                 : "Content in this state will appear here.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
