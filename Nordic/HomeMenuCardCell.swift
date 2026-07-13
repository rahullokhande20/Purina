//
//  HomeMenuCardCell.swift
//  Purina
//
//  A modern card-style cell for menu screens: tinted icon tile, title,
//  optional caption, disclosure chevron, soft shadow, and a press
//  micro-interaction.
//

import UIKit

final class HomeMenuCardCell: UITableViewCell {

    static let reuseIdentifier = "HomeMenuCardCell"

    struct ViewModel {
        let title: String
        let systemImageName: String
        let fallbackImageName: String
        let iconTint: UIColor
        let caption: String?
    }

    private enum Metrics {
        static let iconTileSize: CGFloat = 44
        static let iconPointSize: CGFloat = 20
        static let iconTintBackgroundAlpha: CGFloat = 0.15
        static let chevronPointSize: CGFloat = 14
    }

    private let cardView = UIView()
    private let iconTileView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let captionLabel = UILabel()
    private let chevronView = UIImageView()

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configuration

    func configure(with viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        captionLabel.text = viewModel.caption
        captionLabel.isHidden = viewModel.caption == nil

        iconView.image = UIImage(systemName: viewModel.systemImageName)
            ?? UIImage(named: viewModel.fallbackImageName)
        iconView.tintColor = viewModel.iconTint
        iconTileView.backgroundColor = viewModel.iconTint.withAlphaComponent(Metrics.iconTintBackgroundAlpha)

        accessibilityLabel = viewModel.title
        accessibilityHint = viewModel.caption
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: DesignSystem.Radius.card
        ).cgPath
    }

    // MARK: Press Micro-interaction

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

    // MARK: Setup

    private func configureSubviews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        isAccessibilityElement = true
        accessibilityTraits = .button

        configureCard()
        configureIcon()
        configureLabels()
        configureChevron()
        activateConstraints()
    }

    private func configureCard() {
        cardView.backgroundColor = DesignSystem.Palette.cardBackground
        cardView.layer.cornerRadius = DesignSystem.Radius.card
        DesignSystem.Shadow.card.apply(to: cardView.layer)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
    }

    private func configureIcon() {
        iconTileView.layer.cornerRadius = DesignSystem.Radius.iconTile
        iconTileView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconTileView)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Metrics.iconPointSize,
            weight: .medium
        )
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconTileView.addSubview(iconView)
    }

    private func configureLabels() {
        titleLabel.font = DesignSystem.Typography.cardTitle
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = DesignSystem.Palette.primaryText
        titleLabel.numberOfLines = 0

        captionLabel.font = DesignSystem.Typography.caption
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.textColor = DesignSystem.Palette.secondaryText
        captionLabel.numberOfLines = 0
    }

    private func configureChevron() {
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = DesignSystem.Palette.secondaryText
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Metrics.chevronPointSize,
            weight: .semibold
        )
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func activateConstraints() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        textStack.axis = .vertical
        textStack.spacing = DesignSystem.Spacing.xxSmall

        let contentStack = UIStackView(arrangedSubviews: [iconTileView, textStack, chevronView])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = DesignSystem.Spacing.small
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.xSmall),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DesignSystem.Spacing.xSmall),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.medium),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.medium),

            iconTileView.widthAnchor.constraint(equalToConstant: Metrics.iconTileSize),
            iconTileView.heightAnchor.constraint(equalToConstant: Metrics.iconTileSize),
            iconView.centerXAnchor.constraint(equalTo: iconTileView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconTileView.centerYAnchor),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: DesignSystem.Spacing.small),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -DesignSystem.Spacing.small),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: DesignSystem.Spacing.medium),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -DesignSystem.Spacing.medium)
        ])
    }
}
