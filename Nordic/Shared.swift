//
//  Shared.swift
//  Nordic
//
//  Created by Sai Dammu on 4/30/21.

import Foundation
import CoreBluetooth

class singlton {
    
    static let shared = singlton()
    var peripheral : CBPeripheral!
    var centralManager: CBCentralManager!
    var char: CBCharacteristic!
    
    var ecgPPGfileName : String!
    var saveEcgPpgText : Bool!
}
