import SwiftUI
import UIKit

enum Theme {
    static let bg = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let field = Color(.tertiarySystemGroupedBackground)
    /// Black in light mode, soft grey in dark mode (white would hide switch knobs).
    static let tint = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.62, alpha: 1) : .black })
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.88)

    static func num(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Small section labels: spaced capitals in English, plain in Chinese.
    static func label(_ s: String) -> some View {
        Text(L.zh ? s : s.uppercased())
            .font(.system(size: L.zh ? 13 : 11, weight: .semibold))
            .tracking(L.zh ? 0.3 : 0.8)
            .foregroundStyle(.secondary)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
