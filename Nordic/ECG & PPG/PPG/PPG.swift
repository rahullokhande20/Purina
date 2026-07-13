//
//  PPG.swift
//  HeartMath
//
//  Created by Sai Dammu on 11/11/21.
//

import Foundation
import CoreBluetooth

class PPG : NSObject, CBPeripheralDelegate{
    
    var ppgPeripheral : CBPeripheral!
    var ppgChar : CBCharacteristic!
    var update : ( (Data) -> () )?
    var ppgReady : ( () -> () )?
    let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override init() {
        super.init()
        
    }
    
    func discvoer(ppgPeripheral:CBPeripheral){
        self.ppgPeripheral = ppgPeripheral
       
        self.ppgPeripheral.delegate = self
        self.ppgPeripheral.discoverServices(nil)
    }
    
    
    func start(){
        
        let writeData = Utils.sharedInst()?.startECGPPGGraph()
        ppgPeripheral.writeValue(writeData!, for: ppgChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    
    func writeGain(writeGainSelected:String ){
        let value1Int = UInt8(writeGainSelected, radix:16)
        let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
        
        ppgPeripheral.writeValue(responseDict!["Data"] as! Data, for: ppgChar, type: CBCharacteristicWriteType.withoutResponse)
        ppgPeripheral.setNotifyValue(true, for: ppgChar)
       
    }
    
    func readGain(){
        
        let writeData = Utils.sharedInst()?.sendReadGainLND()
        ppgPeripheral.writeValue(writeData!, for: ppgChar, type: CBCharacteristicWriteType.withoutResponse)
        ppgPeripheral.setNotifyValue(true, for: ppgChar)
        
    }
    
    
    func stop(){
        
        let writeData = Utils.sharedInst()?.stopECGPPGGraph()
        ppgPeripheral.writeValue(writeData!, for: ppgChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
       
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        
        for newChar: CBCharacteristic in service.characteristics!{
            
            if newChar.properties.rawValue == CBCharacteristicProperties.notify.rawValue{
                peripheral.setNotifyValue(true, for: newChar)
                
            }
            else {
                if peripheral == ppgPeripheral{
                    self.ppgChar = newChar
//                    ppgReady!()
//                    self.write()
                    print("------------PPG Ready -------------")
                   
                }
            }
        }
        
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // print("Discover services for peripheralIdentifier: \(peripheral.identifier.uuidString)")
        
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
//            let service = foundServices[1]
//            peripheral.discoverCharacteristics(nil, for: service)
            
            for service in foundServices{
                if service.uuid == uartUUID{
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("write success")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("vals")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if peripheral == ppgPeripheral{
            
            if let data = characteristic.value{
                
                update!(data)
                print("ppg val")
                
            }
        }
    }
    
}
