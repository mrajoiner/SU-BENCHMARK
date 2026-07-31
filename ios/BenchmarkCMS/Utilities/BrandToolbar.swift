import SwiftUI

/// Small Benchmark wordmark used across navigation bars so branding is pervasive.
struct BenchmarkLogoMark: View {
    var height: CGFloat = 20

    var body: some View {
        Image("benchmark_logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .accessibilityLabel("Southern University Benchmark")
    }
}

extension View {
    /// Puts the Benchmark logo at the leading edge of the navigation bar.
    /// Use on root screens where there is no back button.
    func benchmarkBranded() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BenchmarkLogoMark()
            }
        }
    }

    /// Puts the Benchmark logo in the center of an inline navigation bar.
    /// Use on pushed screens that don't need a text title.
    func benchmarkBrandedCenter() -> some View {
        toolbar {
            ToolbarItem(placement: .principal) {
                BenchmarkLogoMark(height: 18)
            }
        }
    }
}
