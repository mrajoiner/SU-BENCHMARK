import SwiftUI
import SwiftData

/// Admin hub: users, categories, all content, and site settings.
struct AdminView: View {
    @Query private var users: [AppUser]
    @Query private var categories: [PostCategory]
    @Query private var posts: [Post]
    @Query private var internships: [Internship]

    let user: AppUser

    var body: some View {
        List {
            Section("Administration") {
                    NavigationLink {
                        UserManagerView()
                    } label: {
                        adminRow(
                            icon: "person.2.fill",
                            tint: .benchSteel,
                            title: "Users",
                            subtitle: "\(users.count) accounts · roles & access"
                        )
                    }

                    NavigationLink {
                        CategoryManagerView()
                    } label: {
                        adminRow(
                            icon: "square.grid.2x2.fill",
                            tint: .benchGold,
                            title: "Categories",
                            subtitle: "\(categories.count) in site navigation · reorder & hide"
                        )
                    }

                    NavigationLink {
                        ContentManagerView(user: user)
                    } label: {
                        adminRow(
                            icon: "doc.text.fill",
                            tint: .benchNavy,
                            title: "All Content",
                            subtitle: "\(posts.count) posts · every status"
                        )
                    }

                    NavigationLink {
                        SiteSettingsView()
                    } label: {
                        adminRow(
                            icon: "gearshape.fill",
                            tint: .benchSlate,
                            title: "Site Settings",
                            subtitle: "Title, tagline, contact & display"
                        )
                    }

                    NavigationLink {
                        InternshipsView(user: user, isTabRoot: false)
                    } label: {
                        adminRow(
                            icon: "briefcase.fill",
                            tint: .benchSteel,
                            title: "Internships",
                            subtitle: "\(internships.count) listings · manage opportunities"
                        )
                    }
                }

                Section("At a Glance") {
                    statRow(label: "Live on site", value: posts.filter { $0.isLive }.count)
                    statRow(label: "Awaiting review", value: posts.filter { $0.status == .submitted }.count)
                    statRow(label: "Approved, awaiting publish", value: posts.filter { $0.status == .approved }.count)
                    statRow(label: "Scheduled", value: posts.filter { $0.isScheduled }.count)
                    statRow(label: "Drafts", value: posts.filter { $0.status == .draft }.count)
                    statRow(label: "Open internships", value: internships.filter { $0.isPublished && !$0.isExpired }.count)
                }
            }
        .navigationTitle("Manage")
        .benchmarkBranded()
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
    }

    private func adminRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.benchNavy)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.benchSlate)
            }
        }
        .padding(.vertical, 4)
    }

    private func statRow(label: String, value: Int) -> some View {
        LabeledContent(label) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
        }
    }
}
