//
//  RightPCBViewController.swift
//  Soniphi
//
//  Created by Sai Dammu on 7/10/20.
//  Copyright © 2020 SaiDammu. All rights reserved.
//


import UIKit
import CoreBluetooth
import MBProgressHUD

class RightPCBViewController: UIViewController,CBPeripheralDelegate {
    
    var alrController : UIAlertController!
    var characteristic : CBCharacteristic!
    @IBOutlet weak var bootloadTableView: UITableView!
    @IBOutlet weak var binFileLabel: UILabel!
    //@IBOutlet weak var resetSpinner: UIActivityIndicatorView!
    //@IBOutlet weak var bootloadSpinner: UIActivityIndicatorView!
    
    let strQppUpdateDataRateDynNoti = "qppUpdateDataRateDynamicNotification"
    let strQppUpdateStateForCharNoti = "bleQppUpdateStateForCharNoti"
    let strQppScanPeriEndNoti = "qppScanPeripherals EndNotification"
    let strQppUpdateDataRateAvgNoti = "qppUpdateDataRateAverageNotification"
    
    let UUID_QPP_SVC =  "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    
    var qppPeriLaser : CBPeripheral!
    
    var string255 = String()
    var loadCount = 0
    var timerCount = 0
    var isCompleteBootLoadRight = false
    let blePeriDiscoveredNoti = "ble-PeriDiscoveredNoti"
    let didQppEnableConfirmForAppNoti = "str-didQppEnableConfirmForApp-Noti"
    let keyPeriInQppEnableConfirmed = "key-PeriInQppEnableConfirmForApp"
    let keyWrCharInQpp = "key-WrCharInQppEnableConfirmForApp"
    let keyNtfCharInQpp = "key-NtfCharInQppEnableConfirmForApp"
    
    let keyConfirmStatus = "key-StatusInQppEnableConfirmForApp"
    
    var deviceVC = DevicesViewController()
        
    var buttonActionString = ""
    
    var loadProgressHud : MBProgressHUD!
    
    //var deviceVC = DevicesViewController()
    enum qppCentralState {
        case QPP_CENT_IDLE  // scan
        case QPP_CENT_SCANNING
        case QPP_CENT_SCANNED
        case QPP_CENT_CONNECTING
        case QPP_CENT_CONNECTED
        case QPP_CENT_DISCONNECTING
        case QPP_CENT_DISCONNECTED
        case QPP_CENT_RETRIEVING
        case QPP_CENT_RETRIEVED
        case QPP_CENT_SENDING        /// sending package
        case QPP_CENT_ERROR
    }
    var qppCentState:qppCentralState! = nil
    
    var qppWrData = [Int8]()
    var flagOnePeriScanned = Bool()
    
    
    var hexArr : [String]!
    var binFileNames : NSMutableArray!
    var pickerView:UIPickerView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Biometric PCB"
            
        singlton.shared.peripheral.delegate = self
        
        bootloadTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
      
        let resetButton = UIButton(type: .custom)
        resetButton.tag = 1
        resetButton.setTitle("System Reset", for: .normal)
        resetButton.setTitleColor(UIColor.white, for: .normal)
        resetButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        resetButton.addTarget(self, action: #selector(self.systemResetAction), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: resetButton)
        self.navigationItem.rightBarButtonItem = item1
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.parent?.title = "Biometric PCB"
        
    }
    
    
    
    
    
