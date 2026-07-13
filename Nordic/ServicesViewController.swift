//
//  ServicesViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 4/14/21.

import UIKit
import CoreBluetooth
import MBProgressHUD

class ServicesViewController: UIViewController,CBPeripheralDelegate {
    
    var peripheral : CBPeripheral!
    var services = [CBService]()
    var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = "Services"
        
        tableView = UITableView()
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // print("Discover services for peripheralIdentifier: \(peripheral.identifier.uuidString)")
        
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            services = foundServices
            tableView.reloadData()
        }
        
        // services = peripheral.services!
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        // for service in peripheral.services ?? [] {
        //   print("serv \(service)")
        /*if service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"){
         peripheral.discoverCharacteristics(nil, for: service)
         }
         */
        // }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover char")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        for newChar: CBCharacteristic in service.characteristics!{
            print("ccb \(newChar.properties.rawValue)")
            // MBProgressHUD.hide(for: self.view, animated: true)
            //  if newChar.value != nil{
            
            if newChar.properties.rawValue == 18{
                print("CB 18")
                peripheral.setNotifyValue(true, for: newChar)
                MBProgressHUD.hide(for: self.view, animated: true)
                let vc = DetailsViewController()
                vc.peripheral = peripheral
                vc.char = newChar
                self.navigationController?.pushViewController(vc, animated: true)
                break
            }
            if newChar.properties.rawValue == 12 || newChar.properties.rawValue == 16{
                print("CB 12")
                peripheral.setNotifyValue(true, for: newChar)
                MBProgressHUD.hide(for: self.view, animated: true)
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "LNDViewController") as! LNDViewController
                vc.peripheral = peripheral
                vc.char = newChar
                self.navigationController?.pushViewController(vc, animated: true)
                break
            }
            
            else if newChar.properties == CBCharacteristicProperties.read{
                print("CB read")
                
                 peripheral.setNotifyValue(true, for: newChar)
                MBProgressHUD.hide(for: self.view, animated: true)
                
                let vc = DetailsViewController()
                vc.peripheral = peripheral
                vc.char = newChar
                self.navigationController?.pushViewController(vc, animated: true)
                break
            }
            else if (newChar.properties == CBCharacteristicProperties.read) && (newChar.properties == CBCharacteristicProperties.notify){
                print("CB read notify")
            }
            else if newChar.properties == CBCharacteristicProperties.write{
                print("CB write")
            }
            else if newChar.properties == CBCharacteristicProperties.writeWithoutResponse{
                print("CB write wo resp")
            }
            else if newChar.properties == CBCharacteristicProperties.notify{
                print("CB Notify")
                peripheral.setNotifyValue(true, for: newChar)
                MBProgressHUD.hide(for: self.view, animated: true)
                
                let vc = DetailsViewController()
                vc.peripheral = peripheral
                vc.char = newChar
                self.navigationController?.pushViewController(vc, animated: true)
                break
                // peripheral.setNotifyValue(true, for: newChar)
            }
            else if newChar.properties == CBCharacteristicProperties.authenticatedSignedWrites{
                print("CB authenticatedSignedWrites")
            }
            else if newChar.properties == CBCharacteristicProperties.extendedProperties{
                print("CB extendedProperties")
            }
            else if newChar.properties == CBCharacteristicProperties.notifyEncryptionRequired{
                print("CB notifyEncryptionRequired")
            }
            else if newChar.properties == CBCharacteristicProperties.indicateEncryptionRequired{
                print("CB indicateEncryptionRequired")
            }
            print("\(newChar.properties)")
            
        }
        // print("Found \(service.characteristics!.count) characteristics!: \(service.characteristics)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let data = characteristic.value{
            print("value recieved ")
            let hexString = data.hexDescription.separate(every: 4, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            NotificationCenter.default.post(name: Notification.Name("NotifyValue"), object: hexArray)
            
        }else {
            print("value recieved nil")
        }
        
    }
    
}

extension ServicesViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let service = services[indexPath.row].uuid.uuidString
        
        if service == "180D"{
            cell?.textLabel?.text = "180D -- Heart rate"
        }
        else if service == "180F"{
            cell?.textLabel?.text = "180F -- Battery"
        }
        else if service == "180A"{
            cell?.textLabel?.text = "180A -- Primary service"
        }
        else {
            cell?.textLabel?.text = "\(service) -- UART"
            cell?.textLabel?.numberOfLines = 0
        }
        
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let service = services[indexPath.row]
        peripheral.delegate = self
        peripheral.discoverCharacteristics(nil, for: service)
        
    }
    
}


