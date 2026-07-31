import SwiftUI

/// Fixed-height remote image using the Color-anchor + overlay pattern
/// so `.fill` images never break the surrounding layout.
/// Uses CachedAsyncImage so images persist across LazyVStack scroll recycling
/// instead of re-downloading (and appearing grayed out) on every scroll.
struct RemoteImageView: View {
    let urlString: String
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 16

    var body: some View {
        CachedAsyncImage(urlString: urlString, height: height, cornerRadius: cornerRadius)
    }
}

/// Same anchor pattern for locally attached photo data.
struct DataImageView: View {
    let data: Data
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 16

    var body: some View {
        Color.benchNavy.opacity(0.08)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.benchSlate)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
