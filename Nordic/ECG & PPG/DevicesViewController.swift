//
//  DevicesViewController.swift
//  LD-Sana
//
//  Created by Sai Dammu on 5/11/21.
//

import UIKit
import CoreBluetooth
import MBProgressHUD

class DevicesViewController: UIViewController {
    
    var centralManager: CBCentralManager?
    var peripherals = [NearByPeripheral]()
    var tableView :UITableView!
    var selectedPeripheral : CBPeripheral!
    var discButton : UIButton!
    var delegate : ScannerDelegate?
    var isEcgPPG : Bool!
    var ecgPeripheral : CBPeripheral!
    var ppgPeripheral : CBPeripheral!
    let ecgIdentifier = "4CC6DC74-1173-578A-F3A6-15E18A315C1F"
    var ppgIdentifier = "E7DA26EC-DCF7-A02A-5807-AD654D18912D"
    
    
    @objc func buttonAction(){
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = .white
        
        if isEcgPPG{
            let button = UIButton()
            button.frame = CGRect(x: self.view.frame.width-100, y: 10, width: 80, height: 40)
            button.setTitle("Dismiss", for: .normal)
            button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            button.setTitleColor(.black, for: .normal)
            self.view.addSubview(button)
        }
        
       
        var dic : [String : Any] = Dictionary()
        dic[CBCentralManagerOptionShowPowerAlertKey] = false
        centralManager = CBCentralManager(delegate: self, queue: nil, options: dic)
        singlton.shared.centralManager = centralManager!
        
        tableView = UITableView()
        if isEcgPPG{
            tableView.frame = CGRect(x: 0, y: 50, width: self.view.frame.size.width, height: self.view.frame.size.height-60)
        }else{
            tableView.frame = self.view.bounds
            
        }
        tableView.delegate = self
        tableView.dataSource = self
       
        self.view.addSubview(tableView)
        tableView.register(DeviceCell.self, forCellReuseIdentifier: "cell")
        
      
    }

    
}

extension DevicesViewController : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DeviceCell
        cell.nameLabel.text = peripherals[indexPath.row].peripheral.name ?? ""
        cell.strengthLabel.text = "\(peripherals[indexPath.row].rssi ?? 0)"
        
        
        
        let RSSI = peripherals[indexPath.row].rssi
        
        // The signal strength img icon
        switch labs(RSSI as! Int) {
        case 0...40:
            cell.strengthImageView.image = UIImage(named: "signal_strength_5")
        case 41...53:
            cell.strengthImageView.image = UIImage(named: "signal_strength_4")
        case 54...65:
            cell.strengthImageView.image = UIImage(named: "signal_strength_3")
        case 66...77:
            cell.strengthImageView.image = UIImage(named: "signal_strength_2")
        case 77...89:
            cell.strengthImageView.image = UIImage(named: "signal_strength_1")
        default:
            cell.strengthImageView.image = UIImage(named: "signal_strength_0")
        }
        
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MBProgressHUD.showAdded(to: view, animated: true)
        centralManager?.stopScan()
        selectedPeripheral = peripherals[indexPath.row].peripheral
        
        if isEcgPPG{
            
            if ppgPeripheral == nil{
            
                ppgPeripheral = selectedPeripheral
               
            }else{
                ecgPeripheral = selectedPeripheral
            }
            
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            ecgPpgDelegate()
        
        }
        selectedPeripheral.delegate = self
        
        centralManager?.connect(selectedPeripheral, options: nil)
        
    }
    
}

extension DevicesViewController: CBCentralManagerDelegate,CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if !peripherals.contains(where: {$0.peripheral.name == peripheral.name}){
            let peri = NearByPeripheral(peripheral: peripheral, rssi: RSSI)
            peripherals.append(peri)
        }else{
            
            if let index = peripherals.firstIndex(where: {$0.peripheral.name == peripheral.name}){
                peripherals[index].rssi = RSSI
                print("reloading")
            }
        }
        
        tableView.reloadData()
        
    }
    
    
    func bleDidDisconnectPeripheral(_ aPeripheral: CBPeripheral!, error: Error!) {
        print("did disc");
    }
  
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
    }
    
    func ecgPpgDelegate(){
        if ecgPeripheral != nil && ppgPeripheral != nil{
            self.delegate?.centralManagerDidSelectPeripheral!(withManager: centralManager!, ecgPeripheral: ecgPeripheral, ppgPeripheral: ppgPeripheral)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGPeripheral"), object: nil, userInfo: ["peri": ppgPeripheral!])
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
     //   print("Peripheral Connected with identifier: \(peripheral.identifier.uuidString)")
        MBProgressHUD.hide(for: self.view, animated: true)
        singlton.shared.centralManager = central
        singlton.shared.peripheral = peripheral
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Connected"), object: nil, userInfo: nil)
        
        
        if isEcgPPG{
            ecgPpgDelegate()
        }else{
            self.delegate?.centralManagerDidSelectPeripheral?(withManager: centralManager!, andPeripheral: selectedPeripheral)
            self.dismiss(animated: true, completion: nil)
        }
        
     
       // self.dismiss(animated: true, completion: nil)
       /*
        discButton.isHidden = false
        
        let dvc = ServicesViewController()
        dvc.peripheral = peripheral
        self.navigationController?.pushViewController(dvc, animated: true)
 */
    }
}

