import SwiftUI
import SwiftData

@main
struct BenchmarkCMSApp: App {
    @State private var session = SessionManager()
    @State private var showSplash = true

    let container: ModelContainer

    init() {
        let schema = Schema([
            AppUser.self,
            PostCategory.self,
            Post.self,
            SiteSettings.self,
            Bookmark.self,
            Internship.self,
        ])

        container = Self.makeContainer(schema: schema)
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    /// Creates the persistent container, recovering from a corrupted or
    /// unwritable store instead of crashing at launch.
    ///
    /// The cloud simulator's container sometimes ships without a
    /// `Library/Application Support` directory, which makes the first
    /// `ModelContainer` attempt fail with `errno 2` (No such file or
    /// directory). We pre-create that directory *before* the first attempt
    /// so the common path succeeds without falling through to recovery.
    private static func makeContainer(schema: Schema) -> ModelContainer {
        // Ensure the Application Support directory exists before SwiftData
        // tries to open its SQLite store — otherwise the first attempt fails
        // and Core Data logs a cascade of error-512 recovery messages.
        if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
        }

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema)]
            )
        } catch {
            print("ModelContainer failed (\(error.localizedDescription)) — removing store and retrying")
        }

        // Remove the damaged store files and try once more.
        if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
            for suffix in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: supportURL.appendingPathComponent(suffix))
            }
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema)]
                )
            } catch {
                print("ModelContainer retry failed (\(error.localizedDescription)) — falling back to in-memory store")
            }
        }

        // Last resort: keep the app running with an in-memory store.
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        } catch {
            fatalError("Unable to create any model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(session)
                    .tint(.benchNavy)
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
        }
        .modelContainer(container)
    }
}
