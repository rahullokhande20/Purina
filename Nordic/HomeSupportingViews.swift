//
//  HomeSupportingViews.swift
//  Nordic
//
//  Design tokens and reusable views backing the home screen.
//

import UIKit

// MARK: - DesignSystem

/// Central design tokens (colors, spacing, fonts) and haptic helpers
/// shared by the home screen UI.
enum DesignSystem {

    enum Palette {
        static let brand = UIColor.adaptive(
            light: UIColor(red: 0.00, green: 0.45, blue: 0.74, alpha: 1.00),
            dark: UIColor(red: 0.22, green: 0.74, blue: 0.94, alpha: 1.00)
        )
        static let accent = UIColor.adaptive(
            light: UIColor(red: 0.83, green: 0.18, blue: 0.14, alpha: 1.00),
            dark: UIColor(red: 1.00, green: 0.42, blue: 0.36, alpha: 1.00)
        )
        static let success = UIColor.systemGreen
        static let warning = UIColor.systemOrange
        static let vital = UIColor.systemPink
        static let info = UIColor.systemTeal
        static let document = UIColor.systemIndigo
        static let screenBackground = UIColor.systemGroupedBackground
        static let cardBackground = UIColor.secondarySystemGroupedBackground
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
        static let disabledText = UIColor.tertiaryLabel
        static let chipBackground = UIColor.tertiarySystemFill
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Typography {
        static var largeTitle: UIFont { scaledFont(baseSize: 30, weight: .bold, style: .largeTitle) }
        static var subtitle: UIFont { scaledFont(baseSize: 15, weight: .regular, style: .subheadline) }
        static var sectionHeader: UIFont { scaledFont(baseSize: 12, weight: .semibold, style: .footnote) }
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

    enum Radius {
        static let card: CGFloat = 16
        static let iconTile: CGFloat = 12
    }

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

    enum Motion {
        static let pressScale: CGFloat = 0.97
        static let pressDuration: TimeInterval = 0.15
        static let transitionDuration: TimeInterval = 0.25
    }

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

extension UIColor {

    static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

// MARK: - CapsuleButton

/// Pill-shaped filled button used for the connect/disconnect bar action.
final class CapsuleButton: UIButton {

    private enum Metrics {
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 8
        static let minimumHeight: CGFloat = 36
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = DesignSystem.Typography.button
        titleLabel?.adjustsFontForContentSizeCategory = true
        setTitleColor(.white, for: .normal)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + Metrics.horizontalPadding * 2,
            height: max(size.height + Metrics.verticalPadding * 2, Metrics.minimumHeight)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func setAppearance(title: String, fillColor: UIColor, animated: Bool) {
        let apply = {
            self.setTitle(title, for: .normal)
            self.backgroundColor = fillColor
        }
        guard animated else {
            apply()
            return
        }
        UIView.transition(
            with: self,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: apply
        )
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: DesignSystem.Motion.pressDuration,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: DesignSystem.Motion.pressScale, y: DesignSystem.Motion.pressScale)
                    : .identity
                self.alpha = self.isHighlighted ? 0.86 : 1
            }
        }
    }
}

// MARK: - StatusChipView

/// Small capsule showing the current connection status with a colored dot.
final class StatusChipView: UIView {

    private enum Metrics {
        static let dotSize: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 6
    }

    private let dotView = UIView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = DesignSystem.Palette.chipBackground
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.layer.cornerRadius = Metrics.dotSize / 2

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = DesignSystem.Typography.chip
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textColor = DesignSystem.Palette.secondaryText

        addSubview(dotView)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: Metrics.dotSize),
            dotView.heightAnchor.constraint(equalToConstant: Metrics.dotSize),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),

            textLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: DesignSystem.Spacing.xSmall),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.verticalPadding),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.verticalPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func update(text: String, statusColor: UIColor, animated: Bool) {
        let apply = {
            self.textLabel.text = text
            self.dotView.backgroundColor = statusColor
            self.accessibilityLabel = text
        }
        guard animated else {
            apply()
            return
        }
        UIView.transition(
            with: self,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: apply
        )
    }
}

// MARK: - ConnectionCardView

