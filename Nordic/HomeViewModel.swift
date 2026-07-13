//
//  HomeViewModel.swift
//  Nordic
//
//  Connection state and BLE data flow for the Home screen. Extracted from
//  HomeViewController so the view controller is limited to layout and
//  binding; this type owns no UIKit views and can be unit tested.
//
//  Binding convention: the view controller calls the methods below
//  ("input"), and assigns the `on...` closures ("output") to react to
//  state changes. No Combine / reactive framework, per project convention.
//

import UIKit
import CoreBluetooth

// MARK: - Notification Names

extension Notification.Name {
    /// Posted by the device scanner screens once a peripheral connection is established.
    /// The raw value must remain "Connected" for compatibility with existing posters.
    static let deviceConnected = Notification.Name("Connected")

    /// Carries the latest characteristic value as an array of hex strings.
    /// The raw value must remain "NotifyValue" for compatibility with existing observers.
    static let characteristicValueReceived = Notification.Name("NotifyValue")
}

// MARK: - HomeViewModel

final class HomeViewModel: NSObject {

    private enum Constants {
        static let deviceTitle = "LND339"
    }

    // MARK: Output

    /// Fired whenever the connection state changes so the view controller
    /// can refresh the connect button, status chip, and menu enablement.
    var onConnectionStateChanged: ((HomeConnectionState) -> Void)?

    /// Fired when the user selects a menu item that requires a connected
    /// device but none is ready yet.
    var onConnectionRequiredAlert: (() -> Void)?

    /// Fired when a menu item's destination is ready to be shown; carries
    /// what the coordinator needs to build and push it.
    var onNavigate: ((HomeMenuItem, HomeRouteContext) -> Void)?

    /// Fired when the user taps Connect while not currently connected,
    /// asking the view controller to present the device scanner.
    var onRequestScannerPresentation: (() -> Void)?

    /// Fired when the peripheral disconnects unexpectedly. The view
    /// controller decides how to respond, since that depends on which
    /// screen is currently on top (e.g. an expected disconnect during DFU).
    var onPeripheralDisconnected: (() -> Void)?

    // MARK: State

    private(set) var connectionState = HomeConnectionState.disconnected {
        didSet { onConnectionStateChanged?(connectionState) }
    }

    private let connectionService: BluetoothConnectionServicing
    private var services: [CBService] = []
    private var characteristic: CBCharacteristic?

    // MARK: Init

    init(connectionService: BluetoothConnectionServicing = BluetoothConnectionService()) {
        self.connectionService = connectionService
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceConnectedNotification),
            name: .deviceConnected,
            object: nil
        )
    }

    // MARK: Menu

    func isItemEnabled(_ item: HomeMenuItem) -> Bool {
        !item.requiresConnectedDevice || connectionState.isDeviceReady
    }

    func selectItem(_ item: HomeMenuItem) {
        if item.requiresConnectedDevice && !connectionState.isDeviceReady {
            DesignSystem.Haptics.error()
            onConnectionRequiredAlert?()
            return
        }
        let context = HomeRouteContext(
            peripheral: connectionService.peripheral,
            characteristic: characteristic,
            deviceTitle: Constants.deviceTitle
        )
        DesignSystem.Haptics.selection()
        onNavigate?(item, context)
    }

    // MARK: Connection

    func connectButtonTapped() {
        if connectionState.isConnected {
            disconnectPeripheral()
        } else {
            onRequestScannerPresentation?()
        }
    }

    private func disconnectPeripheral() {
        connectionService.disconnectCurrentPeripheral()
        connectionService.peripheral = nil
        resetConnectionState()
    }

    func resetConnectionState() {
        characteristic = nil
        connectionState = .disconnected
    }

    // MARK: Notification Handling

    @objc private func handleDeviceConnectedNotification() {
        guard let peripheral = connectionService.peripheral else { return }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        connectionState = .discovering
        DesignSystem.Haptics.success()
        connectionService.centralManager?.delegate = self
    }
}

// MARK: - CBCentralManagerDelegate

extension HomeViewModel: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Connection is initiated from the scanner screen; no action needed here.
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        onPeripheralDisconnected?()
    }
}

// MARK: - CBPeripheralDelegate

extension HomeViewModel: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let foundServices = peripheral.services, let primaryService = foundServices.first else { return }
        services = foundServices
        peripheral.discoverCharacteristics(nil, for: primaryService)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        // The last non-notify characteristic is used as the command characteristic.
        for discovered in service.characteristics ?? [] where discovered.properties != .notify {
            characteristic = discovered
        }
        if characteristic != nil {
            connectionState = .ready
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let hexString = data.hexDescription.separate(every: 4, with: " ")
        let hexValues = hexString.components(separatedBy: " ")
        NotificationCenter.default.post(name: .characteristicValueReceived, object: hexValues)
    }
}
