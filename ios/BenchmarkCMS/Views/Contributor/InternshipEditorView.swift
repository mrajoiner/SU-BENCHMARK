import SwiftUI
import SwiftData

/// Form for creating or editing an internship listing.
/// Autosaves like the post editor — every keystroke persists.
struct InternshipEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var internship: Internship
    let user: AppUser

    @State private var lastSaved: Date?
    @State private var showDeleteConfirm = false

    private var isNew: Bool { internship.title.isEmpty }

    var body: some View {
        Form {
            opportunitySection
            companySection
            categorySection
            imageSection
            applicationSection
            publishingSection
            deleteSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
        .navigationTitle(isNew ? "New Internship" : "Edit Internship")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                autosaveChip
            }
        }
        .confirmationDialog(
            "Delete this internship?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(internship)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var opportunitySection: some View {
        Section("Opportunity") {
            TextField("Title", text: $internship.title, axis: .vertical)
                .font(.headline)
                .onChange(of: internship.title) { _, _ in markSaved() }

            TextField("Summary — one or two sentences", text: $internship.summary, axis: .vertical)
                .lineLimit(2...4)
                .onChange(of: internship.summary) { _, _ in markSaved() }

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $internship.bodyText)
                    .frame(minHeight: 140)
                    .font(.body)
                    .onChange(of: internship.bodyText) { _, _ in markSaved() }
            }
        }
    }

    private var companySection: some View {
        Section("Company & Location") {
            TextField("Company name", text: $internship.company)
                .onChange(of: internship.company) { _, _ in markSaved() }

            TextField("Location (city, state)", text: $internship.location)
                .onChange(of: internship.location) { _, _ in markSaved() }

            Toggle("Remote eligible", isOn: $internship.isRemote)
                .onChange(of: internship.isRemote) { _, _ in markSaved() }

            Toggle("Paid position", isOn: $internship.isPaid)
                .onChange(of: internship.isPaid) { _, _ in markSaved() }
        }
    }

    private var categorySection: some View {
        Section("Field") {
            Picker("Category", selection: $internship.category) {
                ForEach(InternshipCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat.rawValue)
                }
            }
            .onChange(of: internship.category) { _, _ in markSaved() }
        }
    }

    private var imageSection: some View {
        Section("Image") {
            TextField("Image URL (optional)", text: $internship.imageURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: internship.imageURL) { _, _ in markSaved() }

            if !internship.imageURL.isEmpty {
                RemoteImageView(urlString: internship.imageURL, height: 120, cornerRadius: 12)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var applicationSection: some View {
        Section("Application") {
            TextField("Application URL or email", text: $internship.applicationURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: internship.applicationURL) { _, _ in markSaved() }

            DatePicker("Application deadline", selection: $internship.deadline)
                .onChange(of: internship.deadline) { _, _ in markSaved() }
        }
    }

    private var publishingSection: some View {
        Section("Publishing") {
            Toggle("Published — visible to students", isOn: $internship.isPublished)
                .onChange(of: internship.isPublished) { _, _ in
                    if internship.isPublished { internship.postedAt = .now }
                    markSaved()
                }

            if internship.isPublished {
                LabeledContent("Status") {
                    Text(internship.statusBadge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(internship.isExpired ? Color.gray : Color.green)
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Internship", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var autosaveChip: some View {
        let savedColor = Color(red: 0.18, green: 0.55, blue: 0.34)
        return HStack(spacing: 4) {
            Image(systemName: "checkmark.icloud.fill")
                .font(.system(size: 10))
            Text(lastSaved == nil ? "Autosave on" : "Saved")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(savedColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(savedColor.opacity(0.12), in: .capsule)
        .animation(.easeInOut(duration: 0.2), value: lastSaved)
    }

    private func markSaved() {
        internship.updatedAt = .now
        lastSaved = .now
        try? context.save()
    }
}

/// Discipline categories for internships.
enum InternshipCategory: String, CaseIterable {
    case softwareEngineering = "Software Engineering"
    case dataScience = "Data Science"
    case electricalEngineering = "Electrical Engineering"
    case mechanicalEngineering = "Mechanical Engineering"
    case cybersecurity = "Cybersecurity"
    case research = "Research"
    case civilEngineering = "Civil Engineering"
    case other = "Other"
}
