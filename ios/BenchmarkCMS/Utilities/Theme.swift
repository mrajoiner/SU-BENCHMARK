import SwiftUI

/// Benchmark brand palette based on the official Benchmark logo system.
/// Primary Yellow: #FECE34, Primary Blue: #59B6E8, Navy: #051838,
/// Light Blue: #63AEE3, White: #ffffff.
extension Color {
    /// Benchmark navy (#051838) — used for headers, nav bars, primary text, and key surfaces.
    static let benchNavy = Color(red: 5 / 255, green: 24 / 255, blue: 56 / 255)
    /// A deeper navy for gradients and shadow tints.
    static let benchNavyDeep = Color(red: 2 / 255, green: 11 / 255, blue: 28 / 255)
    /// Primary blue (#59B6E8) — icons, links, active accents, and secondary CTAs.
    static let benchBlue = Color(red: 89 / 255, green: 182 / 255, blue: 232 / 255)
    /// Light blue (#63AEE3) — softer accents, secondary highlights, and subtle links.
    static let benchLightBlue = Color(red: 99 / 255, green: 174 / 255, blue: 227 / 255)
    /// Primary yellow (#FECE34) — primary CTAs, badges, and key highlights.
    static let benchYellow = Color(red: 254 / 255, green: 206 / 255, blue: 52 / 255)
    /// Muted steel used for secondary text and subtle icon fills.
    static let benchSlate = Color(red: 74 / 255, green: 95 / 255, blue: 120 / 255)
    /// Main background is always white.
    static let benchPaper = Color.white
    /// Card and container surfaces are white.
    static let benchCard = Color.white
    /// Legacy gold alias mapped to the official primary yellow.
    static let benchGold = Color.benchYellow
    /// Legacy steel alias mapped to the official primary blue.
    static let benchSteel = Color.benchBlue
}

/// Allow dot-shorthand (`.foregroundStyle(.benchNavy)`) wherever a ShapeStyle is expected.
extension ShapeStyle where Self == Color {
    static var benchNavy: Color { Color.benchNavy }
    static var benchNavyDeep: Color { Color.benchNavyDeep }
    static var benchBlue: Color { Color.benchBlue }
    static var benchLightBlue: Color { Color.benchLightBlue }
    static var benchYellow: Color { Color.benchYellow }
    static var benchSlate: Color { Color.benchSlate }
    static var benchPaper: Color { Color.benchPaper }
    static var benchCard: Color { Color.benchCard }
    static var benchGold: Color { Color.benchYellow }
    static var benchSteel: Color { Color.benchBlue }
}

extension LinearGradient {
    static let benchHeader = LinearGradient(
        colors: [.benchNavy, .benchNavyDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
