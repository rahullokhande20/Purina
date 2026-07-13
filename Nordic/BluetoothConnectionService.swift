//
//  BluetoothConnectionService.swift
//  Nordic
//
//  Small facade over the legacy shared BLE state used by the Home screen
//  and the device scanner (which sets centralManager/peripheral once a
//  connection succeeds).
//

import CoreBluetooth

protocol BluetoothConnectionServicing: AnyObject {
    var centralManager: CBCentralManager? { get set }
    var peripheral: CBPeripheral? { get set }

    func disconnectCurrentPeripheral()
}

final class BluetoothConnectionService: BluetoothConnectionServicing {

    var centralManager: CBCentralManager? {
        get { singlton.shared.centralManager }
        set { singlton.shared.centralManager = newValue }
    }

    var peripheral: CBPeripheral? {
        get { singlton.shared.peripheral }
        set { singlton.shared.peripheral = newValue }
    }

    func disconnectCurrentPeripheral() {
        guard let manager = centralManager, let peripheral else { return }
        manager.cancelPeripheralConnection(peripheral)
    }
}
