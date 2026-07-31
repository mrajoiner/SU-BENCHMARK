import SwiftUI
import SwiftData
import PhotosUI

/// Full submission editor with autosave. Bound directly to the SwiftData model,
/// so every keystroke persists; the autosave chip confirms it.
struct PostEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var post: Post
    let user: AppUser

    @Query(sort: \PostCategory.sortOrder) private var categories: [PostCategory]

    @State private var lastSaved: Date?
    @State private var newImageURL: String = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var hasExpiration: Bool = false
    @State private var showSubmitConfirm = false
    @State private var showDeleteConfirm = false

    /// Categories visible to this user — filtered by admin-assigned categories
    /// when the user has a restriction in place.
    private var availableCategories: [PostCategory] {
        guard user.hasAssignedCategories else { return categories }
        return categories.filter { user.assignedCategorySlugs.contains($0.slug) }
    }

    private var isLocked: Bool {
        !user.role.canEdit(postStatus: post.status)
    }

    var body: some View {
        Form {
            statusSection

            if isLocked {
                Section {
                    Label("This post is \(post.displayLabel.lowercased()) and can no longer be edited by your role.", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.benchSlate)
                }
            }

            Section("Story") {
                TextField("Title", text: $post.title, axis: .vertical)
                    .font(.headline)
                    .onChange(of: post.title) { _, _ in
                        post.refreshSlug()
                        markSaved()
                    }

                TextField("Summary — one or two sentences", text: $post.summary, axis: .vertical)
                    .lineLimit(2...4)
                    .onChange(of: post.summary) { _, _ in markSaved() }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Body")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $post.bodyText)
                        .frame(minHeight: 160)
                        .font(.body)
                        .onChange(of: post.bodyText) { _, _ in markSaved() }
                }
            }

            Section("Category & Author") {
                Picker("Category", selection: $post.category) {
                    Text("None").tag(nil as PostCategory?)
                    ForEach(availableCategories) { category in
                        Text(category.name).tag(category as PostCategory?)
                    }
                }
                .onChange(of: post.category) { _, _ in markSaved() }

                TextField("Author byline", text: $post.authorName)
                    .onChange(of: post.authorName) { _, _ in markSaved() }
            }

            imagesSection

            Section("Video") {
                TextField("YouTube or Vimeo URL", text: $post.videoURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: post.videoURL) { _, _ in markSaved() }
                if !post.videoURL.isEmpty {
                    VideoEmbedView(urlString: post.videoURL)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section("Call to Action") {
                TextField("Button text (e.g. Register Now)", text: $post.ctaText)
                    .onChange(of: post.ctaText) { _, _ in markSaved() }
                TextField("Button URL", text: $post.ctaURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: post.ctaURL) { _, _ in markSaved() }
            }

            Section("Scheduling") {
                DatePicker("Publish date", selection: $post.publishDate)
                    .onChange(of: post.publishDate) { _, _ in markSaved() }

                Toggle("Expires", isOn: $hasExpiration)
                    .onChange(of: hasExpiration) { _, isOn in
                        post.expirationDate = isOn
                            ? (post.expirationDate ?? Date(timeIntervalSinceNow: 30 * 86_400))
                            : nil
                        markSaved()
                    }

                if hasExpiration {
                    DatePicker(
                        "Expiration date",
                        selection: Binding(
                            get: { post.expirationDate ?? Date(timeIntervalSinceNow: 30 * 86_400) },
                            set: { post.expirationDate = $0; markSaved() }
                        )
                    )
                }
            }

            Section("Notes for Reviewer") {
                TextField("Anything the approver should know", text: $post.notes, axis: .vertical)
                    .lineLimit(2...5)
                    .onChange(of: post.notes) { _, _ in markSaved() }
            }

            if !post.reviewFeedback.isEmpty {
                Section("Reviewer Feedback") {
                    Label(post.reviewFeedback, systemImage: "text.bubble.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            Section("SEO") {
                LabeledContent("URL slug") {
                    Text(post.slug.isEmpty ? "—" : post.slug)
                        .font(.caption.monospaced())
                        .foregroundStyle(.benchSlate)
                }
                LabeledContent("Public URL") {
                    Text(post.publicPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.benchSteel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            actionSection
        }
        .disabled(isLocked)
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
        .navigationTitle(post.status == .draft ? "Draft" : "Edit Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                autosaveChip
            }
        }
        .onAppear {
            hasExpiration = post.expirationDate != nil
        }
        .confirmationDialog(
            "Submit for approval?",
            isPresented: $showSubmitConfirm,
            titleVisibility: .visible
        ) {
            Button("Submit") { submit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("An approver will review your post before it goes live on subenchmark.blooksy.com.")
        }
        .confirmationDialog(
            "Delete this post?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(post)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var statusSection: some View {
        Section {
            HStack {
                StatusBadge(post: post)
                Spacer()
                if let submittedAt = post.submittedAt, post.status == .submitted {
                    Text("Submitted \(submittedAt, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(.benchSlate)
                }
            }
        }
    }

    private var imagesSection: some View {
        Section("Images") {
            ForEach(Array(post.imageURLs.enumerated()), id: \.offset) { index, urlString in
                VStack(alignment: .leading, spacing: 8) {
                    RemoteImageView(urlString: urlString, height: 140, cornerRadius: 12)
                    if !isLocked {
                        Button(role: .destructive) {
                            post.imageURLs.remove(at: index)
                            markSaved()
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            ForEach(Array(post.photoData.enumerated()), id: \.offset) { index, data in
                VStack(alignment: .leading, spacing: 8) {
                    DataImageView(data: data, height: 140, cornerRadius: 12)
                    if !isLocked {
                        Button(role: .destructive) {
                            post.photoData.remove(at: index)
                            markSaved()
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                TextField("Paste image URL", text: $newImageURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    let trimmed = newImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    post.imageURLs.append(trimmed)
                    newImageURL = ""
                    markSaved()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.benchNavy)
                }
                .disabled(newImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            PhotosPicker(selection: $pickerItems, maxSelectionCount: 4, matching: .images) {
                Label("Add from Photo Library", systemImage: "photo.badge.plus")
                    .font(.subheadline)
            }
            .onChange(of: pickerItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let compressed = compressImage(data) {
                            post.photoData.append(compressed)
                        }
                    }
                    pickerItems = []
                    markSaved()
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            if post.status.isEditableByContributor {
                Button {
                    showSubmitConfirm = true
                } label: {
                    Label(
                        post.status == .draft ? "Submit for Approval" : "Resubmit for Approval",
                        systemImage: "paperplane.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.benchNavy)
                .disabled(post.title.trimmingCharacters(in: .whitespaces).isEmpty)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if post.status == .draft || user.role.canAdminister || user.role.canPublish {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Post", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var autosaveChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.icloud.fill")
                .font(.system(size: 10))
            Text(lastSaved == nil ? "Autosave on" : "Saved")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(PostStatus.published.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(PostStatus.published.tint.opacity(0.12), in: .capsule)
        .animation(.easeInOut(duration: 0.2), value: lastSaved)
    }

    private func markSaved() {
        post.touch()
        lastSaved = .now
        try? context.save()
    }

    private func submit() {
        post.status = .submitted
        post.submittedAt = .now
        post.reviewFeedback = ""
        post.refreshSlug()
        markSaved()
        dismiss()
    }

    /// Downscales library photos so SwiftData stays lean.
    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 1400
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }
}
