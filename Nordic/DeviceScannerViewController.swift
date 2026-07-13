//
//  DeviceScannerViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 4/14/21.
//
//  Renamed from ViewController. Scans for nearby peripherals and connects
//  to the one the user selects; presented modally from Home's Connect
//  button. `NearByPeripheral` and `DeviceCell` are also reused by
//  `DevicesViewController` (the ECG/PPG dual-device scanner, not yet
//  refactored), so their public surface is kept stable here rather than
//  narrowed.
//

import UIKit
import CoreBluetooth

// MARK: - DeviceScannerViewController

final class DeviceScannerViewController: UIViewController {

    private let viewModel = DeviceScannerViewModel()

    private let tableView = UITableView()

    private lazy var disconnectButton: UIButton = {
        let button = UIButton(type: .system)
        // UIBarButtonItem(customView:) reads the view's frame at assignment
        // time, so this needs a real, non-zero size before configureAppearance()
        // wraps it — an explicit frame here (rather than relying on Auto
        // Layout constraints resolving later) avoids the button briefly
        // having a degenerate (zero) size while it's part of the nav bar.
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.setTitle("X", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = DesignSystem.Palette.accent
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        configureLayout()
        bindViewModel()
        viewModel.startScanning()
    }

    // MARK: Setup

    private func configureAppearance() {
        title = "Devices"
        view.backgroundColor = DesignSystem.Palette.screenBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: disconnectButton)
    }

    private func configureLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.reuseIdentifier)
        view.addSubview(tableView)

        disconnectButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            disconnectButton.widthAnchor.constraint(equalToConstant: 40),
            disconnectButton.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: View Model Binding

    private func bindViewModel() {
        viewModel.onPeripheralsChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onConnected = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    // MARK: Actions

    @objc private func disconnectButtonTapped() {
        viewModel.cancelConnection()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension DeviceScannerViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DeviceCell.reuseIdentifier,
            for: indexPath
        ) as? DeviceCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.peripherals[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectPeripheral(at: indexPath.row)
    }
}

// MARK: - NearByPeripheral

/// A discovered BLE peripheral awaiting connection. Also constructed and
/// mutated directly by `DevicesViewController`, which reads `rssi` with
/// `?? 0` — so `rssi` stays an implicitly-unwrapped optional here (it's
/// always set at init in practice) rather than a plain `NSNumber`, to
/// avoid breaking that untouched screen's compile-time compatibility.
final class NearByPeripheral {

    let peripheral: CBPeripheral
    var rssi: NSNumber!

    init(peripheral: CBPeripheral, rssi: NSNumber) {
        self.peripheral = peripheral
        self.rssi = rssi
    }
}

// MARK: - SignalStrength

/// Maps an RSSI reading to the bundled signal-strength icon name. Pulled
/// out of `cellForRowAt` so it's independently unit tested; mirrors the
/// original threshold bands exactly, including the pre-existing overlap
/// between the `66...77` and `77...89` bands (a value of 77 always lands
/// in the first matching case).
enum SignalStrength {
    static func imageName(forRSSI rssi: NSNumber) -> String {
        switch abs(rssi.intValue) {
        case 0...40: return "signal_strength_5"
        case 41...53: return "signal_strength_4"
        case 54...65: return "signal_strength_3"
        case 66...77: return "signal_strength_2"
        case 77...89: return "signal_strength_1"
        default: return "signal_strength_0"
        }
    }
}

// MARK: - DeviceCell

/// Row showing a discovered peripheral's name and signal strength.
/// `DevicesViewController` also dequeues this cell and sets `nameLabel`,
/// `strengthLabel`, and `strengthImageView` directly, so those stay
/// non-private even though `DeviceScannerViewController` uses
/// `configure(with:)` instead.
final class DeviceCell: UITableViewCell {

    static let reuseIdentifier = "DeviceCell"

    let nameLabel = UILabel()
    let strengthImageView = UIImageView()
    let strengthLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        strengthImageView.translatesAutoresizingMaskIntoConstraints = false
        strengthImageView.contentMode = .scaleAspectFit

        strengthLabel.translatesAutoresizingMaskIntoConstraints = false
        strengthLabel.textColor = DesignSystem.Palette.secondaryText

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = DesignSystem.Palette.primaryText

        contentView.addSubview(strengthImageView)
        contentView.addSubview(strengthLabel)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            strengthImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.small),
            strengthImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            strengthImageView.widthAnchor.constraint(equalToConstant: 30),
            strengthImageView.heightAnchor.constraint(equalToConstant: 30),

            strengthLabel.leadingAnchor.constraint(equalTo: strengthImageView.leadingAnchor),
            strengthLabel.topAnchor.constraint(equalTo: strengthImageView.bottomAnchor),
            strengthLabel.widthAnchor.constraint(equalToConstant: 30),

            nameLabel.leadingAnchor.constraint(equalTo: strengthImageView.trailingAnchor, constant: DesignSystem.Spacing.small),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.small),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    /// Convenience used by `DeviceScannerViewController`. `DevicesViewController`
    /// sets the labels/image view directly instead of using this method.
    func configure(with peripheral: NearByPeripheral) {
        nameLabel.text = peripheral.peripheral.name ?? ""
        strengthLabel.text = "\(peripheral.rssi ?? 0)"
        strengthImageView.image = UIImage(named: SignalStrength.imageName(forRSSI: peripheral.rssi ?? 0))
    }
}
