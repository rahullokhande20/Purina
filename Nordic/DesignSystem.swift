//
//  DesignSystem.swift
//  Purina
//
//  Central design tokens. All UI should source colors, typography, spacing,
//  radii, shadows, motion, and haptics from here instead of hardcoding values.
//

import UIKit

enum DesignSystem {

    // MARK: - Palette

    /// Semantic, dark-mode-adaptive colors. Brand colors are brightened in
    /// dark mode to preserve contrast on dark surfaces.
    enum Palette {
        static let brand = UIColor.adaptive(
            light: UIColor(hexString: "00A1D8"),
            dark: UIColor(hexString: "34C3F2")
        )
        static let accent = UIColor.adaptive(
            light: UIColor(hexString: "EB3D2D"),
            dark: UIColor(hexString: "FF6B5C")
        )
        static let success = UIColor.systemGreen
        static let screenBackground = UIColor.systemGroupedBackground
        static let cardBackground = UIColor.secondarySystemGroupedBackground
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
        static let chipBackground = UIColor.tertiarySystemFill
    }

    // MARK: - Typography

    /// Dynamic Type–aware fonts. Base sizes match Apple's default (Large)
    /// content size for each text style and scale with the user's setting.
    enum Typography {
        static var screenTitle: UIFont { scaledFont(baseSize: 17, weight: .semibold, style: .headline) }
        static var cardTitle: UIFont { scaledFont(baseSize: 16, weight: .semibold, style: .headline) }
        static var caption: UIFont { scaledFont(baseSize: 12, weight: .regular, style: .caption1) }
        static var chip: UIFont { scaledFont(baseSize: 13, weight: .medium, style: .footnote) }
        static var button: UIFont { scaledFont(baseSize: 15, weight: .semibold, style: .subheadline) }

        private static func scaledFont(baseSize: CGFloat, weight: UIFont.Weight, style: UIFont.TextStyle) -> UIFont {
            let base = UIFont.systemFont(ofSize: baseSize, weight: weight)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        }
    }

    // MARK: - Spacing

    /// 4pt-grid spacing scale.
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let card: CGFloat = 16
        static let iconTile: CGFloat = 12
    }

    // MARK: - Shadows

    struct Shadow {
        let color: UIColor
        let opacity: Float
        let radius: CGFloat
        let offset: CGSize

        static let card = Shadow(
            color: .black,
            opacity: 0.08,
            radius: 10,
            offset: CGSize(width: 0, height: 4)
        )

        func apply(to layer: CALayer) {
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = opacity
            layer.shadowRadius = radius
            layer.shadowOffset = offset
        }
    }

    // MARK: - Motion

    enum Motion {
        static let pressScale: CGFloat = 0.97
        static let pressDuration: TimeInterval = 0.15
        static let transitionDuration: TimeInterval = 0.25
    }

    // MARK: - Haptics

    @MainActor
    enum Haptics {
        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }

        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        static func warning() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - UIColor + Adaptive

extension UIColor {
    /// A color that resolves differently for light and dark interface styles.
    static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
