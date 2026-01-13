import UIKit

/// Дизайн-система приложения на основе Figma
struct DesignSystem {

    // MARK: - Colors
    struct Colors {
        // Background colors
        static let primaryBackground = UIColor(hex: "#25282d")
        static let secondaryBackground = UIColor(hex: "#33353d")
        static let cellBackground = UIColor(hex: "#2f2f2f")

        // Text colors
        static let primaryText = UIColor(hex: "#ffffff")
        static let secondaryText = UIColor(hex: "#858693")
        static let tertiaryText = UIColor(hex: "#54555b")
        static let placeholderText = UIColor(hex: "#54555b")

        // Accent colors
        static let accentBlue = UIColor(hex: "#2f7fff")
        static let accentGreen = UIColor(hex: "#32b96c")
        static let accentRed = UIColor(hex: "#eb4442")
        static let accentPurple = UIColor(hex: "#5300b8")

        // Message bubble colors
        static let incomingMessageBackground = UIColor(hex: "#33353d")
        static let outgoingMessageBackground = UIColor(hex: "#2f7fff")

        // Border colors
        static let separator = UIColor(hex: "#54555b", alpha: 0.3)

        // Status colors
        static let online = UIColor(hex: "#32b96c")
        static let verified = UIColor(hex: "#2f7fff")
    }

    // MARK: - Fonts
    struct Fonts {
        static func systemFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }

        // Headers
        static let title = systemFont(size: 17, weight: .semibold)
        static let subtitle = systemFont(size: 15, weight: .regular)

        // Body text
        static let body = systemFont(size: 15, weight: .regular)
        static let bodyBold = systemFont(size: 15, weight: .semibold)

        // Small text
        static let caption = systemFont(size: 13, weight: .regular)
        static let captionBold = systemFont(size: 13, weight: .semibold)

        // Tiny text
        static let footnote = systemFont(size: 11, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let huge: CGFloat = 24
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let round: CGFloat = 20
    }

    // MARK: - Sizes
    struct Sizes {
        static let avatarSmall: CGFloat = 40
        static let avatarMedium: CGFloat = 48
        static let avatarLarge: CGFloat = 64

        static let buttonHeight: CGFloat = 44
        static let cellHeight: CGFloat = 72

        static let tabBarHeight: CGFloat = 49
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
