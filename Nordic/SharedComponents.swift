//
//  SharedComponents.swift
//  Purina
//
//  Reusable UI components built on the design system.
//

import UIKit

// MARK: - CapsuleButton

/// A pill-shaped filled button used for primary inline actions
/// (e.g. Connect/Disconnect in a navigation bar).
final class CapsuleButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = DesignSystem.Typography.button
        titleLabel?.adjustsFontForContentSizeCategory = true
        setTitleColor(.white, for: .normal)
        contentEdgeInsets = UIEdgeInsets(
            top: DesignSystem.Spacing.xxSmall + 2,
            left: DesignSystem.Spacing.small,
            bottom: DesignSystem.Spacing.xxSmall + 2,
            right: DesignSystem.Spacing.small
        )
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override var isHighlighted: Bool {
        didSet { animatePress(isHighlighted) }
    }

    /// Updates the title and fill color, cross-fading between states.
    func setAppearance(title: String, fillColor: UIColor, animated: Bool = true) {
        let updates = {
            self.setTitle(title, for: .normal)
            self.backgroundColor = fillColor
        }
        guard animated else {
            updates()
            return
        }
        UIView.transition(
            with: self,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: updates
        )
    }

    private func animatePress(_ pressed: Bool) {
        UIView.animate(
            withDuration: DesignSystem.Motion.pressDuration,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.transform = pressed
                ? CGAffineTransform(scaleX: DesignSystem.Motion.pressScale, y: DesignSystem.Motion.pressScale)
                : .identity
            self.alpha = pressed ? 0.85 : 1
        }
    }
}

// MARK: - StatusChipView

/// A small capsule chip with a colored status dot and a label,
/// used to surface connection state.
final class StatusChipView: UIView {

    private enum Metrics {
        static let dotSize: CGFloat = 8
    }

    private let dotView = UIView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        dotView.layer.cornerRadius = Metrics.dotSize / 2
    }

    /// Updates the chip's text and status color with a subtle cross-fade.
    func update(text: String, statusColor: UIColor, animated: Bool = true) {
        let updates = {
            self.textLabel.text = text
            self.dotView.backgroundColor = statusColor
        }
        accessibilityLabel = text
        guard animated else {
            updates()
            return
        }
        UIView.transition(
            with: self,
            duration: DesignSystem.Motion.transitionDuration,
            options: .transitionCrossDissolve,
            animations: updates
        )
    }

    private func configureSubviews() {
        backgroundColor = DesignSystem.Palette.chipBackground

        isAccessibilityElement = true
        accessibilityTraits = .staticText

        textLabel.font = DesignSystem.Typography.chip
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textColor = DesignSystem.Palette.secondaryText

        let stack = UIStackView(arrangedSubviews: [dotView, textLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = DesignSystem.Spacing.xSmall
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: Metrics.dotSize),
            dotView.heightAnchor.constraint(equalToConstant: Metrics.dotSize),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DesignSystem.Spacing.xxSmall + 2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(DesignSystem.Spacing.xxSmall + 2)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignSystem.Spacing.small),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignSystem.Spacing.small)
        ])
    }
}
