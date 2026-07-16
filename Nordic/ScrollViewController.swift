//
//  ScrollViewController.swift
//  Purina
//
//  Created by Sai Dammu on 2/14/22.
//

import UIKit
import DGCharts
import DropDown
import CoreBluetooth
import MBProgressHUD

class ScrollViewController: UIViewController,ChartViewDelegate, UITextFieldDelegate {
    
    var selectedSwitch : Int!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var activityTextfield: UITextField!
    @IBOutlet weak var writeGainTextfield1 : UITextField!
    @IBOutlet weak var readGainLabel1 : UILabel!
    @IBOutlet weak var graph1: LineChartView!

    @IBOutlet weak var writeGainTextfield2 : UITextField!
    @IBOutlet weak var readGainLabel2 : UILabel!
    
    @IBOutlet weak var fileNameTextfield : UITextField!
    @IBOutlet weak var startTxtButton : UIButton!
    
    @IBOutlet weak var firstPeriNameLabel : UILabel!
    @IBOutlet weak var secondPeriNameLabel : UILabel!
    
    var activityDropdown = DropDown()
    @IBOutlet weak var startStopButton : UIButton!
    var activityArray : [String]!
    
    var previousNo : Int!
    var previousPacket : String!
    var valString = ""
    var char1 : CBCharacteristic!
    var char2 : CBCharacteristic!
    
    var writeGainSelected1 : String!
    var writeGainSelected2 : String!
    
    var connectButton : UIButton!
    var timer : Timer!
    var gainDropdown1 = DropDown()
    var gainDropdown2 = DropDown()
    
    var peripheral1 : CBPeripheral!
    var peripheral2 : CBPeripheral!
    
    var ecg = ECG()
    var isGain = false
    
    var dataString = ""
    var millisecondsGap = 0.1
    
    
    var graph1ValuesArray = NSMutableArray()
    let graph1SecondsArray = NSMutableArray()
    var graph1FileNameString : String!
    let channelArray = [ "01", "02", "03", "04", "05", "06", "07", "08"]
    var isGraphRunning = false
    var activityIndexString:String!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        fileNameTextfield.autocorrectionType = .no
    
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.writtenGain2), name: NSNotification.Name(rawValue: "WrittenGainPPG"), object: nil)
        
        startStopButton.tag = 0
        startStopButton.isUserInteractionEnabled = false
        startStopButton.alpha = 0.3
        
        startTxtButton.tag = 0
        startTxtButton.isUserInteractionEnabled = false
        startTxtButton.alpha = 0.3
        
        connectButton = UIButton(type: .custom)
        connectButton.tag = 1
        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(UIColor.white, for: .normal)
        connectButton.titleLabel?.font = DesignSystem.Typography.button
        // Previously had no background, so white text was invisible against
        // the nav bar. Give it a filled pill matching Home's connect button.
        connectButton.backgroundColor = DesignSystem.Palette.brand
        connectButton.layer.cornerRadius = 15
        connectButton.clipsToBounds = true
        connectButton.contentHorizontalAlignment = .center
        connectButton.frame = CGRect(x: 0, y: 0, width: 110, height: 30)
        connectButton.addTarget(self, action: #selector(self.scanAction), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: connectButton)
        self.navigationItem.rightBarButtonItem = item1
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
        
        let  hexGainArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
        activityArray = ["Laying Down","Sitting","Standing","Walking","Running","Playing","Eating","Drinking", "Other"]
       
        writeGainTextfield1.inputView = UIView()
        gainDropdown1.dataSource = hexGainArray
        gainDropdown1.anchorView = writeGainTextfield1
        gainDropdown1.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            gainDropdown1.hide()
            self.writeGainSelected1 = hexGainArray[index]
            self.writeGainTextfield1.text = hexGainArray[index]
            
        }
        writeGainTextfield1.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(writeGain1DropDownAction))
        writeGainTextfield1.addGestureRecognizer(tap)
        
        
        writeGainTextfield2.inputView = UIView()
        gainDropdown2.dataSource = hexGainArray
        gainDropdown2.anchorView = writeGainTextfield1
        gainDropdown2.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            gainDropdown2.hide()
            self.writeGainSelected2 = hexGainArray[index]
            self.writeGainTextfield2.text = hexGainArray[index]
        }
        writeGainTextfield2.isUserInteractionEnabled = true
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(writeGain2DropDownAction))
        writeGainTextfield2.addGestureRecognizer(tap1)
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.setEcgDatacount()
        }
        
        
        graph1.delegate = self;
        
        graph1.dragEnabled = false
        graph1.setScaleEnabled(true)
        graph1.drawGridBackgroundEnabled = false
        graph1.pinchZoomEnabled = true
        graph1.backgroundColor = .white
        
        graph1.chartDescription.enabled = false
        graph1.dragEnabled = false
        graph1.setScaleEnabled(true)
        graph1.pinchZoomEnabled = false
        graph1.drawGridBackgroundEnabled = false
        graph1.highlightPerDragEnabled = true
        graph1.backgroundColor = .clear
        graph1.legend.enabled = false
        
        let l = graph1.legend
        l.form = .line
        l.font = UIFont.systemFont(ofSize: 10)
        l.textColor = .white
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        
        let xAxis = graph1.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis.labelTextColor = .white
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        
        
        let leftAxis = graph1.leftAxis
        leftAxis.labelTextColor = .red
        leftAxis.axisMinimum = 200
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true;
        leftAxis.drawZeroLineEnabled = false;
        leftAxis.granularityEnabled = true;
        
        let rightAxis = graph1.leftAxis
        rightAxis.labelTextColor = .red
        rightAxis.axisMinimum = 200
        rightAxis.axisMinimum = 0
        rightAxis.drawGridLinesEnabled = true;
        rightAxis.drawZeroLineEnabled = false;
        rightAxis.granularityEnabled = true;
        
        
        
        activityTextfield.inputView = UIView()
        activityDropdown.dataSource = activityArray
        activityDropdown.anchorView = activityTextfield
        activityDropdown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            activityDropdown.hide()
