import SwiftUI
import SwiftData

/// Full-fidelity preview with the complete approval toolkit:
/// approve & publish, schedule, request changes, reject, edit, unpublish.
struct ReviewDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var post: Post
    let user: AppUser

    @State private var showFeedbackSheet = false
    @State private var feedbackMode: FeedbackMode = .requestChanges
    @State private var feedbackText = ""
    @State private var showScheduleSheet = false
    @State private var scheduleDate = Date(timeIntervalSinceNow: 86_400)
    @State private var showApproveDialog = false
    @State private var showUnpublishConfirm = false
    @State private var showPublishConfirm = false

    enum FeedbackMode {
        case requestChanges
        case reject

        var title: String {
            switch self {
            case .requestChanges: return "Request Changes"
            case .reject: return "Reject Submission"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                previewCard

                if !post.notes.isEmpty {
                    contributorNotes
                }

                metadataCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .background(Color.benchPaper)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if user.role.canEdit(postStatus: post.status) {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PostEditorView(post: post, user: user)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .sheet(isPresented: $showFeedbackSheet) {
            feedbackSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showScheduleSheet) {
            scheduleSheet
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Publish this approved post?",
            isPresented: $showPublishConfirm,
            titleVisibility: .visible
        ) {
            Button("Publish Now") { publishNow() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will make the post live on subenchmark.blooksy.com immediately.")
        }
        .confirmationDialog(
            "Unpublish this post?",
            isPresented: $showUnpublishConfirm,
            titleVisibility: .visible
        ) {
            Button("Unpublish", role: .destructive) { unpublish() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from the public site immediately.")
        }
    }

    // MARK: - Preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Site Preview", systemImage: "eye.fill")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundStyle(.benchGold)
                Spacer()
                StatusBadge(post: post)
            }

            if let firstImage = post.imageURLs.first {
                RemoteImageView(urlString: firstImage, height: 190, cornerRadius: 12)
            } else if let firstData = post.photoData.first {
                DataImageView(data: firstData, height: 190, cornerRadius: 12)
            }

            if let category = post.category {
                Text(category.name)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundStyle(.benchGold)
            }

            Text(post.displayTitle)
                .font(.title2.weight(.bold))
                .fontDesign(.serif)
                .foregroundStyle(Color.benchNavy)

            if !post.summary.isEmpty {
                Text(post.summary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.benchSlate)
            }

            if !post.videoURL.isEmpty {
                VideoEmbedView(urlString: post.videoURL)
            }

            Text(post.bodyText)
                .font(.body)
                .foregroundStyle(Color.benchNavy.opacity(0.9))

            if post.imageURLs.count > 1 {
                galleryStrip
            }

            if !post.ctaText.isEmpty {
                Text(post.ctaText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.benchNavy, in: .capsule)
            }
        }
        .padding(16)
        .background(Color.benchCard, in: .rect(cornerRadius: 18))
        .shadow(color: Color.benchNavy.opacity(0.07), radius: 10, y: 4)
        .padding(.top, 8)
    }

    private var galleryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(post.imageURLs.dropFirst().enumerated()), id: \.offset) { _, urlString in
                    RemoteImageView(urlString: urlString, height: 90, cornerRadius: 10)
                        .frame(width: 130)
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private var contributorNotes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Notes from \(post.authorName.isEmpty ? "contributor" : post.authorName)", systemImage: "text.bubble.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.benchSteel)
            Text(post.notes)
                .font(.subheadline)
                .foregroundStyle(Color.benchNavy.opacity(0.85))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.benchSteel.opacity(0.1), in: .rect(cornerRadius: 14))
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            metaRow(label: "Author", value: post.authorName.isEmpty ? "—" : post.authorName)
            metaRow(label: "Publish date", value: post.publishDate.formatted(date: .abbreviated, time: .shortened))
            if let expiration = post.expirationDate {
                metaRow(label: "Expires", value: expiration.formatted(date: .abbreviated, time: .shortened))
            }
            metaRow(label: "Public URL", value: post.publicURL)
            metaRow(label: "Last updated", value: post.updatedAt.formatted(.relative(presentation: .named)))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.benchCard, in: .rect(cornerRadius: 16))
        .shadow(color: Color.benchNavy.opacity(0.05), radius: 6, y: 3)
    }

    private func metaRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(.benchSlate)
            Text(value)
                .font(.footnote)
                .foregroundStyle(Color.benchNavy)
        }
    }

    // MARK: - Actions

    private var actionBar: some View {
        VStack(spacing: 10) {
            // APPROVER actions: approve, request changes, reject (submitted posts)
            if post.status == .submitted && user.role.canApprove {
                Button {
                    approveOnly()
                } label: {
                    Label("Approve", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.benchGold)

                HStack(spacing: 10) {
                    Button {
                        feedbackMode = .requestChanges
                        feedbackText = ""
                        showFeedbackSheet = true
                    } label: {
                        Label("Request Changes", systemImage: "arrow.uturn.backward")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Button {
                        feedbackMode = .reject
                        feedbackText = ""
                        showFeedbackSheet = true
                    } label: {
                        Label("Reject", systemImage: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }

            // PUBLISHER actions: publish approved content, schedule, unpublish
            if post.status == .approved && user.role.canPublish {
                Button {
                    showPublishConfirm = true
                } label: {
                    Label("Publish Now", systemImage: "dot.radiowaves.left.and.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.benchNavy)

                Button {
                    scheduleDate = max(post.publishDate, Date(timeIntervalSinceNow: 3_600))
                    showScheduleSheet = true
                } label: {
                    Label("Schedule Publish…", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // PUBLISHER/ADMIN: unpublish live or scheduled content
            if (post.isLive || post.isScheduled) && user.role.canPublish {
                Button(role: .destructive) {
                    showUnpublishConfirm = true
                } label: {
                    Label("Unpublish", systemImage: "archivebox")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // PUBLISHER/ADMIN: republish archived content
            if post.status == .archived && user.role.canPublish {
                Button {
                    publishNow()
                } label: {
                    Label("Republish", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.benchNavy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var feedbackSheet: some View {
        NavigationStack {
            Form {
                Section(feedbackMode == .requestChanges ? "What should the contributor fix?" : "Why is this rejected?") {
                    TextField("Feedback for the contributor", text: $feedbackText, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(feedbackMode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showFeedbackSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { sendFeedback() }
                        .disabled(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var scheduleSheet: some View {
        NavigationStack {
            Form {
                Section("Go-live date") {
                    DatePicker("Publish on", selection: $scheduleDate, in: Date.now...)
                        .datePickerStyle(.graphical)
                }
                Section {
                    Text("The post is approved now and will appear on the site automatically at the scheduled time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Schedule Publish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showScheduleSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") { schedulePublish() }
                }
            }
        }
    }

    /// Approver approves a submitted post — sets status to `.approved`,
    /// waiting for a publisher to publish it.
    private func approveOnly() {
        post.status = .approved
        post.reviewFeedback = ""
        post.touch()
        try? context.save()
        dismiss()
    }

    /// Publisher publishes an approved post immediately.
    private func publishNow() {
        post.status = .published
        post.publishDate = min(post.publishDate, .now)
        post.publishedAt = .now
        post.touch()
        try? context.save()
        dismiss()
    }

    /// Publisher schedules a publish for a future date.
    private func schedulePublish() {
        post.status = .published
        post.publishDate = scheduleDate
        post.reviewFeedback = ""
        post.touch()
        try? context.save()
        showScheduleSheet = false
        dismiss()
    }

    private func sendFeedback() {
        post.reviewFeedback = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        post.status = feedbackMode == .requestChanges ? .changesRequested : .rejected
        post.touch()
        try? context.save()
        showFeedbackSheet = false
        dismiss()
    }

    private func unpublish() {
        post.status = .archived
        post.touch()
        try? context.save()
        dismiss()
    }
}
