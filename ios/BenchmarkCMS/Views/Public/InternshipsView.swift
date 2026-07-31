import SwiftUI
import SwiftData

/// Public internship board — visible to all users (including guests).
/// Authenticated contributors+ can post and manage their own listings;
/// approvers/admins see all listings including drafts.
struct InternshipsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Internship.deadline, order: .forward) private var allInternships: [Internship]

    /// Signed-in account, or nil when browsing as a guest.
    var user: AppUser?

    /// When true, this view is the root of a tab's NavigationStack (no back button).
    /// When false, it was pushed from another screen and should show a back button.
    var isTabRoot: Bool = true

    @State private var newInternship: Internship?
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showClosed = false

    private var visibleInternships: [Internship] {
        allInternships.filter { item in
            // Visibility: guests and non-staff see only published + not expired
            let canSeeDrafts = user?.role.canPublish ?? false || user?.role.canAdminister ?? false
            if !canSeeDrafts && !item.isPublished { return false }
            if !canSeeDrafts && item.isExpired { return false }

            if !showClosed && item.isExpired { return false }

            if let selectedCategory, item.category != selectedCategory { return false }

            let query = searchText.trimmingCharacters(in: .whitespaces)
            if !query.isEmpty {
                return item.title.localizedStandardContains(query)
                    || item.company.localizedStandardContains(query)
                    || item.summary.localizedStandardContains(query)
                    || item.category.localizedStandardContains(query)
            }
            return true
        }
    }

    private var categories: [String] {
        let seen = Set(allInternships.filter { $0.isPublished }.map(\.category))
        return InternshipCategory.allCases.map(\.rawValue).filter { seen.contains($0) }
    }

    private var canPost: Bool { user != nil }
    private var canManageAll: Bool { user?.role.canPublish ?? false || user?.role.canAdminister ?? false }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    categoryChips

                    if visibleInternships.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(visibleInternships) { item in
                                NavigationLink(value: item) {
                                    internshipCard(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .background(Color.benchPaper)
        .toolbar(isTabRoot ? .hidden : .automatic, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $newInternship) { item in
            if let user {
                InternshipEditorView(internship: item, user: user)
            } else {
                Text("Sign in to edit internships.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationDestination(for: Internship.self) { item in
            InternshipDetailView(internship: item, user: user)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Internships")
                        .font(.title2.weight(.bold))
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                    Text("Opportunities for Southern University students")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                if canPost {
                    Button {
                        let item = Internship(author: user)
                        context.insert(item)
                        try? context.save()
                        newInternship = item
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.benchGold)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.6))
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search internships…").foregroundStyle(.white.opacity(0.5))
                )
                .foregroundStyle(.white)
                .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.12), in: .capsule)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient.benchHeader
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.benchSteel.opacity(0.16))
                        .frame(width: 220, height: 220)
                        .offset(x: 90, y: -100)
                }
                .clipped()
        )
        .clipShape(.rect(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.snappy) { selectedCategory = nil }
                }
                ForEach(categories, id: \.self) { cat in
                    chip(label: cat, isSelected: selectedCategory == cat) {
                        withAnimation(.snappy) { selectedCategory = cat }
                    }
                }

                Divider()
                    .frame(height: 18)

                Button {
                    withAnimation(.snappy) { showClosed.toggle() }
                } label: {
                    Label("Closed", systemImage: showClosed ? "checkmark.circle.fill" : "circle")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(showClosed ? .benchNavy : .benchSlate)
                }
                .buttonStyle(.plain)
            }
        }
        .contentMargins(.horizontal, 16)
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : Color.benchNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.benchNavy : Color.benchNavy.opacity(0.07),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card

    private func internshipCard(_ item: Internship) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !item.imageURL.isEmpty {
                RemoteImageView(urlString: item.imageURL, height: 140, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(0.8)
                        .foregroundStyle(.benchGold)

                    Spacer()

                    if !item.isPublished {
                        statusPill("Draft", tint: .benchSlate)
                    } else if item.isExpired {
                        statusPill("Closed", tint: .gray)
                    } else {
                        statusPill("Open", tint: Color(red: 0.18, green: 0.55, blue: 0.34))
                    }
                }

                Text(item.title)
                    .font(.headline)
                    .fontDesign(.serif)
                    .foregroundStyle(Color.benchNavy)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.benchSteel)
                    Text(item.company)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.benchNavy)

                    if !item.location.isEmpty {
                        Text("·")
                            .foregroundStyle(.benchSlate)
                        Image(systemName: item.isRemote ? "wifi" : "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundStyle(.benchSteel)
                        Text(item.isRemote ? "Remote" : item.location)
                            .font(.caption)
                            .foregroundStyle(.benchSlate)
                    }
                }

                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.benchSlate)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Image(systemName: item.isPaid ? "dollarsign.circle.fill" : "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(item.isPaid ? Color(red: 0.18, green: 0.55, blue: 0.34) : .pink)
                    Text(item.isPaid ? "Paid" : "Unpaid")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(item.isPaid ? Color(red: 0.18, green: 0.55, blue: 0.34) : .pink)

                    Spacer()

                    Label(item.deadlineLabel, systemImage: "calendar")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(item.isExpired ? .gray : .benchSlate)
                }
                .padding(.top, 2)
            }
            .padding(16)
        }
        .background(Color.benchCard)
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: Color.benchNavy.opacity(0.08), radius: 12, y: 5)
    }

    private func statusPill(_ text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .kerning(0.5)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: .capsule)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? "briefcase" : "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(.benchSlate.opacity(0.4))
            Text(searchText.isEmpty ? "No internships posted yet" : "No matches")
                .font(.headline)
                .foregroundStyle(Color.benchNavy)
            Text(searchText.isEmpty
                 ? "Check back soon — new opportunities are posted regularly."
                 : "Try a different search term or category.")
                .font(.subheadline)
                .foregroundStyle(.benchSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Detail View

/// Full detail view for a single internship listing.
struct InternshipDetailView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    let internship: Internship
    var user: AppUser?

    private var canEdit: Bool {
        guard let user else { return false }
        return internship.author?.username == user.username || user.role.canPublish || user.role.canAdminister
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !internship.imageURL.isEmpty {
                    RemoteImageView(urlString: internship.imageURL, height: 220, cornerRadius: 0)
                        .clipShape(.rect(topLeadingRadius: 0, topTrailingRadius: 0))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(internship.category)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundStyle(.benchGold)

                    Text(internship.title)
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.benchNavy)

                    HStack(spacing: 10) {
                        Label(internship.company, systemImage: "building.2.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.benchNavy)

                        if !internship.location.isEmpty {
                            Label(internship.isRemote ? "Remote" : internship.location,
                                  systemImage: internship.isRemote ? "wifi" : "mappin.and.ellipse")
                                .font(.footnote)
                                .foregroundStyle(.benchSlate)
                        }
                    }

                    HStack(spacing: 10) {
                        Label(internship.isPaid ? "Paid Position" : "Unpaid",
                              systemImage: internship.isPaid ? "dollarsign.circle.fill" : "heart.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(internship.isPaid ? Color(red: 0.18, green: 0.55, blue: 0.34) : .pink)

                        Label(internship.deadlineLabel, systemImage: "calendar")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(internship.isExpired ? .gray : .benchSteel)
                    }

                    Rectangle()
                        .fill(Color.benchGold)
                        .frame(width: 56, height: 3)

                    if !internship.summary.isEmpty {
                        Text(internship.summary)
                            .font(.title3.weight(.medium))
                            .fontDesign(.serif)
                            .foregroundStyle(.benchSlate)
                            .padding(.vertical, 4)
                    }

                    Text(internship.bodyText.isEmpty ? "No description provided." : internship.bodyText)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(Color.benchNavy.opacity(0.92))

                    if !internship.isExpired && !internship.applicationURL.isEmpty {
                        applyButton
                            .padding(.top, 8)
                    }

                    if canEdit {
                        editLink
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .background(Color.benchPaper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BenchmarkLogoMark(height: 18)
            }
        }
    }

    private var applyButton: some View {
        Button {
            if let url = URL(string: internship.applicationURL) {
                openURL(url)
            }
        } label: {
            HStack {
                Text("Apply Now")
                    .font(.headline)
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.benchNavy, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var editLink: some View {
        if let user {
            NavigationLink {
                InternshipEditorView(internship: internship, user: user)
            } label: {
                Label("Edit Listing", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.benchSteel)
            }
        }
    }
}
