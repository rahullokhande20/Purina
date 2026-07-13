//
//  Line1.swift
//  Purina
//
//  Created by Sai Dammu on 1/11/22.
//



import Foundation
import CoreBluetooth

class Line1 : NSObject, CBPeripheralDelegate{
    
    var peripheral : CBPeripheral!
    var char : CBCharacteristic!
    var update : ((Data,CBCharacteristic) -> () )?
    var updateRead : ((String) -> () )?
    var isPeripheralReady : ( () -> () )?
    let uuid = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override init() {
        super.init()
        
    }
    
    func writeGain(writeGainSelected:String){
        let value1Int = UInt8(writeGainSelected, radix:16)
        let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
        
        peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        peripheral.setNotifyValue(true, for: char)
      
       
    }
    
    
    func readGain(){
        
        let writeData = Utils.sharedInst()?.sendReadGainLND()
        peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        peripheral.setNotifyValue(true, for: char)
        
    }
    
    func discvoer(peripheral:CBPeripheral){
       
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
        print("peri 1 ", self.peripheral.name ?? "")
        print("peri 1 conn ", self.peripheral.state)
    }
    
    func stop(){
        
        let writeData = Utils.sharedInst()?.stopECGPPGGraph()
        peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func start(){
       
        let writeData = Utils.sharedInst()?.startECGPPGGraph()
        peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
        
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
                 if peripheral == peripheral{
                    self.char = newChar
                    isPeripheralReady!()
                    print("------------P1 Ready -------------")
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
           
            
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            
            if hexArray.count == 7{
                if hexArray[4] == "01"{
                    updateRead?(hexArray[5])
                }
            }
           
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Line1Update"), object: nil, userInfo: ["data": data, "char": char!])

            update!(data, char)
            
        }
        
    }
    
}