//            self.writeGainSelected = hexGainArray[index]
            activityIndexString = "0\(index)"
            self.activityTextfield.text = activityArray[index]
            
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "activityUpdate"), object: nil, userInfo: ["activity":activityIndexString!])
            
        }
        activityTextfield.isUserInteractionEnabled = true
        let tap11 = UITapGestureRecognizer(target: self, action: #selector(activityDropdownAction))
        activityTextfield.addGestureRecognizer(tap11)
        
        
    }
    
    @objc func activityDropdownAction(){
        activityDropdown.show()
    }
    
    
    //MARAK: Objc funcs
    @objc func writeGain1DropDownAction(){
        gainDropdown1.show()
    }
    @objc func writeGain2DropDownAction(){
        gainDropdown2.show()
    }
    
    @objc func scanAction(){
        
        if connectButton.tag == 1{
            let dvc = DevicesViewController()
            dvc.isEcgPPG = true
            dvc.delegate = self
            self.present(dvc, animated: true, completion: nil)
        }else{
            
            singlton.shared.centralManager.cancelPeripheralConnection(peripheral1)
            singlton.shared.centralManager.cancelPeripheralConnection(peripheral2)
            connectButton.tag = 1
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = DesignSystem.Palette.brand
        }
    }
    
    @objc func backAction(){
        timer.invalidate()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Timer"), object: nil, userInfo: nil)
        self.navigationController?.popViewController(animated: true)
        if peripheral1 != nil && peripheral2 != nil{
            singlton.shared.centralManager.cancelPeripheralConnection(peripheral1)
            singlton.shared.centralManager.cancelPeripheralConnection(peripheral2)
        }
    }
    
    @objc func writtenGain2(noti: Notification){
        if let readGain = noti.userInfo?["WrittenGainPPG"] as? String{
            readGainLabel2.text = readGain
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGRead"), object: nil, userInfo: ["PPG": self.readGainLabel2.text ?? "-1"])

        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    //MARK: IB Actions
    
    @IBAction func writeGainOnGraph1(_ sender:Any){
        
        if (peripheral1 != nil){
            
            isGain = true
            
            guard writeGainSelected1 != nil else {
                let alert = UIAlertController(title: nil, message: "Gain is required", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            // newWritePacket = true
            print("graph packet write")
            ecg.writeGain(writeGainSelected: writeGainSelected1, channel: true)
            
        }else{
            let alert = UIAlertController(title: nil, message: "Please connect to the devices", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    @IBAction func readGainOnGraph1(_ sender:Any){
        isGain = false
        
        if (peripheral1 != nil){
            ecg.readGain(channel: true)
        }else{
            let alert = UIAlertController(title: nil, message: "Please connect to the devices", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    @IBAction func writeGainOnGraph2(_ sender:Any){
        
        guard writeGainSelected2 != nil else {
            let alert = UIAlertController(title: nil, message: "Gain is required", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        // newWritePacket = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGwriteGain"), object: nil, userInfo: ["writeGain": writeGainSelected2!])
        
    }
    
    @IBAction func ReadGainGraph2Action(_ sender: Any) {
        // ecg.readGain()
        // newWritePacket = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGReadGain"), object: nil, userInfo: nil)
    }
   
    
    @IBAction func startGraphAction(_ sender: Any) {
        
        print("starting graph")
        if startStopButton.tag == 0{

            startStopButton.tag = 1
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGStart"), object: nil, userInfo: nil)
            self.ecg.start()
            startStopButton.setTitle("Stop", for: .normal)
            
        }else{
            if (singlton.shared.saveEcgPpgText ?? false) == true{
                startStopTxtSaving(UIButton())
            }
            startStopButton.tag = 0
            startStopButton.setTitle("Start", for: .normal)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGStop"), object: nil, userInfo: nil)
            
            MBProgressHUD.showAdded(to: view, animated: true)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [unowned self] timer in
                MBProgressHUD.hide(for: self.view, animated: true)
                isGraphRunning = false
                self.ecg.stop()
                
            }
        }
        
    }
    
    
    @IBAction func startStopTxtSaving(_ sender: Any) {
        
        if activityIndexString == nil{
            let alert = UIAlertController(title: nil, message: "Please select activity", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        print("starting txt saving")
        if fileNameTextfield.text != nil{
            if fileNameTextfield.text != ""{
                if startTxtButton.tag == 0{
                    graph1FileNameString = fileNameTextfield.text
                    singlton.shared.ecgPPGfileName = fileNameTextfield.text
                    startTxtButton.tag = 1
                    singlton.shared.saveEcgPpgText = true
                    startTxtButton.setTitle("Stop", for: .normal)
                    
                    
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
                    let dateString = formatter.string(from: date)
                    graph1FileNameString = "\(graph1FileNameString!)_\(peripheral1.name!):\(dateString).txt"
                    graph1FileNameString = graph1FileNameString.replacingOccurrences(of: " ", with: "_")
                    
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        
                        let fileURL = dir.appendingPathComponent(self.graph1FileNameString)
                        
                        do {
                            try "PS , Data , PS State , Gain , Channel , Activity\n".write(to: fileURL, atomically: false, encoding: .utf8)
                        }
                        catch {/* error handling here */}
                        
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGSave"), object: nil, userInfo: nil)
                    
                }else{
                    fileNameTextfield.text = ""
                    startTxtButton.tag = 0
                    singlton.shared.saveEcgPpgText = false
                    startTxtButton.setTitle("Start", for: .normal)
                }
            }else{
                let alert = UIAlertController(title: nil, message: "Invalid file name", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
            
        }else{
            let alert = UIAlertController(title: nil, message: "Invalid file name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    
    
    

    func updateGraph1(_ ppgData : Data){
        var isModified = false
        let packetString = ppgData.map { String(format: "%02hhx", $0) }.joined()
        print("graph packet :\(packetString)")
        
        var currentNo : Int!
        var currentNoString = packetString.dropFirst(8)
        currentNoString = currentNoString.dropLast(currentNoString.count-2)
        currentNo = Int(UInt32(currentNoString, radix:16)!)
        
        
        
        if previousNo != nil && currentNo != previousNo+1 && (currentNo-previousNo != -254){
            
           var currNo:Int!
            
            var prevPacketLastByte = previousPacket.dropLast(2)
            prevPacketLastByte = prevPacketLastByte.dropFirst(prevPacketLastByte.count-4)
        
            let missedValues = currentNo-previousNo
            
           
            if missedValues>1{
                isModified = true
                for _ in 0..<missedValues{
                    
                    if previousNo == 255{
                        currNo = 0
                    }else{
                        currNo = previousNo+1
                    }
                    let hex = String(format:"%02X", currNo).lowercased()
                    let missedPack = "ab260201\(hex)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)CS"
                    print("miss Pack: ",missedPack)
                    valString = missedPack
                    updateValues(valString: &valString, currNo: currNo, isModified: isModified )
                    previousNo = currNo
                    print("xxx 0:\(valString)")
                }
            }
            else if missedValues < -1{
                isModified = true
                for _ in 0..<missedValues+255{
                    
                    if previousNo == 255{
                        currNo = 1
                    }else{
                        currNo = previousNo+1
                    }
                    let hex = String(format:"%02X", currNo).lowercased()
                    let missedPack = "ab260201\(hex)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)\(prevPacketLastByte)CS"
                    print("miss Pack: ",missedPack)
                    valString = missedPack
                    updateValues(valString: &valString, currNo: currNo, isModified: isModified )
                    previousNo = currNo
                    print("xxx 0:\(valString)")
                }
            }
            else{
                print("xxx miss")
                valString = packetString
            }
        }else{
            print("Cuur Pack: ",packetString)
            previousPacket = packetString
            valString = packetString
            updateValues(valString: &valString, currNo: currentNo, isModified: isModified )
            print("xxx 1:\(valString)")
        }
        previousNo = currentNo
        print("xxx past:\(valString)")
        
    }
    
    
    
    func updateValues (valString : inout String, currNo:Int, isModified:Bool){
        print("xxx before:\(valString)")
                
        valString = String(valString.dropFirst(10))
        valString = String(valString.dropLast(2))
        
        print("xxx after:\(valString)")
        
        let hexString = valString.separate(every: 4, with: " ")
        print("xxx", hexString)
        let hexArray = hexString.components(separatedBy: " ")
        for i in hexArray{
            
            let decimalValue = UInt32(i, radix:16)!
            addValuesToEcggraph(Int(decimalValue))
            
           
            if let saveEcg = singlton.shared.saveEcgPpgText {
                if saveEcg == true{
                    
                    var valueString = ""
                    if let index = selectedSwitch{
                        valueString = "\(currNo), \(decimalValue), \(isModified ? 1 : 0), \(readGainLabel1.text ?? "-1"), \(channelArray[index]), \(activityIndexString ?? "")"
                        
                    }else{
                        valueString = "\(currNo), \(decimalValue), \(isModified ? 1 : 0), \(readGainLabel1.text ?? "-1"), 0, \(activityIndexString ?? "")"
                    }
                    
                               
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileurl = dir.appendingPathComponent(self.graph1FileNameString ?? "PPG")
                        
                        let string = "\(valueString)\n"
                        
                        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                        
                        if FileManager.default.fileExists(atPath: fileurl.path) {
                            do {
                                let fileHandle = try FileHandle(forWritingTo: fileurl)
                                fileHandle.seekToEndOfFile()
                                fileHandle.write(data)
                                fileHandle.closeFile()
                            }
                            catch let error{
                                print("could write into txt \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
                
            
        }
        
    }
    
    let ACCEPTABLE_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ "

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = NSCharacterSet(charactersIn: ACCEPTABLE_CHARACTERS).inverted
        let filtered = string.components(separatedBy: cs).joined(separator: "")

        return (string == filtered)
    }
    
    func addValuesToEcggraph(_ value:Int)  {
        
        
            millisecondsGap +=  0.1
            self.graph1ValuesArray.add(value)
            graph1SecondsArray.add(millisecondsGap)
            
            if self.graph1ValuesArray.count>1280{
                self.graph1ValuesArray.removeObject(at: 0)
                self.graph1ValuesArray.removeObject(at: 0)
            }
    }
    
    @objc func setEcgDatacount(){
        
        let values = NSMutableArray()
        
        for i in 0..<graph1ValuesArray.count{
            
            let value = ChartDataEntry(x: graph1SecondsArray[i] as! Double, y: graph1ValuesArray[i] as! Double)
            values.add(value)
          
        }
        
        if let minVal = (graph1ValuesArray as! [Int]).min(),let maxVal = (graph1ValuesArray as! [Int]).max(){
            
            graph1.rightAxis.axisMinimum = Double(minVal-50)
            graph1.leftAxis.axisMinimum = Double(minVal-50)
            graph1.rightAxis.axisMaximum = Double(maxVal+50)
            graph1.leftAxis.axisMaximum = Double(maxVal+50)
            
        }
        let set1 = LineChartDataSet(entries: values as? [ChartDataEntry] ?? [], label: "DataSet 1")
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 70/255, green: 140/255, blue: 240/255, alpha: 1))
        set1.drawCirclesEnabled = false
        set1.lineWidth = 2
        set1.circleRadius = 3
        set1.fillAlpha = 1
        set1.drawFilledEnabled = true
        set1.fillColor = .white
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        
        
        let data = LineChartData(dataSets: [set1])
        data.setDrawValues(false)
        
        graph1.data = data
        
    }
    
    
}

extension ScrollViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChannellCollectionViewCell
        
        cell.chSwitch.tag = indexPath.row
        cell.chSwitch.addTarget(self, action: #selector(switchAction), for: .valueChanged)
        cell.chLabel.text = "CH \(indexPath.row+1)"
    
        
        if let index = selectedSwitch{
            if indexPath.row == index{
                cell.chSwitch.isOn = true
            }else{
                cell.chSwitch.isOn = false
            }
        }
        
        return cell
    }

    
    @objc func switchAction(_ sender: UISwitch){
        
        if peripheral1 == nil{
            let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! ChannellCollectionViewCell
            cell.chSwitch.isOn = false
            return
        }
        
        if sender.isOn == true{
            selectedSwitch = sender.tag
            let value1Int = UInt8(channelArray[sender.tag], radix:16)
            let response = Utils.sharedInst()?.channelSwitch(onCommand: Int32(value1Int!))
            peripheral1.writeValue(response!, for: char1, type: CBCharacteristicWriteType.withoutResponse)
            peripheral1.setNotifyValue(true, for: char1)
        }else{
            selectedSwitch = nil
            let value1Int = UInt8(channelArray[sender.tag], radix:16)
            let response = Utils.sharedInst().channelSwitchOffCommand(Int32(value1Int!))
            peripheral1.writeValue(response!, for: char1, type: CBCharacteristicWriteType.withoutResponse)
            peripheral1.setNotifyValue(true, for: char1)
        }
         
        
        collectionView.reloadData()
    }
    
    
    
}

extension ScrollViewController : ScannerDelegate{
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, ecgPeripheral: CBPeripheral, ppgPeripheral: CBPeripheral) {
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        secondPeriNameLabel.text = ppgPeripheral.name
        firstPeriNameLabel.text = ecgPeripheral.name
        
        self.peripheral1 = ecgPeripheral
        self.peripheral2 = ppgPeripheral
        
        connectButton.tag = 0
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
            
            
            self?.ecg.update = { data in
                
                if data.hexDescription.count == 80{
                    self?.isGraphRunning = true
                    self?.startTxtButton.isUserInteractionEnabled = true
                    self?.startTxtButton.alpha = 1.0
                    self?.updateGraph1(data)
                }
              
            }
            
            self?.ecg.updateGain = {
                if let gain = self?.isGain{
                    if gain{
                        self?.readGainOnGraph1(UIButton())
                        let alert = UIAlertController(title: "Success", message: "Gain written on \(ecgPeripheral.name ?? "")", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }
            
            self?.ecg.discvoer(ecgPeripheral: ecgPeripheral)
            self?.ecg.updateRead = { readString in
                self?.readGainLabel1.text = readString
            }
            self?.ecg.ecgReady = { char in
                MBProgressHUD.hide(for: (self?.view)!, animated: true)
                self?.char1 = char
                
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self?.readGainOnGraph1(UIButton())
                    let aSwitch = UISwitch();
                    aSwitch.isOn = false
                    aSwitch.tag = 0
                    self?.switchAction(aSwitch)
                }
                
                self?.connectButton.setTitle("Disconnect", for: .normal)
                self?.connectButton.backgroundColor = DesignSystem.Palette.accent
                self?.startStopButton.alpha = 1.0
                self?.startStopButton.isUserInteractionEnabled = true
               
            }
        }
    }
}
