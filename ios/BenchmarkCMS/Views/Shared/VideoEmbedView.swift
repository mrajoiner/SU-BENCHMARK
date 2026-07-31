import SwiftUI
import WebKit

/// Embeds YouTube/Vimeo (or any) video URLs in an inline player.
struct VideoEmbedView: View {
    let urlString: String

    var body: some View {
        if let url = VideoEmbedView.embedURL(from: urlString) {
            WebVideoPlayer(url: url)
                .frame(height: 210)
                .clipShape(.rect(cornerRadius: 16))
        } else {
            // Degrade gracefully instead of showing nothing or crashing
            // when the URL can't be parsed into an embeddable form.
            Color.benchNavy.opacity(0.06)
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "play.rectangle")
                            .font(.title2)
                            .foregroundStyle(.benchSlate)
                        Text("Video unavailable")
                            .font(.caption)
                            .foregroundStyle(.benchSlate)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
        }
    }

    /// Converts common share links to their embeddable form.
    static func embedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        let host = url.host()?.lowercased() ?? ""

        if host.contains("youtube.com"), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1")
            }
            if url.path().hasPrefix("/embed/") { return url }
        }
        if host.contains("youtu.be") {
            let videoID = url.lastPathComponent
            if !videoID.isEmpty {
                return URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1")
            }
        }
        if host.contains("vimeo.com"), !host.contains("player") {
            let videoID = url.lastPathComponent
            if Int(videoID) != nil {
                return URL(string: "https://player.vimeo.com/video/\(videoID)")
            }
        }
        return url
    }
}

private struct WebVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = [.all]
        // Keep WebKit from accumulating data over a long browsing session.
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        // Avoid retaining the view's process after navigation away.
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // Stop loading and remove all messages to prevent WebKit process
        // crashes when the view is recycled during navigation.
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Swallow navigation errors so WebKit doesn't surface a crash
            // sheet when an embed fails to load on the simulator.
            print("Video embed failed: \(error.localizedDescription)")
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Video embed provisional failure: \(error.localizedDescription)")
        }
    }
}
