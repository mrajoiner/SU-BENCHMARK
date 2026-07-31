import SwiftUI
import SwiftData

/// New-account registration: pick a name and an account type.
/// Each role card displays exactly what that account can do,
/// and the app opens the matching workspace right after signing up.
struct RegisterView: View {
    @Environment(SessionManager.self) private var session
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [AppUser]

    @State private var fullName = ""
    @State private var title = ""
    @State private var selectedRole: UserRole = .contributor
    @State private var errorMessage: String?

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespaces)
    }

    private var canCreate: Bool {
        trimmedName.split(separator: " ").count >= 1 && !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Join the Benchmark")
                            .font(.title2.weight(.bold))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.benchNavy)
                        Text("Tell us who you are and choose your account type.")
                            .font(.subheadline)
                            .foregroundStyle(.benchSlate)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("Full Name")
                        TextField("e.g. Jordan Williams", text: $fullName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color.benchCard, in: .rect(cornerRadius: 14))

                        fieldLabel("Title (optional)")
                        TextField("e.g. Staff Writer, CSE ‘27", text: $title)
                            .padding(14)
                            .background(Color.benchCard, in: .rect(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("Account Type")
                        ForEach(UserRole.allCases) { role in
                            roleCard(role)
                        }
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Button {
                        createAccount()
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                canCreate ? Color.benchNavy : Color.benchNavy.opacity(0.35),
                                in: .rect(cornerRadius: 16)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreate)

                    Text("Admin accounts manage the entire site. In production, admin access is granted by an existing admin.")
                        .font(.caption2)
                        .foregroundStyle(.benchSlate)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.benchPaper)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(.benchNavy)
                }
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .kerning(0.8)
            .foregroundStyle(.benchSlate)
    }

    private func roleCard(_ role: UserRole) -> some View {
        let isSelected = selectedRole == role
        return Button {
            withAnimation(.snappy) { selectedRole = role }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(role.tint.opacity(0.15))
                        Image(systemName: role.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(role.tint)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.displayLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.benchNavy)
                        Text(role.summary)
                            .font(.caption)
                            .foregroundStyle(.benchSlate)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? role.tint : Color.benchSlate.opacity(0.35))
                }

                if isSelected {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(role.permissions, id: \.label) { perm in
                            permissionRow(perm.label, granted: perm.granted)
                        }
                    }
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(Color.benchCard)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? role.tint.opacity(0.6) : Color.benchNavy.opacity(0.08),
                        lineWidth: isSelected ? 1.8 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func permissionRow(_ text: String, granted: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundStyle(granted ? Color.benchSteel : Color.benchSlate.opacity(0.5))
            Text(text)
                .font(.caption)
                .foregroundStyle(granted ? Color.benchNavy : .benchSlate.opacity(0.7))
        }
    }

    private func createAccount() {
        guard canCreate else { return }

        let username = generateUsername(from: trimmedName)
        guard !users.contains(where: { $0.username == username }) else {
            errorMessage = "An account with a similar name already exists. Try adding a middle initial."
            return
        }

        let user = AppUser(
            username: username,
            fullName: trimmedName,
            title: title.trimmingCharacters(in: .whitespaces).isEmpty
                ? selectedRole.displayLabel
                : title.trimmingCharacters(in: .whitespaces),
            role: selectedRole
        )
        context.insert(user)

        do {
            try context.save()
            session.pendingOnboardingRole = selectedRole
            session.signIn(user: user)
            dismiss()
        } catch {
            errorMessage = "Could not create the account. Please try again."
        }
    }

    /// Builds a unique handle like "jwilliams" from a full name.
    private func generateUsername(from name: String) -> String {
        let parts = name.lowercased().split(separator: " ")
        let base: String
        if parts.count > 1, let first = parts.first, let last = parts.last {
            base = String(first.prefix(1)) + last
        } else {
            base = parts.first.map(String.init) ?? "user"
        }
        return base.filter { $0.isLetter || $0.isNumber }
    }
}
