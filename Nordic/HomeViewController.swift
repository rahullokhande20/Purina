//
//  HomeViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 4/30/21.
//

import UIKit
import CoreBluetooth

// MARK: - HomeViewController

/// Landing screen listing the available device features. Binds to
/// `HomeViewModel` for connection state and BLE data flow, and delegates
/// destination navigation to `HomeCoordinator`. This view controller owns
/// layout, UI updates, and the alert/navigation decisions that need
/// on-screen context (e.g. which screen is currently on top).
///
/// The screen renders its own large title, subtitle, and connection card
/// above the menu list instead of using the navigation bar, so the
/// navigation bar is hidden while this screen is on top and restored for
/// any screen pushed on top of it.
final class HomeViewController: UIViewController {

    // MARK: Constants

    private enum Constants {
        static let screenTitle = "Purina"
        static let headerSubtitle = "Device connection & modes"
        static let deviceName = "Purina Sensor"
        static let deviceModesSectionTitle = "DEVICE MODES"
        static let estimatedRowHeight: CGFloat = 76
        static let sectionHeaderKerning: CGFloat = 0.6
    }

    private enum Strings {
        static let ok = "OK"
        static let okay = "Okay"
        static let errorTitle = "Error"
        static let connectPrompt = "Please connect to device"
        static let deviceDisconnected = "Device disconnected, Please try again"
    }

    // MARK: Dependencies

    private let viewModel = HomeViewModel()
    private lazy var coordinator = HomeCoordinator(navigationController: navigationController)

    // MARK: UI

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.screenTitle
        label.font = DesignSystem.Typography.largeTitle
        label.adjustsFontForContentSizeCategory = true
        label.textColor = DesignSystem.Palette.primaryText
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.headerSubtitle
        label.font = DesignSystem.Typography.subtitle
        label.adjustsFontForContentSizeCategory = true
        label.textColor = DesignSystem.Palette.secondaryText
        return label
    }()

    private let connectionCard = ConnectionCardView()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerTitleLabel, headerSubtitleLabel, connectionCard])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = DesignSystem.Spacing.small
        stack.setCustomSpacing(DesignSystem.Spacing.medium, after: headerSubtitleLabel)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: DesignSystem.Spacing.small,
            leading: DesignSystem.Spacing.medium,
            bottom: DesignSystem.Spacing.small,
            trailing: DesignSystem.Spacing.medium
        )
        return stack
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 32
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: DesignSystem.Spacing.large, right: 0)
        tableView.register(HomeMenuCardCell.self, forCellReuseIdentifier: HomeMenuCardCell.reuseIdentifier)
        return tableView
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        configureLayout()
        bindViewModel()
        updateConnectionUI(for: viewModel.connectionState, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: Setup

    private func configureAppearance() {
        view.backgroundColor = DesignSystem.Palette.screenBackground
    }

    private func configureLayout() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: View Model Binding

    private func bindViewModel() {
        viewModel.onConnectionStateChanged = { [weak self] state in
            self?.updateConnectionUI(for: state, animated: true)
            self?.tableView.reloadData()
        }
        viewModel.onConnectionRequiredAlert = { [weak self] in
            self?.presentAlert(message: Strings.connectPrompt)
        }
        viewModel.onNavigate = { [weak self] item, context in
            self?.coordinator.navigate(to: item, context: context)
        }
        viewModel.onRequestScannerPresentation = { [weak self] in
            self?.present(DeviceScannerViewController(), animated: true)
        }
        viewModel.onPeripheralDisconnected = { [weak self] in
            self?.handlePeripheralDisconnected()
        }
        connectionCard.onActionTapped = { [weak self] in
            self?.viewModel.connectButtonTapped()
        }
    }

    // MARK: Connection UI

    private func updateConnectionUI(for state: HomeConnectionState, animated: Bool) {
        connectionCard.configure(
            with: ConnectionCardView.ViewModel(
                deviceName: Constants.deviceName,
                statusText: state.statusText,
                statusColor: state.statusColor,
                actionTitle: state.buttonTitle,
                actionIsPrimary: !state.isConnected
            ),
            animated: animated
        )
    }

    // MARK: Disconnect Handling

    private func handlePeripheralDisconnected() {
        guard let topController = UIApplication.topViewController() else { return }

        // A disconnect is expected while the DFU screen reboots the device,
        // so only surface an error alert on every other screen.
        if topController is DFUUpdateViewController {
            viewModel.resetConnectionState()
        } else {
            DesignSystem.Haptics.warning()
            presentAlert(
                title: Strings.errorTitle,
                message: Strings.deviceDisconnected,
                actionTitle: Strings.okay
            ) { [weak self] _ in
                guard let self else { return }
                self.navigationController?.popToRootViewController(animated: true)
                self.viewModel.resetConnectionState()
            }
        }
    }

    // MARK: Alerts

    private func presentAlert(
        title: String? = nil,
        message: String,
        actionTitle: String = Strings.ok,
        handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        HomeMenuItem.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let item = HomeMenuItem(rawValue: indexPath.row),
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeMenuCardCell.reuseIdentifier,
                for: indexPath
            ) as? HomeMenuCardCell
        else {
            assertionFailure("Misconfigured table view: row \(indexPath.row)")
            return UITableViewCell()
        }
        cell.configure(
            with: item.cardViewModel(isEnabled: viewModel.isItemEnabled(item))
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = HomeMenuItem(rawValue: indexPath.row) else { return }
        viewModel.selectItem(item)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = DesignSystem.Typography.sectionHeader
        label.textColor = DesignSystem.Palette.secondaryText
        let attributedTitle = NSMutableAttributedString(string: Constants.deviceModesSectionTitle)
        attributedTitle.addAttribute(
            .kern,
            value: Constants.sectionHeaderKerning,
            range: NSRange(location: 0, length: attributedTitle.length)
        )
        label.attributedText = attributedTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: DesignSystem.Spacing.medium),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -DesignSystem.Spacing.medium),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: DesignSystem.Spacing.medium),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -DesignSystem.Spacing.xSmall)
        ])
        return container
    }
}

// MARK: - UIApplication + Top View Controller

extension UIApplication {

    /// Walks the controller hierarchy to find the view controller currently
    /// visible to the user.
    class func topViewController(controller: UIViewController? = UIApplication.shared.activeKeyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            return topViewController(controller: selected)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

    private var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
