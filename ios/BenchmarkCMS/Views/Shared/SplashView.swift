import SwiftUI

/// A short, branded splash screen shown on app launch.
/// It displays the Benchmark mark on a white background and fades away
/// before the main content appears.
struct SplashView: View {
    let onComplete: () -> Void

    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.benchPaper.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("benchmark_logo_lightblue")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 52)

                Text("Showcasing Southern University's excellence to the world.")
                    .font(.subheadline)
                    .foregroundStyle(.benchSlate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                ProgressView()
                    .tint(.benchYellow)
                    .padding(.top, 8)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35)) {
                opacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }
        }
    }
}
