import SwiftUI
import SwiftData

/// Admin: add, edit, deactivate, and delete CMS accounts.
/// Includes category assignment so admins can scope each user's workflow.
struct UserManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AppUser.createdAt) private var users: [AppUser]

    @State private var editingUser: AppUser?
    @State private var showNewUser = false

    var body: some View {
        List {
            ForEach(UserRole.allCases) { role in
                let roleUsers = users.filter { $0.role == role }
                if !roleUsers.isEmpty {
                    Section(role.label + "s") {
                        ForEach(roleUsers) { user in
                            Button {
                                editingUser = user
                            } label: {
                                userRow(user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Users")
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewUser = true
                } label: {
                    Label("Add User", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(item: $editingUser) { user in
            UserEditorSheet(user: user)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showNewUser) {
            UserEditorSheet(user: nil)
                .presentationDetents([.medium, .large])
        }
    }

    private func userRow(_ user: AppUser) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(user.role.tint.opacity(0.14))
                Text(user.initials)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(user.role.tint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(user.isActive ? Color.benchNavy : .secondary)
                Text("@\(user.username) · \(user.title)")
                    .font(.caption)
                    .foregroundStyle(.benchSlate)
                    .lineLimit(1)
                if !user.email.isEmpty {
                    Text(user.email)
                        .font(.caption2)
                        .foregroundStyle(.benchSteel)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !user.isActive {
                Text("Inactive")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.15), in: .capsule)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Create or edit a user account, including category assignment.
private struct UserEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PostCategory.sortOrder) private var allCategories: [PostCategory]

    let user: AppUser?

    @State private var fullName = ""
    @State private var username = ""
    @State private var title = ""
    @State private var email = ""
    @State private var role: UserRole = .contributor
    @State private var isActive = true
    @State private var showDeleteConfirm = false

    // Category assignment
    @State private var restrictCategories = false
    @State private var selectedCategorySlugs: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Full name", text: $fullName)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Title / department", text: $title)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases) { option in
                            Label(option.label, systemImage: option.icon).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    Text(role.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Active account", isOn: $isActive)
                }

                // Category assignment — admins can scope a user's workflow
                Section {
                    Toggle("Restrict to specific categories", isOn: $restrictCategories)
                        .onChange(of: restrictCategories) { _, isOn in
                            if !isOn { selectedCategorySlugs.removeAll() }
                        }

                    if restrictCategories {
                        Text("Selected categories determine which sections this user can create and edit content in.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(allCategories) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                if selectedCategorySlugs.contains(category.slug) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.benchNavy)
                                }
                            }
                            .contentShape(.rect)
                            .onTapGesture {
                                if selectedCategorySlugs.contains(category.slug) {
                                    selectedCategorySlugs.remove(category.slug)
                                } else {
                                    selectedCategorySlugs.insert(category.slug)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Category Assignment")
                } footer: {
                    Text("When restricted, the user's editor only shows assigned categories. Unrestricted users see all categories.")
                }

                if user != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete User", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(user == nil ? "New User" : "Edit User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty
                            || username.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let user {
                    fullName = user.fullName
                    username = user.username
                    title = user.title
                    email = user.email
                    role = user.role
                    isActive = user.isActive
                    selectedCategorySlugs = Set(user.assignedCategorySlugs)
                    restrictCategories = !user.assignedCategorySlugs.isEmpty
                }
            }
            .confirmationDialog("Delete this user?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let user {
                        context.delete(user)
                        try? context.save()
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Their posts remain, but the byline is preserved as plain text.")
            }
        }
    }

    private func save() {
        let cleanUsername = username.trimmingCharacters(in: .whitespaces).lowercased()
        let slugs = restrictCategories ? Array(selectedCategorySlugs) : []
        if let user {
            user.fullName = fullName.trimmingCharacters(in: .whitespaces)
            user.username = cleanUsername
            user.title = title.trimmingCharacters(in: .whitespaces)
            user.email = email.trimmingCharacters(in: .whitespaces)
            user.role = role
            user.isActive = isActive
            user.assignedCategorySlugs = slugs
        } else {
            let newUser = AppUser(
                username: cleanUsername,
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                title: title.trimmingCharacters(in: .whitespaces),
                role: role,
                isActive: isActive,
                email: email.trimmingCharacters(in: .whitespaces),
                assignedCategorySlugs: slugs
            )
            context.insert(newUser)
        }
        try? context.save()
        dismiss()
    }
}
