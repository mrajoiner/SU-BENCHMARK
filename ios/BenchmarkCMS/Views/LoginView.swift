import SwiftUI
import SwiftData

/// Role-based sign-in. Tap an account to enter its workspace.
struct LoginView: View {
    @Environment(SessionManager.self) private var session
    @Query(sort: \AppUser.createdAt) private var users: [AppUser]

    @State private var appeared = false
    @State private var isRegistering = false

    private var activeUsers: [AppUser] {
        users.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.benchPaper.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sign in to your workspace")
                            .font(.headline)
                            .foregroundStyle(.benchSlate)
                            .padding(.top, 26)

                        ForEach(Array(activeUsers.enumerated()), id: \.element.username) { index, user in
                            Button {
                                session.signIn(user: user)
                            } label: {
                                accountCard(user: user)
                            }
                            .buttonStyle(.plain)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(
                                .spring(duration: 0.5).delay(0.15 + Double(index) * 0.08),
                                value: appeared
                            )
                        }

                        registerButton
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(.spring(duration: 0.5).delay(0.4), value: appeared)

                        guestButton
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(.spring(duration: 0.5).delay(0.48), value: appeared)

                        Text("Roles are enforced across the app: contributors write, approvers publish, admins manage everything. No account is needed to read the site.")
                            .font(.footnote)
                            .foregroundStyle(.benchSlate)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        session.isShowingLogin = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.benchYellow)
                    }
                }
            }
        }
        .onAppear { appeared = true }
        .sheet(isPresented: $isRegistering) {
            RegisterView()
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image("benchmark_logo_gold")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 44)
                .padding(.top, 28)

            VStack(spacing: 4) {
                Text("Benchmark")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                Text("powered by the College of Sciences and Engineering")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.white.opacity(0.7))
                Text("Content Studio")
                    .font(.subheadline)
                    .foregroundStyle(.benchGold)
                    .textCase(.uppercase)
                    .kerning(2)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient.benchHeader
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.benchBlue.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .offset(x: 80, y: -90)
                        .blur(radius: 2)
                }
                .clipped()
        )
        .clipShape(.rect(bottomLeadingRadius: 28, bottomTrailingRadius: 28))
        .ignoresSafeArea(edges: .top)
    }

    private var registerButton: some View {
        Button {
            isRegistering = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.benchYellow.opacity(0.16))
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title3)
                        .foregroundStyle(.benchYellow)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Create an Account")
                        .font(.headline)
                        .foregroundStyle(Color.benchNavy)
                    Text("Register and choose your account type")
                        .font(.caption)
                        .foregroundStyle(.benchSlate)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.benchYellow.opacity(0.5))
            }
            .padding(16)
            .background(Color.benchCard)
            .clipShape(.rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.benchYellow.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.benchNavy.opacity(0.07), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var guestButton: some View {
        Button {
            session.isShowingLogin = false
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                Text("Continue reading without an account")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.benchSteel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func accountCard(user: AppUser) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(user.role.tint.opacity(0.14))
                Text(user.initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(user.role.tint)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.fullName)
                    .font(.headline)
                    .foregroundStyle(Color.benchNavy)
                Text(user.title)
                    .font(.caption)
                    .foregroundStyle(.benchSlate)
                HStack(spacing: 4) {
                    Image(systemName: user.role.icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(user.role.displayLabel)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(0.6)
                }
                .foregroundStyle(user.role.tint)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.benchNavy.opacity(0.25))
        }
        .padding(16)
        .background(Color.benchCard)
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: Color.benchNavy.opacity(0.07), radius: 10, y: 4)
    }
}