    @objc func SystemReset(_ notification : NotificationCenter){
        
        MBProgressHUD.hide(for: self.view, animated: true)
        print("notification \(notification)")
        let dict = notification.value(forKey: "userInfo") as! NSDictionary
        print("reset : \(dict.value(forKey: "name"))%")
        
        if isCompleteBootLoadRight{
            
            let alert = UIAlertController(title: "Success", message: "Systemreset successful. Please re-connect after 2 minutes", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
                DispatchQueue.main.async {
                    print("go home")
                    self.navigationController?.popViewController(animated: true)
                }
                
            }))
            self.present(alert, animated: true, completion: nil)
            
        }else{
            
            let alert = UIAlertController(title: "Success", message: "System reset successful.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    
    
    @IBAction func chooseBinAction(_ sender: Any) {
        
        
        var documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            print(directoryContents)
            
            // if you want to filter the directory contents you can do like this:
            let binFiles = directoryContents.filter{ $0.pathExtension == "bin" }
            print("bin urls:",binFiles)
            
            // let ppPath = documentsUrl.appendPathComponent("\(mp3Files[0])")
            
            let allBinFiles = binFiles.map{ $0.deletingPathExtension().lastPathComponent } as? NSArray ?? NSArray()
            print("bin list:", binFileNames)
            
            binFileNames = NSMutableArray()
            for name in allBinFiles{
                
              //  if (name as! String).prefix(5) == "Right"{
                    binFileNames.add(name)
              //  }
                
            }
            
            
            if binFileNames.count>0{
                
                alrController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                
                let margin:CGFloat = 8.0
                let rect = CGRect(x: margin, y: margin, width: alrController.view.bounds.size.width - margin * 4.0, height: 100.0)
                let tableView = UITableView(frame: rect)
                tableView.delegate = self
                tableView.dataSource = self
                tableView.tag = 1
                tableView.backgroundColor = UIColor.lightGray
                tableView.register(UITableViewCell.self, forCellReuseIdentifier:
                                    "cell")
                alrController.view.addSubview(tableView)
                
                // let somethingAction = UIAlertAction(title: "Load Bin", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in print("something")})
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
                
                //  alrController.addAction(somethingAction)
                alrController.addAction(cancelAction)
                
                self.present(alrController, animated: true, completion:{})
                
                
                
                
                /*
                 
                 
                 self.pickerView = UIPickerView()
                 // self.pickerView.frame = CGRect(x: 0, y: self.view.frame.size.height-250, width: self.view.frame.size.height, height: 250)
                 self.pickerView.delegate = self
                 self.pickerView.dataSource = self
                 self.pickerView.backgroundColor = UIColor.lightGray
                 self.view.addSubview(pickerView)
                 
                 
                 self.pickerView.snp.makeConstraints { (make) in
                 make.left.right.bottom.equalTo(self.view)
                 make.height.equalTo(200)
                 }
                 */
                
            }
            
            
            
        } catch {
            print(error)
        }
        
        
    }
    
    
    @objc func systemResetAction(_ sender: Any) {
        
        // MBProgressHUD.showAdded(to: self.view, animated: true)
        
        
        
    }
    
    @IBAction func initiateButtonAction(_ sender: Any)
    {
        
    }
    
    @IBAction func loadButtonAction(_ sender: Any) {
        
        buttonActionString = "Load"
        
        
    }
    
    @IBAction func completeButtonAction(_ sender: Any)
    {
        
    }
    
    @IBAction func bootLoadAction(_ sender: Any) {
        
        loadProgressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadProgressHud.mode = .determinateHorizontalBar
        loadProgressHud.label.text = "0% completed"
        
        // s1: write data
        // s2: set notify
        //  qppApi.qppSendData(aPeri: devInfo.qppPeri!, qppData: writeData! as NSData, writeType: .withResponse)
        //  qppApi.qppEnableNotify(aPeripheral: devInfo.qppPeri, ntfChar: devInfo.aQppNtfChar, enable: true)
        
        if let peripheral = singlton.shared.peripheral{
            
            //Start command
            
            let startData = Utils.sharedInst()?.intiateBootloadRight()
            peripheral.writeValue(startData!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            
        }
    }
    func loadHexString(){
        
        let n = Int(loadCount)
        let serialString = String(format:"%04X", n)
        let serialArr = "\(serialString)".components(withLength: 02)
        
        var value = UInt()
        for i in serialArr{
            let hexInt =  UInt(i, radix: 16)
            value = value+hexInt!
        }
        
        if let peripheral = singlton.shared.peripheral {
            let writeData = Utils.sharedInst()?.loadBootloadRight(hexArr[loadCount].components(withLength: 2), withstring255: hexArr[loadCount], packetCountHexTotal: Int32(value), packetCount:Int32(Int(loadCount)))
            peripheral.writeValue(writeData!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
        }
        loadCount += 1
        
    }
    func completeBin(){
        //Stop command
      //  MBProgressHUD.hide(for: self.view, animated: true)
        
   
        let stopData = Utils.sharedInst()?.completeBootloadRight()
        if let peripheral = singlton.shared.peripheral{
            peripheral.writeValue(stopData!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
        }
        print("writing hex completed")
        
        let inputAlert = UIAlertController(title: "Bootload", message: "Bootload completed, Please reset system", preferredStyle: UIAlertController.Style.alert)
        
        inputAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (make) in
            self.loadProgressHud.hide(animated: true)
        }))
        
        self.present(inputAlert, animated: true, completion: nil)
        
        
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("write success")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("vals")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("vall")
        
        if let data = characteristic.value{
            print("value recieved ")
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            if hexArray.count<4 { return }
            if hexArray[4] == "00"{
                let oneValue = 100.00/Double(hexArr.count)
                let progressValue = Float((oneValue*Double(loadCount))/100.00)
                loadProgressHud.progress = progressValue
                let percString = String(format: "%.0f", progressValue*100)
                loadProgressHud.label.text = "\(percString)% completed"
                
                if loadCount < hexArr.count{
                    loadHexString()
                }else if loadCount == hexArr.count{
                    completeBin()
                    loadCount += 1
                }
                
            }else{
                let alert = UIAlertController(title: "Error", message: "Ack error code - \(hexArray[4])", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            // NotificationCenter.default.post(name: Notification.Name("NotifyValue"), object: hexArray)
            print("value recieved \(hexString)")
        }else {
            print("value recieved nil")
        }
        
    }
    
}

extension RightPCBViewController : UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView.tag == 1{
            return 25
        }
        
        return 225
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if tableView.tag == 1{
            return binFileNames.count
        }else{
            
            if hexArr != nil{
                return hexArr.count
            }
            
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        
        if tableView.tag == 1{
            cell?.textLabel?.text = "\(binFileNames[indexPath.row])"
            cell?.backgroundColor = .lightGray
        }else{
            cell?.textLabel?.text = "0X\(hexArr[indexPath.row])"
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.sizeToFit()
        }
        return cell!
        
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.tag == 1{
            
            
            alrController.dismiss(animated: true, completion: nil)
            
            
            print("started reading bin")
            
            var archieveData = Data()
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let filepath = documents.strings(byAppendingPaths: ["\(binFileNames.object(at: indexPath.row)).bin"])[0]
            
            
            binFileLabel.text = "\(binFileNames.object(at: indexPath.row)).bin"
            binFileLabel.numberOfLines = 0
            binFileLabel.sizeToFit()
            let data = FileManager.default.contents(atPath: filepath);
            if #available(iOS 11.0, *) {
                archieveData = try! NSKeyedArchiver.archivedData(withRootObject: data!, requiringSecureCoding: false)
                print("bin the end ")
            } else {
                // Fallback on earlier versions
                archieveData = NSKeyedArchiver.archivedData(withRootObject: data!) as Data
                
            }
            
            let hexStringRaw = (archieveData.hexDescription)
            let index = hexStringRaw.components(separatedBy: "00500020")
            let trimLength = (index[0] ).count
            var hexString = (archieveData.hexDescription).dropFirst(trimLength)
            // hexString = hexString.dropLast(116)
            hexArr = "\(hexString)".components(withLength: 128)
            
            self.bootloadTableView.reloadData()
            
            
        }else{
            string255 = hexArr[indexPath.row]
        }
        
        
    }
    
    
}




