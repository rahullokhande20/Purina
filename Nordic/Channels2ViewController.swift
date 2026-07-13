//
//  LNDViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 4/26/21.
//

import UIKit
import DropDown
import DGCharts
import CoreBluetooth
import MRHexKeyboard
import MBProgressHUD

class Channels2ViewController: UIViewController,ChartViewDelegate,UITextFieldDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }
    
    let channelArray = [ "01", "02", "03", "04", "05", "06", "07", "08"]
    var collectionView : UICollectionView!
    
    var selectedSwitch : Int!
  
    //    @IBOutlet weak var writeGain1Label : UILabel!
    //    @IBOutlet weak var writeGain2Label : UILabel!
    //    @IBOutlet weak var readGain1Label : UILabel!
    //    @IBOutlet weak var readGain2Label : UILabel!
    
    @IBOutlet weak var txtButton : UIButton!
    @IBOutlet weak var graphButton : UIButton!
    @IBOutlet weak var graphView: LineChartView!
    @IBOutlet weak var breedTextfield : UITextField!
    @IBOutlet weak var locationTextfield : UITextField!
    
    @IBOutlet weak var writeGainTextfield: UITextField!
    @IBOutlet weak var readGainLabel : UILabel!
    
    //@IBOutlet weak var writeGain2Textfield: UITextField!
    // @IBOutlet weak var readGain2Textfield: UITextField!
    
    
    var millisecondsGap = 0.1
    var valuesArr = NSMutableArray()
    let secondsArray = NSMutableArray()
    
  
    var char1 : CBCharacteristic!
    var fileNameString1 : String!
    var fileNameString2 : String!
    var values  = String()
    var stopSaving = true
    var isGraphRunning = false
    var vvaluesArray = NSMutableArray()
    var isPlotting = false
    var serviceType = ""
    var dataString = ""
    var gainDropdown = DropDown()

    
    var hexGainArray : [String]!
    var dropDownGainArray : [String]!
    var hexCurrentArray : [String]!
    var dropDownCurrentArray : [String]!
    
    var writeGainSelected : String!
    var writeCurrentSelected : String!
    var isFirst = true
    
    var writePacketGain : String!
    var writePacketCurrent : String!
    var isStopPacket = false
    var writePacketString : String!
    
    var startDate : Date!
   
    var startDelay : Double!
    var lapTIme = 0
    var timer : Timer!
    var connectButton : UIButton!
    var peripheral1 : CBPeripheral!
    var peripheral2 : CBPeripheral!
    
    var peri1Name = ""
    var peri2Name = ""
    
    var line1 = Line1()
    var line2 = Line2()
    
    var vvalues2Array = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.line1Update), name: NSNotification.Name(rawValue: "Line1Update"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.line2Update), name: NSNotification.Name(rawValue: "Line2Update"), object: nil)
        
        connectButton = UIButton(type: .custom)
        connectButton.tag = 1
        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(UIColor.white, for: .normal)
        connectButton.contentHorizontalAlignment = .right
        connectButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        connectButton.addTarget(self, action: #selector(self.scanAction), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: connectButton)
        self.navigationItem.rightBarButtonItem = item1
        
      
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect(x: 10, y: 0, width: 700, height: 120), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        layout.itemSize = CGSize(width: 50, height: 70)
        collectionView.backgroundColor = .white
        collectionView.isPagingEnabled = true
        self.view.addSubview(collectionView)
        collectionView.register(SwitchCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        

            hexGainArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C"]
            dropDownGainArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
            hexCurrentArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C"]
            dropDownCurrentArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
 
        
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        writeGainTextfield.inputView = UIView()
        gainDropdown.dataSource = dropDownGainArray
        gainDropdown.anchorView = writeGainTextfield
        gainDropdown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            gainDropdown.hide()
            self.writeGainSelected = hexGainArray[index]
            self.writeGainTextfield.text = dropDownGainArray[index]
        }
        writeGainTextfield.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(writeGainDropDown))
        writeGainTextfield.addGestureRecognizer(tap)
        
        txtButton.isHidden = true
        
        txtButton.layer.cornerRadius = 5.0
        txtButton.clipsToBounds = true
        
        graphButton.layer.cornerRadius = 5.0
        graphButton.clipsToBounds = true
        
        
        
        graphButton.setTitle("Start Graph", for: .normal)
        graphButton.addTarget(self, action: #selector(self.graphButtonAction), for: .touchUpInside)
        graphButton.tag = 1
        
        txtButton.tag = 1
        txtButton.addTarget(self, action: #selector(self.txtButtonAction), for: .touchUpInside)
        txtButton.setTitle("Start saving", for: .normal)
        
        
        
        
        graphView.delegate = self;
        graphView.dragEnabled = false
        graphView.drawGridBackgroundEnabled = false
        graphView.pinchZoomEnabled = true
        graphView.chartDescription.enabled = false
        graphView.setScaleEnabled(true)
        graphView.highlightPerDragEnabled = true
        graphView.backgroundColor = .clear
 
        let xAxis = graphView.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis.labelTextColor = .white
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        
//        let leftAxis = graphView.leftAxis
//
//
//        let rightAxis = graphView.rightAxis
//        rightAxis.labelTextColor = .blue

        
        

        
        //Auto Actions
        // writeGainAction()
       
        //        readGainAction()
        //        readCurrentAction()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.setDatacount()
        }
        
    }
    
   
    @objc func line1Update(notification:Notification){
        if let data = notification.userInfo?["data"] as? Data,
           let char = notification.userInfo?["char"] as? CBCharacteristic{
            
            self.char1 = char
            self.updateLine1Graph(data)
            
        }
    }
    
    
