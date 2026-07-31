import SwiftUI

/// In-memory image cache so images persist across LazyVStack scroll recycling.
/// Without this, AsyncImage re-downloads every time a card re-enters the viewport,
/// making the feed look grayed out while scrolling.
///
/// Both a count limit AND a cost cap are set: full-size 1200px Unsplash images
/// decode to several MB each, so a count-only cap can hold ~1GB over a long
/// browsing session. The cost limit keeps memory bounded and avoids
/// jetsam/`runtime-interruption` crashes on the simulator.
///
/// Images are downscaled to a max display dimension before caching, so the
/// decoded bitmap is much smaller than the original 1200px download — this is
/// the single most effective change for keeping memory stable during a long
/// browsing session.
actor ImageCache {
    static let shared = ImageCache()

    /// Maximum display dimension (in points). 1200px Unsplash photos are
    /// downscaled to this before storing in the cache.
    static let maxDisplayDimension: CGFloat = 700

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        // ~60MB cap — images are downscaled before caching, so this is generous.
        cache.totalCostLimit = 60 * 1024 * 1024
        // Respond to memory pressure by purging aggressively.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            cache.removeAllObjects()
        }
        return cache
    }()

    func image(for url: String) -> UIImage? {
        cache.object(forKey: url as NSString)
    }

    func store(_ image: UIImage, for url: String) {
        // Cost is the decoded image size in bytes — this is what the system
        // charges against `totalCostLimit` when deciding what to evict.
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url as NSString, cost: cost)
    }

    /// Downscale a downloaded image to a reasonable display size so the
    /// decoded bitmap doesn't dominate the app's memory footprint.
    /// Full-size 1200×800 photos decode to ~3.8MB each; at 700px max they
    /// decode to ~1.3MB — a ~3x reduction per image.
    func downscale(_ image: UIImage) -> UIImage {
        let maxDim = Self.maxDisplayDimension
        let scale = min(1, maxDim / max(image.size.width, image.size.height))
        guard scale < 1 else { return image }
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

/// Cached remote image view. Downloads once, then serves from the in-memory
/// cache on every subsequent appearance — no re-downloading on scroll.
struct CachedAsyncImage: View {
    let urlString: String
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 16

    @State private var image: UIImage?
    @State private var hasFailed = false

    var body: some View {
        Color.benchNavy.opacity(0.06)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                } else if hasFailed {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundStyle(.benchSlate)
                } else {
                    ProgressView()
                        .tint(.benchSlate)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .task { await loadImage() }
    }

    private func loadImage() async {
        // Serve from cache first — instant for previously-loaded images.
        if let cached = await ImageCache.shared.image(for: urlString) {
            withAnimation(.easeIn(duration: 0.15)) { image = cached }
            return
        }

        guard let url = URL(string: urlString) else {
            hasFailed = true
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let rawImage = UIImage(data: data) else {
                hasFailed = true
                return
            }
            // Downscale before caching so the decoded bitmap stays small.
            // This is the key defense against jetsam kills on the simulator.
            let scaled = await ImageCache.shared.downscale(rawImage)
            await ImageCache.shared.store(scaled, for: urlString)
            withAnimation(.easeIn(duration: 0.2)) { image = scaled }
        } catch {
            hasFailed = true
        }
    }
}