/// Prominent card summarizing the current device connection: icon, device
/// name, live status (dot + text), and a Connect/Disconnect pill action.
final class ConnectionCardView: UIView {

    struct ViewModel {
        let deviceName: String
        let statusText: String
        let statusColor: UIColor
        let actionTitle: String
        /// `true` for the primary/filled action (Connect), `false` for the
        /// neutral/outline action (Disconnect).
        let actionIsPrimary: Bool
    }

    private enum Metrics {
        static let iconContainerSize: CGFloat = 44
        static let iconPointSize: CGFloat = 20
        static let iconBackgroundAlpha: CGFloat = 0.15
        static let dotSize: CGFloat = 8
        static let actionHorizontalPadding: CGFloat = 16
        static let actionVerticalPadding: CGFloat = 8
        static let actionMinimumHeight: CGFloat = 34
    }

    var onActionTapped: (() -> Void)?

    private let iconContainerView = UIView()
    private let iconImageView = UIImageView(image: UIImage(systemName: "antenna.radiowaves.left.and.right"))
    private let nameLabel = UILabel()
    private let statusDotView = UIView()
    private let statusLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: DesignSystem.Radius.card).cgPath
        actionButton.layer.cornerRadius = actionButton.bounds.height / 2
    }

    private func configureLayout() {
        backgroundColor = DesignSystem.Palette.cardBackground
        layer.cornerRadius = DesignSystem.Radius.card
        DesignSystem.Shadow.card.apply(to: layer)

        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.layer.cornerRadius = DesignSystem.Radius.iconTile
        iconContainerView.backgroundColor = DesignSystem.Palette.brand.withAlphaComponent(Metrics.iconBackgroundAlpha)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = DesignSystem.Palette.brand
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Metrics.iconPointSize,
            weight: .medium
        )

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = DesignSystem.Typography.cardTitle
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = DesignSystem.Palette.primaryText

        statusDotView.translatesAutoresizingMaskIntoConstraints = false
        statusDotView.layer.cornerRadius = Metrics.dotSize / 2

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = DesignSystem.Typography.caption
        statusLabel.adjustsFontForContentSizeCategory = true

        let statusRow = UIStackView(arrangedSubviews: [statusDotView, statusLabel])
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        statusRow.axis = .horizontal
        statusRow.alignment = .center
        statusRow.spacing = DesignSystem.Spacing.xxSmall

        let textStack = UIStackView(arrangedSubviews: [nameLabel, statusRow])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 4

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = DesignSystem.Typography.button
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.clipsToBounds = true
        actionButton.contentEdgeInsets = UIEdgeInsets(
            top: Metrics.actionVerticalPadding,
            left: Metrics.actionHorizontalPadding,
            bottom: Metrics.actionVerticalPadding,
            right: Metrics.actionHorizontalPadding
        )
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(textStack)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            iconContainerView.widthAnchor.constraint(equalToConstant: Metrics.iconContainerSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: Metrics.iconContainerSize),
            iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignSystem.Spacing.medium),
            iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),

            statusDotView.widthAnchor.constraint(equalToConstant: Metrics.dotSize),
            statusDotView.heightAnchor.constraint(equalToConstant: Metrics.dotSize),

            textStack.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: DesignSystem.Spacing.small),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: DesignSystem.Spacing.medium),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignSystem.Spacing.medium),

            actionButton.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: DesignSystem.Spacing.small),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignSystem.Spacing.medium),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.actionMinimumHeight)
        ])
    }

    func configure(with viewModel: ViewModel, animated: Bool) {
        let apply = {
            self.nameLabel.text = viewModel.deviceName
            self.statusLabel.text = viewModel.statusText
            self.statusLabel.textColor = viewModel.statusColor
            self.statusDotView.backgroundColor = viewModel.statusColor
            self.actionButton.setTitle(viewModel.actionTitle, for: .normal)
            if viewModel.actionIsPrimary {
                self.actionButton.backgroundColor = DesignSystem.Palette.brand
                self.actionButton.setTitleColor(.white, for: .normal)
            } else {
                self.actionButton.backgroundColor = DesignSystem.Palette.chipBackground
                self.actionButton.setTitleColor(DesignSystem.Palette.primaryText, for: .normal)
            }
            self.accessibilityLabel = "\(viewModel.deviceName), \(viewModel.statusText)"
        }
        guard animated else {
            apply()
            return
        }
        UIView.transition(
            with: self,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: apply
        )
    }

    @objc private func actionTapped() {
        onActionTapped?()
    }
}

