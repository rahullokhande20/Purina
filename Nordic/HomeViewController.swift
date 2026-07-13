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
final class HomeViewController: UIViewController {

    // MARK: Constants

    private enum Constants {
        static let screenTitle = "Purina"
        static let estimatedRowHeight: CGFloat = 76
    }

    private enum Strings {
        static let ok = "OK"
        static let okay = "Okay"
        static let errorTitle = "Error"
        static let connectPrompt = "Please connect to device"
        static let deviceDisconnected = "Device disconnected, Please try again"
        static let requiresDevice = "Requires connected device"
    }

    // MARK: Dependencies

    private let viewModel = HomeViewModel()
    private lazy var coordinator = HomeCoordinator(navigationController: navigationController)

    // MARK: UI

    private lazy var connectButton: CapsuleButton = {
        let button = CapsuleButton()
        button.setAppearance(
            title: viewModel.connectionState.buttonTitle,
            fillColor: viewModel.connectionState.buttonFillColor,
            animated: false
        )
        button.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        return button
    }()

    private let statusChip = StatusChipView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.contentInset = UIEdgeInsets(top: DesignSystem.Spacing.xSmall, left: 0, bottom: DesignSystem.Spacing.large, right: 0)
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
        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }

    // MARK: Setup

    private func configureAppearance() {
        title = Constants.screenTitle
        view.backgroundColor = DesignSystem.Palette.screenBackground

        // Per-item appearance so this screen adopts the modern neutral bar
        // without restyling the screens pushed on the same navigation stack.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: DesignSystem.Palette.primaryText,
            .font: DesignSystem.Typography.screenTitle
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = DesignSystem.Palette.brand

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: connectButton)
    }

    private func configureLayout() {
        statusChip.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusChip)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            statusChip.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: DesignSystem.Spacing.small
            ),
            statusChip.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: DesignSystem.Spacing.medium
            ),
            statusChip.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -DesignSystem.Spacing.medium
            ),

            tableView.topAnchor.constraint(
                equalTo: statusChip.bottomAnchor,
                constant: DesignSystem.Spacing.xSmall
            ),
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
    }

    // MARK: Connection UI

    private func updateConnectionUI(for state: HomeConnectionState, animated: Bool) {
        connectButton.setAppearance(
            title: state.buttonTitle,
            fillColor: state.buttonFillColor,
            animated: animated
        )
        statusChip.update(
            text: state.statusText,
            statusColor: state.statusColor,
            animated: animated
        )
    }

    // MARK: Actions

    @objc private func connectButtonTapped() {
        viewModel.connectButtonTapped()
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
            with: item.cardViewModel(
                requiresDeviceText: Strings.requiresDevice,
                isEnabled: viewModel.isItemEnabled(item)
            )
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
