//
//  ScannerDelegate.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol ScannerDelegate {
    @objc optional func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, ecgPeripheral: CBPeripheral, ppgPeripheral : CBPeripheral)
    @objc optional func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral)
}
