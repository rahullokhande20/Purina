//
//  StatusViewController.swift
//  Soniphi
//
//  Created by Sai Dammu on 12/7/20.
//  Copyright © 2020 SaiDammu. All rights reserved.
//

import UIKit
import CoreBluetooth
import MBProgressHUD


class StatusViewController: UIViewController {
    
    
    @IBOutlet weak var hardwareLabel : UILabel!
    @IBOutlet weak var firmwareLabel : UILabel!
    @IBOutlet weak var systemStatusLabel : UILabel!
    @IBOutlet weak var systemSerialLabel : UILabel!
    
    var peripheral : CBPeripheral!
    var char : CBCharacteristic!
    
    var timer : Timer!
    
    var nextPacket = "Hardware"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Device Info"
        
        peripheral = singlton.shared.peripheral
        peripheral.delegate = self
        peripheral?.discoverServices(nil)
//
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
            self.sendHardwarePacket()
        }
        timer = Timer(timeInterval: 10.0, repeats: true) { _ in
            self.goBackHome()
        }
        systemStatusLabel.isHidden = true
        systemSerialLabel.isHidden = true
        
    }
    override func viewDidAppear(_ animated: Bool) {
        // MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    
    @objc func goBackHome(){
        
        let alert = UIAlertController(title: "Error", message: "Please try again later.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func hexStringtoAscii(_ hexString : String) -> String {
        
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matches(in: hexString, options: [], range: NSMakeRange(0, nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        return String(characters)
    }
    
    
    func sendHardwarePacket() {
        
        if let writeData = Utils.sharedInst()?.hardwareStatus(){
           
            peripheral.writeValue(writeData, for: char, type: CBCharacteristicWriteType.withoutResponse)
//            peripheral.discoverServices(nil)
//            peripheral.setNotifyValue(true, for: char)
            print("Resp:hardware packet \(writeData.hexDescription)")
        }
        
    }
    
    func sendFirmwarePacket() {
        
        if let writeData = Utils.sharedInst()?.firmwareStatus(){
           
            peripheral.writeValue(writeData, for: char, type: CBCharacteristicWriteType.withoutResponse)
           // peripheral.discoverServices(nil)
           // peripheral.setNotifyValue(true, for: char)
            print("Resp:firmware packet \(writeData.hexDescription)")
            
        }
        
    }
    func sendSystemStatusPacket() {
        
        if let writeData = Utils.sharedInst()?.systemStatus(){
           
            peripheral.writeValue(writeData, for: char, type: CBCharacteristicWriteType.withoutResponse)
            //peripheral.discoverServices(nil)
           // peripheral.setNotifyValue(true, for: char)
            print("Resp:system status packet \(writeData.hexDescription)")
            
        }
    }
    
    func sendSystemSerialPacket() {
        
        if let writeData = Utils.sharedInst()?.systemSerial(){
           
            peripheral.writeValue(writeData, for: char, type: CBCharacteristicWriteType.withResponse)
           // peripheral.discoverServices(nil)
           // peripheral.setNotifyValue(true, for: char)
            print("Resp:system serial packet \(writeData.hexDescription)")
            
        }
        
    }
    
}

extension String {
    func reverse() -> String  { return self.reduce("") { "\($1)" + $0 } }
}

extension StatusViewController : CBPeripheralDelegate{
    
    //MARK: deleagte
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            print("services111 \(foundServices)")
            
            let service = foundServices[0]
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover char")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        print("char117 \(service.characteristics)")
        
        
        print("discover char")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        print("char118 \(service.characteristics)")
        
        for newChar: CBCharacteristic in service.characteristics!{
            print("ccb \(newChar.properties.rawValue)")
            // MBProgressHUD.hide(for: self.view, animated: true)
            
            //  if newChar.value != nil{
            
            if newChar.properties == CBCharacteristicProperties.notify{
                peripheral.setNotifyValue(true, for: newChar)
                peripheral.setNotifyValue(true, for: newChar)
            }
            else {
                
                self.char = newChar
                
            }
            
        }
       
    }
     
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.timer.invalidate()
        MBProgressHUD.hide(for: self.view, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.nextPacket == "Hardware"{
            
                print("Resp: hardware  : \(characteristic.value?.hexDescription ?? "")")
                self?.nextPacket = "Firmware"
                
                let hexString = characteristic.value?.hexDescription.separate(every: 2, with: " ")
                let hexArray = hexString?.components(separatedBy: " ")
                if let respArray = hexArray{
                    var respArr = respArray.dropFirst(10)
                    respArr = respArr.dropLast(1)
                    
                    
                    let valuesArr = NSMutableArray()
                    
                    for i in respArr{
                        valuesArr.add(i)
                        let val = self?.hexStringtoAscii(i as? String ?? "")
                   
                    }
                    
                    for i in (2..<4).reversed(){
                       // if let val = UInt(i,radix: 16){
                        let val = self?.hexStringtoAscii(valuesArr[i] as? String ?? "")
                        self?.hardwareLabel.text = "\(self?.hardwareLabel.text ?? "") \(val ?? "")"
                       // }
                    }
                    
                    for i in (0..<2).reversed(){
                         if let val = UInt(valuesArr[i] as? String ?? "",radix: 16){
                       // let val = hexStringtoAscii(valuesArr[i] as? String ?? "")
                       // hardwareLabel.text = "\(hardwareLabel.text ?? "") \(val)"
                            if i%2==0{
                                self?.hardwareLabel.text = "\(self?.hardwareLabel.text ?? "").\(val)"
                            }else{
                                self?.hardwareLabel.text = "\(self?.hardwareLabel.text ?? "") \(val)"
                            }
                         }
                    }
                    self?.hardwareLabel.text = "Hardware :\(self?.hardwareLabel.text ?? "")"
                }
                
                self?.sendFirmwarePacket()
                
            }
            else if self?.nextPacket == "Firmware"{
                
                print("Resp: firmware  : \(characteristic.value?.hexDescription ?? "")")
                self?.nextPacket = "SystemStatus"
                
                let hexString = characteristic.value?.hexDescription.separate(every: 2, with: " ")
                let hexArray = hexString?.components(separatedBy: " ")
                if let respArray = hexArray{
                    var respArr = respArray.dropFirst(10)
                    respArr = respArr.dropLast(1)
                    
                    
                    let valuesArr = NSMutableArray()
                    
                    for i in respArr{
                        valuesArr.add(i)
                        //let val = hexStringtoAscii(i as? String ?? "")
                   
                    }
                    
                    for i in (2..<4).reversed(){
                       // if let val = UInt(i,radix: 16){
                        let val = self?.hexStringtoAscii(valuesArr[i] as? String ?? "")
                        self?.firmwareLabel.text = "\(self?.firmwareLabel.text ?? "") \(val ?? "")"
                       // }
                    }
                    
                    for i in (0..<2).reversed(){
                         if let val = UInt(valuesArr[i] as? String ?? "",radix: 16){
                       // let val = hexStringtoAscii(valuesArr[i] as? String ?? "")
                       // hardwareLabel.text = "\(hardwareLabel.text ?? "") \(val)"
                            if i%2==0{
                                self?.firmwareLabel.text = "\(self?.firmwareLabel.text ?? "").\(val)"
                            }else{
                                self?.firmwareLabel.text = "\(self?.firmwareLabel.text ?? "") \(val)"
                            }
                         }
                    }
                    self?.firmwareLabel.text = "Firmware :\(self?.firmwareLabel.text ?? "")"
                }
                
                self?.sendSystemStatusPacket()
            }
//            else if nextPacket == "SystemStatus"{
//
//                print("Resp: system status  : \(characteristic.value?.hexDescription ?? "")")
//                nextPacket = "SerialNumber"
//                let hexString = characteristic.value?.hexDescription.separate(every: 2, with: " ")
//                let hexArray = hexString?.components(separatedBy: " ")
//                if let respArray = hexArray{
//                    var respArr = respArray.dropFirst(10)
//                    respArr = respArr.dropLast(1)
//                    for i in respArr{
//                       // if let val = UInt(i,radix: 16){
//                            systemStatusLabel.text = "\(systemStatusLabel.text ?? "") \(i)"
//                       // }
//                    }
//                    systemStatusLabel.text = "System status :\(systemStatusLabel.text ?? "")"
//                }
//
//                sendSystemSerialPacket()
//            }
//            else if nextPacket == "SerialNumber"{
//
//                nextPacket = ""
//                print("Resp: system serial  : \(characteristic.value?.hexDescription ?? "")")
//                let hexString = characteristic.value?.hexDescription.separate(every: 2, with: " ")
//                let hexArray = hexString?.components(separatedBy: " ")
//                if let respArray = hexArray{
//                    var respArr = respArray.dropFirst(10)
//                    respArr = respArr.dropLast(1)
//
//                    for i in respArr{
//                       // if let val = UInt(i,radix: 16){
//                            systemSerialLabel.text = "\(systemSerialLabel.text ?? "") \(i)"
//                       // }
//                    }
//                    systemSerialLabel.text = "System serial :\(systemSerialLabel.text ?? "")"
//                    systemSerialLabel.numberOfLines = 0
//
//                }
//            }
            else{
                if let vw = self?.view{
                    MBProgressHUD.hide(for: vw, animated: true)
                    print("Resp: unknown : \(characteristic.value?.hexDescription ?? "")")
                }
            }
        }

    }
    
}

