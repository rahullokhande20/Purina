//
//  DeviceScannerViewModel.swift
//  Nordic
//
//  Scanning and connection logic for DeviceScannerViewController, using
//  input/output closures per the project's MVVM binding convention.
//

import Foundation
import CoreBluetooth

final class DeviceScannerViewModel: NSObject {

    // MARK: Output

    /// Fired whenever the discovered-peripherals list changes.
    var onPeripheralsChanged: (() -> Void)?

    /// Fired once the selected peripheral finishes connecting; the view
    /// controller dismisses itself in response.
    var onConnected: (() -> Void)?

    // MARK: State

    private(set) var peripherals: [NearByPeripheral] = []

    private let connectionService: BluetoothConnectionServicing
    private var centralManager: CBCentralManager?
    private var selectedPeripheral: CBPeripheral?

    // MARK: Init

    init(connectionService: BluetoothConnectionServicing = BluetoothConnectionService()) {
        self.connectionService = connectionService
        super.init()
    }

    // MARK: Scanning

    func startScanning() {
        var options: [String: Any] = [:]
        options[CBCentralManagerOptionShowPowerAlertKey] = false
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
    }

    func selectPeripheral(at index: Int) {
        guard peripherals.indices.contains(index) else { return }
        centralManager?.stopScan()
        let peripheral = peripherals[index].peripheral
        selectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    func cancelConnection() {
        guard let selectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(selectedPeripheral)
    }
}

// MARK: - CBCentralManagerDelegate

extension DeviceScannerViewModel: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let index = peripherals.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
            peripherals[index].rssi = RSSI
        } else {
            peripherals.append(NearByPeripheral(peripheral: peripheral, rssi: RSSI))
        }
        onPeripheralsChanged?()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error?.localizedDescription ?? "unknown error"))")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionService.centralManager = central
        connectionService.peripheral = peripheral
        NotificationCenter.default.post(name: .deviceConnected, object: nil, userInfo: nil)
        onConnected?()
    }
}

// MARK: - CBPeripheralDelegate

extension DeviceScannerViewModel: CBPeripheralDelegate {
    // No characteristic-level handling here; kept for parity with the
    // original screen, which set `peripheral.delegate = self` without
    // implementing any CBPeripheralDelegate methods.
}