extension RightPCBViewController : UIPickerViewDelegate,UIPickerViewDataSource{
    
    //MARK:- PickerView Delegate & DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return binFileNames.count
    }
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(50.0)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel : UILabel
        if let label = view as? UILabel {
            pickerLabel = label
        } else {
            pickerLabel = UILabel()
            pickerLabel.textColor = UIColor.black
            if  pickerLabel.effectiveUserInterfaceLayoutDirection == .rightToLeft {
                pickerLabel.textAlignment = NSTextAlignment.left
                
            }
        }
        pickerLabel.text = binFileNames.object(at: row) as? String ?? "No File"
        pickerLabel.sizeToFit()
        pickerLabel.textAlignment = .left
        return pickerLabel
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        
        return binFileNames.object(at: row) as? String ?? "No File"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //  self.txt_pickUpData.text = pickerData[row]
        
        /*
         let loadingNotification = MBProgressHUD.showAdded(to: self, animated: true)
         loadingNotification.mode = MBProgressHUDMode.indeterminate
         loadingNotification.show()
         */
        
        print("started reading bin")
        
        var archieveData = Data()
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filepath = documents.strings(byAppendingPaths: ["\(binFileNames.object(at: row)).bin"])[0]
        
        
        
        let data = FileManager.default.contents(atPath: filepath);
        if #available(iOS 11.0, *) {
            archieveData = try! NSKeyedArchiver.archivedData(withRootObject: data!, requiringSecureCoding: false)
            print("bin the end ")
        } else {
            // Fallback on earlier versions
            archieveData = NSKeyedArchiver.archivedData(withRootObject: data!) as Data
            
            
        }
        
        let hexStringRaw = (archieveData.hexDescription)
        let index = hexStringRaw.components(separatedBy: "00500020")
        let trimLength = (index[0] ).count
        var hexString = (archieveData.hexDescription).dropFirst(trimLength)
        
        hexString = hexString.dropLast(116)
        hexArr = "\(hexString)".components(withLength: 512)
        
        self.bootloadTableView.isHidden = false
        self.bootloadTableView.reloadData()
        self.pickerView.removeFromSuperview()
        
    }
    
}

extension String {
    func components(withLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}
