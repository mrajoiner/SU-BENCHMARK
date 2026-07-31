import SwiftUI

/// A pervasive floating button that returns the user to the landing page.
/// Applied as a view modifier so it overlays on every screen.
struct FloatingHomeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient.benchHeader)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.benchGold.opacity(0.35), lineWidth: 1.5)
                    }
                    .shadow(color: Color.benchNavy.opacity(0.35), radius: 10, y: 5)

                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.benchGold)
            }
        }
        .buttonStyle(HomeButtonStyle())
        .accessibilityLabel("Home")
        .accessibilityHint("Return to the Benchmark home page")
    }
}

/// Press-scale micro-interaction for the floating home button.
private struct HomeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(duration: 0.3), value: configuration.isPressed)
    }
}

extension View {
    /// Overlays a floating home button at the bottom-trailing corner.
    /// - Parameter bottomPadding: Distance from the bottom edge. Use a larger
    ///   value (~88pt) when the view includes a tab bar.
    func floatingHomeButton(
        bottomPadding: CGFloat = 24,
        action: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .bottomTrailing) {
            FloatingHomeButton(action: action)
                .padding(.trailing, 18)
                .padding(.bottom, bottomPadding)
                .ignoresSafeArea(.keyboard)
        }
    }
}