// MARK: - HomeMenuCardCell

/// Card-style cell for a home menu entry: tinted icon, title, and an
/// optional caption when the feature needs a connected device.
final class HomeMenuCardCell: UITableViewCell {

    static let reuseIdentifier = "HomeMenuCardCell"

    struct ViewModel {
        let title: String
        let systemImageName: String
        let fallbackImageName: String
        let iconTint: UIColor
        let caption: String?
        let isEnabled: Bool
    }

    private enum Metrics {
        static let iconContainerSize: CGFloat = 44
        static let iconPointSize: CGFloat = 20
        static let iconBackgroundAlpha: CGFloat = 0.15
        static let chevronWidth: CGFloat = 8
        static let chevronHeight: CGFloat = 14
        static let chevronPointSize: CGFloat = 13
    }

    private let cardView = UIView()
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let captionLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: DesignSystem.Radius.card
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.alpha = 1
        accessibilityTraits = .button
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(
            withDuration: DesignSystem.Motion.pressDuration,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.cardView.transform = highlighted
                ? CGAffineTransform(scaleX: DesignSystem.Motion.pressScale, y: DesignSystem.Motion.pressScale)
                : .identity
        }
    }

    private func configureLayout() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = DesignSystem.Palette.cardBackground
        cardView.layer.cornerRadius = DesignSystem.Radius.card
        DesignSystem.Shadow.card.apply(to: cardView.layer)

        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.layer.cornerRadius = DesignSystem.Radius.iconTile

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Metrics.iconPointSize,
            weight: .medium
        )

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignSystem.Typography.cardTitle
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = DesignSystem.Palette.primaryText
        titleLabel.numberOfLines = 0

        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = DesignSystem.Typography.caption
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.textColor = DesignSystem.Palette.secondaryText
        captionLabel.numberOfLines = 0

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Metrics.chevronPointSize,
            weight: .semibold
        )
        chevronImageView.tintColor = DesignSystem.Palette.secondaryText
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(cardView)
        cardView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        cardView.addSubview(textStack)
        cardView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.xSmall),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DesignSystem.Spacing.xSmall),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.medium),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.medium),

            iconContainerView.widthAnchor.constraint(equalToConstant: Metrics.iconContainerSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: Metrics.iconContainerSize),
            iconContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: DesignSystem.Spacing.medium),
            iconContainerView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: DesignSystem.Spacing.small),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: DesignSystem.Spacing.medium),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -DesignSystem.Spacing.medium),

            chevronImageView.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: DesignSystem.Spacing.xSmall),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -DesignSystem.Spacing.medium),
            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: Metrics.chevronWidth),
            chevronImageView.heightAnchor.constraint(equalToConstant: Metrics.chevronHeight)
        ])
    }

    func configure(with viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        captionLabel.text = viewModel.caption
        captionLabel.isHidden = viewModel.caption == nil

        let image = UIImage(systemName: viewModel.systemImageName)
            ?? UIImage(named: viewModel.fallbackImageName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.image = image
        iconImageView.tintColor = viewModel.iconTint
        iconContainerView.backgroundColor = viewModel.iconTint.withAlphaComponent(Metrics.iconBackgroundAlpha)
        titleLabel.textColor = viewModel.isEnabled ? DesignSystem.Palette.primaryText : DesignSystem.Palette.disabledText
        captionLabel.textColor = viewModel.isEnabled ? DesignSystem.Palette.secondaryText : DesignSystem.Palette.disabledText
        chevronImageView.tintColor = viewModel.isEnabled ? DesignSystem.Palette.secondaryText : DesignSystem.Palette.disabledText
        contentView.alpha = viewModel.isEnabled ? 1 : 0.72
        accessibilityLabel = viewModel.title
        accessibilityHint = viewModel.caption
        accessibilityTraits = viewModel.isEnabled ? .button : [.button, .notEnabled]
    }
}
