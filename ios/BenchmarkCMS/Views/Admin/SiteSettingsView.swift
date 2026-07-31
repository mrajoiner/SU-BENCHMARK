import SwiftUI
import SwiftData

/// Admin: global site configuration.
struct SiteSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [SiteSettings]

    var body: some View {
        Group {
            if let settings = settingsList.first {
                SettingsForm(settings: settings)
            } else {
                ProgressView()
                    .onAppear {
                        context.insert(SiteSettings())
                        try? context.save()
                    }
            }
        }
        .navigationTitle("Site Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsForm: View {
    @Environment(\.modelContext) private var context
    @Bindable var settings: SiteSettings

    var body: some View {
        Form {
            Section("Benchmark") {
                VStack(spacing: 10) {
                    Image("benchmark_logo_black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)

                    Text("Showcasing Southern University's excellence to the world.")
                        .font(.caption)
                        .foregroundStyle(.benchSlate)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            Section("Identity") {
                TextField("Site title", text: $settings.siteTitle)
                    .onChange(of: settings.siteTitle) { _, _ in save() }
                TextField("Tagline", text: $settings.tagline, axis: .vertical)
                    .lineLimit(2...3)
                    .onChange(of: settings.tagline) { _, _ in save() }
            }

            Section("Publishing") {
                TextField("Public site URL", text: $settings.siteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: settings.siteURL) { _, _ in save() }
                TextField("Contact email", text: $settings.contactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: settings.contactEmail) { _, _ in save() }
                TextField("Footer text", text: $settings.footerText)
                    .onChange(of: settings.footerText) { _, _ in save() }
            }

            Section("Display") {
                Toggle("Show search on site", isOn: $settings.showSearch)
                    .onChange(of: settings.showSearch) { _, _ in save() }
                Toggle("Feature the latest post", isOn: $settings.showFeaturedPost)
                    .onChange(of: settings.showFeaturedPost) { _, _ in save() }
            }

            Section {
                LabeledContent("Last updated") {
                    Text(settings.updatedAt, format: .relative(presentation: .named))
                }
                .font(.footnote)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
    }

    private func save() {
        settings.updatedAt = .now
        try? context.save()
    }
}