//     @objc func line2Update(notification:Notification){
//         if let data = notification.userInfo?["data"] as? Data{
//
////             self.char1 = char
//             self.updateLine1Graph(data)
//
//         }
//     }
    
    
    
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
        }
    }
    
    
    @objc func backAction(){
        // self.navigationController?.popViewController(animated: true)
        //  peripheral.setNotifyValue(false, for: char)
        if isGraphRunning {
          
            isStopPacket = true
            MBProgressHUD.showAdded(to: view, animated: true)
            isPlotting = false
            graphButton.tag = 1
            graphButton.setTitle("Start Graph", for: .normal)
            txtButton.isHidden = true
            //  writeAction("AB020205F7")
            isGraphRunning = false
            
            if let peripheral = singlton.shared.peripheral{
                
              
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
                    peripheral1.writeValue(writeData!, for: char1, type: CBCharacteristicWriteType.withResponse)
                
                peripheral1.setNotifyValue(true, for: char1)
            }
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func writeGainDropDown(){
        gainDropdown.show()
    }
  
    
    @IBAction func writeGainAction(){
        
        guard writeGainSelected != nil else {
            let alert = UIAlertController(title: nil, message: "Gain is required", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
       
        
        let value1Int = UInt8(writeGainSelected, radix:16)
        let response = Utils.sharedInst()?.sendWriteGainChannel(Int32(value1Int!))
        peripheral1.writeValue(response!, for: char1, type: CBCharacteristicWriteType.withoutResponse)
        peripheral1.setNotifyValue(true, for: char1)

        
        let alert = UIAlertController(title: nil, message: "Gain written", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        
    }
    @IBAction func readGainAction(){
        serviceType = "Gain"
        
            let writeData = Utils.sharedInst()?.sendreadGainChannel()
            peripheral1.writeValue(writeData!, for: char1, type: CBCharacteristicWriteType.withoutResponse)

        peripheral1.setNotifyValue(true, for: char1)
    }
    @IBAction func readCurrentAction(){
        serviceType = "Current"
        

            let writeData = Utils.sharedInst()?.sendReadCurrentLND()
            peripheral1.writeValue(writeData!, for: char1, type: CBCharacteristicWriteType.withoutResponse)
        
        
        peripheral1.setNotifyValue(true, for: char1)
    }
    
    @IBAction func writeCurrentAction(){
        
        guard writeCurrentSelected != nil else {
            let alert = UIAlertController(title: nil, message: "Current is required", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
       
        //  let value1Int = String(Int(writeCurrentSelected)!, radix:16)
       
            let responseDict = Utils.sharedInst()?.sendWriteCurrentLND(Int32(writeCurrentSelected)!)
            writePacketCurrent = writeCurrentSelected
            peripheral1.writeValue(responseDict!["Data"] as! Data, for: char1, type: CBCharacteristicWriteType.withoutResponse)
            peripheral1.setNotifyValue(true, for: char1)
        
        
        
        let alert = UIAlertController(title: nil, message: "Current written", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
 
    
    
    @objc func txtButtonAction(_ sender: UIButton){
        
        if !isGraphRunning {
            return
        }
        if txtButton.tag == 0{
            
            txtButton.tag = 1
            txtButton.setTitle("Start saving", for: .normal)
            stopSaving = true
            
        }else{
            
            txtButton.tag = 0
            txtButton.setTitle("Stop saving", for: .normal)
            stopSaving = false
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
            let dateString = formatter.string(from: date)
            
            //FILE : 1
            fileNameString1 = "\(breedTextfield.text ?? "")_\(locationTextfield.text ?? "")_\(peri1Name):\(dateString).txt"
            fileNameString1 = fileNameString1.replacingOccurrences(of: " ", with: "_")

            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let fileURL = dir.appendingPathComponent(self.fileNameString1)
                
                do {
                    try "".write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {/* error handling here */}
                
            }
            
            //FILE : 2
            fileNameString2 = "\(breedTextfield.text ?? "")_\(locationTextfield.text ?? "")_\(peri2Name):\(dateString).txt"
            fileNameString2 = fileNameString2.replacingOccurrences(of: " ", with: "_")

            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let fileURL = dir.appendingPathComponent(self.fileNameString2)
                
                do {
                    try "".write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {/* error handling here */}
                
            }
            
            
        }
        
        
    }
    
    
    @objc func graphButtonAction(_ sender: UIButton){
        
        if graphButton.tag == 1{
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Line2Start"), object: nil, userInfo: nil)
            line1.start()
            graphButton.tag = 0
            graphButton.tag = 0
            graphButton.setTitle("Stop Graph", for: .normal)
            isPlotting = true
            isGraphRunning = true
        }
        else{
            if timer != nil{
                timer.invalidate()
            }
            line1.stop()
            line2.stop()
            isPlotting = false
            graphButton.tag = 1
            graphButton.setTitle("Start Graph", for: .normal)
            isGraphRunning = false
        }
        
    }
    
    
    
//    {
//
//        if graphButton.tag == 1{
//            startDate = Date()
//
//            isPlotting = true
//
//            graphButton.tag = 0
//            graphButton.setTitle("Stop Graph", for: .normal)
//            txtButton.isHidden = false
//            isGraphRunning = true
//
//
//            if let peripheral = singlton.shared.peripheral{
//
//                let writeData = Utils.sharedInst()?.startBioMetricGraphLND()
//                peripheral.writeValue(writeData!, for: char1, type: CBCharacteristicWriteType.withResponse)
//
//            }
//
//
//        }else{
//            if timer != nil{
//                timer.invalidate()
//            }
//
//            let date = Date()
//            let formatter = DateFormatter()
//            formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
//            let dateString = formatter.string(from: date)
//
//
//
//
//            isPlotting = false
//            graphButton.tag = 1
//            graphButton.setTitle("Start Graph", for: .normal)
//            txtButton.isHidden = true
//            //  writeAction("AB020205F7")
//            isGraphRunning = false
//
//            if let peripheral = singlton.shared.peripheral{
//
//                    let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
//                    peripheral.writeValue(writeData!, for: char1, type: CBCharacteristicWriteType.withResponse)
//
//
//                peripheral.setNotifyValue(true, for: char1)
//            }
//        }
//
//    }
 
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    //MARK: Line1
    func updateLine1Graph(_ data : Data){
        
        
        var valString = data.map { String(format: "%02hhx", $0) }.joined()
        print("graph packet before :\(valString)")
        
        if valString.count == 86 || valString.count<34{
            return
        }
        
        //Validation for purina board
        if valString.count == 74 /*|| valString.count == 86*/{
            valString = String(valString.dropFirst(8))
            valString = String(valString.dropLast(2))
            dataString = valString
        }
        
        // validation for hearthMath
        else{
            
            if valString.count == 34{
                valString = String(valString.dropLast(2))
                dataString.append(valString)
            }
            if valString.contains("ab220201"){
                valString = String(valString.dropFirst(8))
                dataString.append(valString)
                
            }
        }
        
        if dataString.count<64{
            return
        }
        print("data pack : \(dataString)")
        print("graph packet after:\(valString)")
        
        let array = dataString.map( { String($0) })
        var valuesArray = Array<Int>()
        if array.count>4{
            for i in 0..<array.count{
                
                if i%4==0{
                    
                    var j = i
                    var first = ""
                    if i<array.count{
                        
                        first = array[i] as String
                        
                    }
                    
                    j += 1
                    var second = ""
                    if i<array.count{
                        
                        second = array[j] as String
                    }
                    
                    j += 1
                    var third = ""
                    if j<array.count{
                        
                        third = array[j] as String
                    }
                    
                    j += 1
                    var fourth = ""
                    if j<array.count{
                        fourth = array[j] as String
                    }
                    
                    let value = "\(first)\(second)\(third)\(fourth)"
                    let intValue = UInt32(value, radix:16)
                    
                    valuesArray.append(Int("\(intValue!)")!)
                    
                    
                }
                
            }
        }
        dataString = ""
        addLine1ValuesTograph(valuesArray)
        
    }
    
    
    func addLine1ValuesTograph(_ valuesArray:[Int])   {
        
        if !isPlotting{ return }

        
        for i in 0..<valuesArray.count{
            print("val - \(valuesArray[i])")
           
                millisecondsGap +=  0.1
                
                self.vvaluesArray.add(valuesArray[i])
                secondsArray.add(millisecondsGap)
                
                if self.vvaluesArray.count>2560{
                    self.vvaluesArray.removeObject(at: 0)
                    self.secondsArray.removeObject(at: 0)
                }
                
                if self.stopSaving{ return }
                let valueString = "\(valuesArray[i])"
                
                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileurl = dir.appendingPathComponent(self.fileNameString1)
                    
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
    
    //MARK: Line2
    func updateLine2Graph(_ data : Data){
        
        
        var valString = data.map { String(format: "%02hhx", $0) }.joined()
        print("graph packet before :\(valString)")
        
        if valString.count == 86 || valString.count<34{
            return
        }
        
        //Validation for purina board
        if valString.count == 74 /*|| valString.count == 86*/{
            valString = String(valString.dropFirst(8))
            valString = String(valString.dropLast(2))
            dataString = valString
        }
        
        // validation for hearthMath
        else{
            
            if valString.count == 34{
                valString = String(valString.dropLast(2))
                dataString.append(valString)
            }
            if valString.contains("ab220201"){
                valString = String(valString.dropFirst(8))
                dataString.append(valString)
                
            }
        }
        
        if dataString.count<64{
            return
        }
        print("data pack : \(dataString)")
        print("graph packet after:\(valString)")
        
        let array = dataString.map( { String($0) })
        var valuesArray = Array<Int>()
        if array.count>4{
            for i in 0..<array.count{
                
                if i%4==0{
                    
                    var j = i
                    var first = ""
                    if i<array.count{
                        
                        first = array[i] as String
                        
                    }
                    
                    j += 1
                    var second = ""
                    if i<array.count{
                        
                        second = array[j] as String
                    }
                    
                    j += 1
                    var third = ""
                    if j<array.count{
                        
                        third = array[j] as String
                    }
                    
                    j += 1
                    var fourth = ""
                    if j<array.count{
                        fourth = array[j] as String
                    }
                    
                    let value = "\(first)\(second)\(third)\(fourth)"
                    let intValue = UInt32(value, radix:16)
                    
                    valuesArray.append(Int("\(intValue!)")!)
                }
                
            }
        }
        dataString = ""
        addLine2ValuesTograph(valuesArray)
        
    }
    
    
    func addLine2ValuesTograph(_ valuesArray:[Int])   {
        
        if !isPlotting{ return }

        
        for i in 0..<valuesArray.count{
            if valuesArray[i] != 0{
                millisecondsGap +=  0.1
                
                self.vvalues2Array.add(valuesArray[i])
                secondsArray.add(millisecondsGap)
                
                if self.vvalues2Array.count>2560{
                    self.vvalues2Array.removeObject(at: 0)
                    self.secondsArray.removeObject(at: 0)
                }
                
                if self.stopSaving{ return }
                let valueString = "\(valuesArray[i])"
                
                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileurl = dir.appendingPathComponent(self.fileNameString2)
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
    
    
    @objc func setDatacount(){
        
        
        //Line 1
        var values = [ChartDataEntry]()
        var values2 = [ChartDataEntry]()
        for i in 0..<vvaluesArray.count{
            
            let value = ChartDataEntry(x: secondsArray[i] as! Double, y: vvaluesArray[i] as! Double)
            values.append(value)
            
        }
        
        let set1 = LineChartDataSet(entries: values , label: "\(peri1Name)")
        set1.lineWidth = 2
        set1.setColor(.orange)
        set1.axisDependency = .left
        set1.drawCirclesEnabled = false
        set1.drawCircleHoleEnabled = false
        
        
        //Line 2
        for i in 0..<vvalues2Array.count{
//            print("line 2 X \(seconds2Array[i])")
            let value2 = ChartDataEntry(x: secondsArray[i] as! Double, y: vvalues2Array[i] as! Double)
            values2.append(value2)
        }
        let set2 = LineChartDataSet(entries: values2 , label: "\(peri2Name)")
        set2.lineWidth = 2
        set2.setColor(.blue)
        set1.axisDependency = .left
        set2.drawCirclesEnabled = false
        set2.drawCircleHoleEnabled = false
        
        
        let data = LineChartData(dataSets: [set1 , set2])
        graphView.data = data
        
        
    }
  
    
  
     
   
    
}

extension Channels2ViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SwitchCollectionViewCell
        cell.backgroundColor = .white
        cell.aSwitch.tag = indexPath.item
        cell.aSwitch.addTarget(self, action: #selector(switchAction), for: .valueChanged)
        cell.label.text = "CH \(indexPath.row+1)"
    
        if let index = selectedSwitch{
            if indexPath.item == index{
                cell.aSwitch.isOn = true
            }else{
                cell.aSwitch.isOn = false
            }
        }

        
        return cell
    }
    
    @objc func switchAction(_ sender: UISwitch){
        
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 35
    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 1
//    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 50, height: 65)
//    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//
//    }

}

extension Channels2ViewController : ScannerDelegate{
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, ecgPeripheral: CBPeripheral, ppgPeripheral: CBPeripheral) {
    
        
        
        self.peripheral1 = ppgPeripheral
        self.peripheral2 = ecgPeripheral
        
       
        
        peri1Name = self.peripheral1.name ?? ""
        peri2Name = self.peripheral2.name ?? ""
        
        print("peripheral 1 ", self.peripheral1.name ?? "P1:No-Name")
        print("peripheral 2 ", self.peripheral2.name ?? "P2:No-Name")
        
        connectButton.tag = 0
       
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] timer in
            
            self?.txtButton.isHidden = false
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Line2Connect"), object: nil, userInfo: ["peri":(self?.peripheral1)!])
            
        }
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
          
            
        //Line 1
            self?.line1.update = { data,char in
                self?.char1 = char
                self?.updateLine1Graph(data)
            }
            self?.line1.updateRead = { readString in
                self?.readGainLabel.text = readString
            }
            self?.line1.discvoer(peripheral: (self?.peripheral1)!)
            
            self?.line1.isPeripheralReady = {
                self?.connectButton.setTitle("Disconnect", for: .normal)
                self?.graphButton.alpha = 1.0
                self?.graphButton.isUserInteractionEnabled = true
            }
          
            
           
            
        //Line 2
//            self?.line2.update = { data in
//                self?.updateLine2Graph(data)
//            }
//            self?.line2.discvoer(peripheral: (self?.peripheral2)!)
            
        }
        
    }
    
}
