import SwiftUI
import SwiftData

/// Admin: add, edit, hide, reorder, and delete site navigation categories.
struct CategoryManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PostCategory.sortOrder) private var categories: [PostCategory]

    @State private var editingCategory: PostCategory?
    @State private var showNewCategory = false

    var body: some View {
        List {
            Section {
                Text("Drag to reorder the site's top navigation. Hidden categories stay in the CMS but disappear from the public site.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Navigation Order") {
                ForEach(categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        categoryRow(category)
                    }
                    .buttonStyle(.plain)
                }
                .onMove(perform: moveCategories)
                .onDelete(perform: deleteCategories)
            }
        }
        .navigationTitle("Categories")
        .scrollContentBackground(.hidden)
        .background(Color.benchPaper)
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(category: category)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showNewCategory) {
            CategoryEditorSheet(category: nil)
                .presentationDetents([.medium])
        }
    }

    private func categoryRow(_ category: PostCategory) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(category.isHidden ? .secondary : Color.benchNavy)
                Text("/\(category.slug) · \(category.posts.filter { $0.isLive }.count) live")
                    .font(.caption)
                    .foregroundStyle(.benchSlate)
            }

            Spacer()

            if category.isHidden {
                Label("Hidden", systemImage: "eye.slash.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(.vertical, 2)
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
        try? context.save()
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
        try? context.save()
    }
}

/// Create or edit a category.
private struct CategoryEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: PostCategory?

    @State private var name = ""
    @State private var details = ""
    @State private var isHidden = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name (e.g. CSE News)", text: $name)
                    TextField("Description", text: $details, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section {
                    Toggle("Hidden from public site", isOn: $isHidden)
                    LabeledContent("URL slug") {
                        Text("/" + PostCategory.slugify(name))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let category {
                    name = category.name
                    details = category.details
                    isHidden = category.isHidden
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = cleanName
            category.slug = PostCategory.slugify(cleanName)
            category.details = details
            category.isHidden = isHidden
        } else {
            let descriptor = FetchDescriptor<PostCategory>()
            let count = (try? context.fetchCount(descriptor)) ?? 0
            let newCategory = PostCategory(
                name: cleanName,
                details: details,
                sortOrder: count,
                isHidden: isHidden
            )
            context.insert(newCategory)
        }
        try? context.save()
        dismiss()
    }
}
