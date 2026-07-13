//
//  Line2.swift
//  Purina
//
//  Created by Sai Dammu on 1/12/22.
//

import Foundation
import CoreBluetooth

class Line2 : NSObject, CBPeripheralDelegate{
    
    var peripheral2 : CBPeripheral!
    var char : CBCharacteristic!
    var update : ((Data) -> () )?
    let uuid = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override init() {
        super.init()
        
    }
    
    func writeGain(writeGainSelected:String){
        let value1Int = UInt8(writeGainSelected, radix:16)
        let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
        
        peripheral2.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        peripheral2.setNotifyValue(true, for: char)
      
       
    }
    
    
    func readGain(){
        
        let writeData = Utils.sharedInst()?.sendReadGainLND()
        peripheral2.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        peripheral2.setNotifyValue(true, for: char)
        
    }
    
    func discvoer(peripheral:CBPeripheral){
       
        self.peripheral2 = peripheral
        self.peripheral2.delegate = self
        self.peripheral2.discoverServices(nil)
        print("peri 2 ", self.peripheral2.name ?? "")
        print("peri 2 conn ", self.peripheral2.state)
    }
    
    func stop(){
        
        let writeData = Utils.sharedInst()?.stopECGPPGGraph()
        peripheral2.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func start(){
       
        let writeData = Utils.sharedInst()?.startECGPPGGraph()
        peripheral2.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
        
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
                 if peripheral2 == peripheral{
                    self.char = newChar
                  
                    print("------------P2 Ready -------------")
                }
                
            }
        }
        
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            for service in foundServices{
                if service.uuid == uuid{
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
        print("vals u")
        
        if let data = characteristic.value{
           
            update?(data)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Line2Update"), object: nil, userInfo: ["data": data])

            
        }
        
    }
    
}


