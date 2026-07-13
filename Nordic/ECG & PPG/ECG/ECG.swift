//
//  ECG.swift
//  HeartMath
//
//  Created by Sai Dammu on 11/11/21.
//

import Foundation
import CoreBluetooth

class ECG : NSObject, CBPeripheralDelegate{
    
    var ecgPeripheral : CBPeripheral!
    var ecgChar : CBCharacteristic!
    var update : ((Data) -> () )?
    var ecgReady : ( (CBCharacteristic) -> () )?
    let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    var updateRead : ((String) -> () )?
    var updateGain : (() -> () )?
    override init() {
        super.init()
        
    }
    
    func writeGain(writeGainSelected:String, channel:Bool){
        
        if channel{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let response = Utils.sharedInst()?.sendWriteGainChannel(Int32(value1Int!))
            ecgPeripheral.writeValue(response!, for: ecgChar, type: CBCharacteristicWriteType.withoutResponse)
            ecgPeripheral.setNotifyValue(true, for: ecgChar)
        }else{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
            
            ecgPeripheral.writeValue(responseDict!["Data"] as! Data, for: ecgChar, type: CBCharacteristicWriteType.withoutResponse)
            ecgPeripheral.setNotifyValue(true, for: ecgChar)
        }
        
    }
    
    
    func readGain(channel:Bool){
        
        if channel{
            let writeData = Utils.sharedInst()?.sendreadGainChannel()
            ecgPeripheral.writeValue(writeData!, for: ecgChar, type: CBCharacteristicWriteType.withoutResponse)
            ecgPeripheral.setNotifyValue(true, for: ecgChar)
        }else{
            let writeData = Utils.sharedInst()?.sendReadGainLND()
            ecgPeripheral.writeValue(writeData!, for: ecgChar, type: CBCharacteristicWriteType.withoutResponse)
            ecgPeripheral.setNotifyValue(true, for: ecgChar)
        }
        
    }
    
    func discvoer(ecgPeripheral:CBPeripheral){
        print("vals d")
        self.ecgPeripheral = ecgPeripheral
        self.ecgPeripheral.delegate = self
        self.ecgPeripheral.discoverServices(nil)
    }
    
    func stop(){
        
        let writeData = Utils.sharedInst()?.stopECGPPGGraph()
        ecgPeripheral.writeValue(writeData!, for: ecgChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func start(){
       
        let writeData = Utils.sharedInst()?.startECGPPGGraph()
        ecgPeripheral.writeValue(writeData!, for: ecgChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("vals u")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
       
        for newChar: CBCharacteristic in service.characteristics!{
            
            if newChar.properties.rawValue == CBCharacteristicProperties.notify.rawValue{
                peripheral.setNotifyValue(true, for: newChar)
                
            }
            else {
                 if peripheral == ecgPeripheral{
                    self.ecgChar = newChar
                    ecgReady!(self.ecgChar)

                    print("------------ECG Ready -------------")
                }
                
            }
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // print("Discover services for peripheralIdentifier: \(peripheral.identifier.uuidString)")
        print("vals s")
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
           
//            let service = foundServices[0]
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
        print("vals u")
        
        if let data = characteristic.value{
            
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            print("ECG x",hexString)
            
            
           //ab 03 a1 b3 00 a9
            
            if hexArray.count == 6{
                if hexArray[4] == "00"{
                    
                    updateGain?()
                }
            }
            
            if hexArray.count == 7{
                if hexArray[4] == "01"{
                    updateRead?(hexArray[5])
                }
            }
            
            update!(data)
            
        }
        
    }
    
}
