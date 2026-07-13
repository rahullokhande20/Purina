//
//  TestingViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 4/30/21.
//

import UIKit
import CoreBluetooth
import MRHexKeyboard

class TestingViewController: UIViewController,CBPeripheralDelegate {

    @IBOutlet weak var inputTextfield : UITextField!
    @IBOutlet weak var ackLabel : UILabel!
    
    var peripheral : CBPeripheral!
    var characteristic : CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Testing"
        // Do any additional setup after loading the view.
        
        inputTextfield.inputView = MRHexKeyboard()
 
        peripheral = singlton.shared.peripheral
        peripheral.delegate = self
        peripheral?.discoverServices(nil)
        sendAction(UIButton())
    }
    

    @IBAction func sendAction(_ sender:Any){
            
        if inputTextfield.text!.count>0{
           // peripheral.setNotifyValue(true, for: char)
            let hexData = Data(hex: inputTextfield.text!)!
            
                peripheral.writeValue(hexData, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                peripheral.setNotifyValue(true, for: characteristic)
            peripheral.discoverServices(nil)
                print("write ..!")
                    
        }
    }
    
    //MARK: deleagte
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // print("Discover services for peripheralIdentifier: \(peripheral.identifier.uuidString)")
        
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            print("services111 \(foundServices)")
           
            let service = foundServices[1]
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
        // let value = characteristic.value?.hexDescription
        if let data = characteristic.value{
            print("write ack \(data.hexDescription)")
            ackLabel.text = data.hexDescription
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover char")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        print("char116 \(service.characteristics)")
        for newChar: CBCharacteristic in service.characteristics!{
            print("ccb \(newChar.properties.rawValue)")
           // sendAction(UIButton())
            peripheral.setNotifyValue(true, for: characteristic)
            // MBProgressHUD.hide(for: self.view, animated: true)
            
            //  if newChar.value != nil{
            
            if newChar.properties == CBCharacteristicProperties.notify{
                // peripheral.setNotifyValue(true, for: newChar)
            }
            else {
                
                self.characteristic = newChar
                
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("value rec")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
       // print("vall rec \(ch)")
        if let data = characteristic.value{
            ackLabel.text = data.hexDescription
        }
    }
}
