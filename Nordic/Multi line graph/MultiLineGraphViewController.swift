//
//  MultiLineGraphViewController.swift
//  Purina
//
//  Created by Sai Dammu on 1/10/22.
//


import UIKit
import DropDown
import CoreBluetooth
import MRHexKeyboard
import MBProgressHUD
import DGCharts

class MultiLineGraphViewController: UIViewController,ChartViewDelegate,UITextFieldDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }
   
  
    @IBOutlet weak var graphButton : UIButton!
    @IBOutlet weak var graphView: LineChartView!
    @IBOutlet weak var graphView1: LineChartView!
    @IBOutlet weak var breedTextfield : UITextField!
    @IBOutlet weak var locationTextfield : UITextField!
    @IBOutlet weak var writeGainTextfield: UITextField!
    @IBOutlet weak var writeCurrentTextfield: UITextField!
    @IBOutlet weak var readGainLabel : UILabel!
    @IBOutlet weak var readCurrentLabel : UILabel!
    @IBOutlet weak var currentTitleLabel: UILabel!
    @IBOutlet weak var currentReadButton: UIButton!
    @IBOutlet weak var currentWriteButton: UIButton!
    
    var peri1Name = ""
    var peri2Name = ""
    
    var millisecondsGap = 0.1
    var valuesArr = NSMutableArray()
    let secondsArray = NSMutableArray()
    
    var values2Arr = NSMutableArray()
    let seconds2Array = NSMutableArray()
    
    var values  = String()
    var stopSaving = true
    var isGraphRunning = false
    var vvaluesArray = NSMutableArray()
    var vvalues2Array = NSMutableArray()
    var isPlotting = false
    var titleString : String!
    var serviceType = ""
    var dataString = ""
    var gainDropdown = DropDown()
    var currentDropdown = DropDown()
    
    var hexGainArray : [String]!
    var dropDownGainArray : [String]!
    var hexCurrentArray : [String]!
    var dropDownCurrentArray : [String]!
    
    var writeGainSelected : String!
    var writeCurrentSelected : String!
    var isFirst = true
    var newWritePacket = true
    var writePacketGain : String!
    var writePacketCurrent : String!
    var isStopPacket = false
    var writePacket : String!
    var writePacketString : String!
//    var crudValues = [Int]()
    
    var startDate : Date!
   
    var startDelay : Double!
    var lapTIme = 0
    var timer : Timer!
    
    let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    var connectButton : UIButton!
    var actionType = ""
    var line1 = Line1()
    var line2 = Line2()
    var peripheral1 : CBPeripheral!
    var peripheral2 : CBPeripheral!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.line1Update), name: NSNotification.Name(rawValue: "Line1Update"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.line2Update), name: NSNotification.Name(rawValue: "Line2Update"), object: nil)
        
        
        
        connectButton = UIButton(type: .custom)
        connectButton.tag = 1
        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(UIColor.white, for: .normal)
        connectButton.contentHorizontalAlignment = .right
        connectButton.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
        connectButton.addTarget(self, action: #selector(self.scanAction), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: connectButton)
        self.navigationItem.rightBarButtonItem = item1
        
        
        writeCurrentTextfield.isHidden = false
        readCurrentLabel.isHidden = false
        currentReadButton.isHidden = false
        currentWriteButton.isHidden = false
        currentTitleLabel.isHidden = false
        
        
       
            hexGainArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C"]
            dropDownGainArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
            hexCurrentArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C"]
            dropDownCurrentArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
        
        
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
        
        
        writeCurrentTextfield.inputView = UIView()
        currentDropdown.dataSource = dropDownCurrentArray
        currentDropdown.anchorView = writeCurrentTextfield
        currentDropdown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            currentDropdown.hide()
            self.writeCurrentSelected = dropDownCurrentArray[index]
            self.writeCurrentTextfield.text = dropDownCurrentArray[index]
        }
        currentDropdown.isUserInteractionEnabled = true
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(writeCurrentDropDown))
        writeCurrentTextfield.addGestureRecognizer(tap1)
        
        
        graphButton.setTitle("Start Graph", for: .normal)
        graphButton.addTarget(self, action: #selector(self.graphButtonAction), for: .touchUpInside)
        graphButton.tag = 1
        
        
        
        
        //Graph 1
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
        
        let leftAxis = graphView.leftAxis
        leftAxis.labelTextColor = .orange

        let rightAxis = graphView.rightAxis
        rightAxis.labelTextColor = .blue
        
        
        //Graph 2
        graphView1.delegate = self;
        graphView1.dragEnabled = false
        graphView1.drawGridBackgroundEnabled = false
        graphView1.pinchZoomEnabled = true
        graphView1.chartDescription.enabled = false
        graphView1.setScaleEnabled(true)
        graphView1.highlightPerDragEnabled = true
        graphView1.backgroundColor = .clear
 
        let xAxis1 = graphView.xAxis
        xAxis1.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis1.labelTextColor = .white
        xAxis1.drawGridLinesEnabled = false
        xAxis1.drawAxisLineEnabled = false
        
        let leftAxis1 = graphView.leftAxis
        leftAxis1.labelTextColor = .blue


        
        newWritePacket = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.setDatacount()
            self.setDatacount1()
        }
    }
    
    @objc func line1Update(notification:Notification){
        if let data = notification.userInfo?["data"] as? Data,
           let char = notification.userInfo?["char"] as? CBCharacteristic{
        
            self.updateLine1Graph(data)
            
        }
    }
    
    @objc func line2Update(notification:Notification){
        if let data = notification.userInfo?["data"] as? Data{
        
            DispatchQueue.main.async {
                self.updateLine2Graph(data)
            }
            
        }
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
        }
    }
    
    
    @objc func backAction(){
        
        if isGraphRunning {
//            newWritePacket = false
//            isStopPacket = true
//            MBProgressHUD.showAdded(to: view, animated: true)
//            isPlotting = false
//            graphButton.tag = 1
//            graphButton.setTitle("Start Graph", for: .normal)
//            txtButton.isHidden = true
//            //  writeAction("AB020205F7")
//            isGraphRunning = false
//
//            if let peripheral = singlton.shared.peripheral{
//
//                let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
//                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
//
//                peripheral.setNotifyValue(true, for: char)
//            }
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func writeGainDropDown(){
        gainDropdown.show()
    }
    @objc func writeCurrentDropDown(){
        currentDropdown.show()
    }
    
    @IBAction func writeGainAction()
    {
        actionType = "write"
        guard writeGainSelected != nil else {
            let alert = UIAlertController(title: nil, message: "Gain is required", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        // newWritePacket = true
        print("graph packet write")
        line1.writeGain(writeGainSelected: writeGainSelected)
        
    }
    
    @IBAction func readGainAction(){
        serviceType = "Gain"
        
       
//            let writeData = Utils.sharedInst()?.sendReadGainLND()
//            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
//
//        peripheral.setNotifyValue(true, for: char)
    }
    @IBAction func readCurrentAction(){
        serviceType = "Current"
        
//
//            let writeData = Utils.sharedInst()?.sendReadCurrentLND()
//            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
//
//
//        peripheral.setNotifyValue(true, for: char)
    }
    
    @IBAction func writeCurrentAction(){
        
//        guard writeCurrentSelected != nil else {
//            let alert = UIAlertController(title: nil, message: "Current is required", preferredStyle: UIAlertController.Style.alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//            return
//        }
//        newWritePacket = true
//
//            let responseDict = Utils.sharedInst()?.sendWriteCurrentLND(Int32(writeCurrentSelected)!)
//            writePacketCurrent = writeCurrentSelected
//            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
//            peripheral.setNotifyValue(true, for: char)
//
//
//
//        let alert = UIAlertController(title: nil, message: "Current written", preferredStyle: UIAlertController.Style.alert)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
        
    }
    
    //    @IBAction func readGainAction(){
    //
    //            if let value1 = readGain1Textfield.text, let value2 = readGain2Textfield.text{
    //                let writeData = Utils.sharedInst()?.sendReadGain()
    //                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
    //                peripheral.setNotifyValue(true, for: char)
    //            }
    //
    //        print("R Gain 1 \(readGain1Textfield.text)\nR Gain 2 \(readGain2Textfield.text)")
    //
    //    }
    //    @IBAction func writeGainAction(){
    //
    //
    //        if let value1 = writeGain1Textfield.text, let value2 = writeGain2Textfield.text {
    //
    //            guard value1 != "" else {
    //                let alert = UIAlertController(title: nil, message: "Gain 1 is required", preferredStyle: UIAlertController.Style.alert)
    //                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    //                self.present(alert, animated: true, completion: nil)
    //                return
    //            }
    //            guard value2 != "" else {
    //                let alert = UIAlertController(title: nil, message: "Gain 2 is required", preferredStyle: UIAlertController.Style.alert)
    //                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    //                self.present(alert, animated: true, completion: nil)
    //                return
    //            }
    //
    //
    //            let value1Int = UInt8(value1, radix:16)
    //            let value2Int = UInt8(value2, radix:16)
    //            let writeData = Utils.sharedInst()?.sendWriteGain(Int32(value1Int!), value2: Int32(value2Int!))
    //            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
    //            peripheral.setNotifyValue(true, for: char)
    //
    //            let alert = UIAlertController(title: nil, message: "Gain written", preferredStyle: UIAlertController.Style.alert)
    //            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    //            self.present(alert, animated: true, completion: nil)
    //
    //        }
    //        print("W Gain 1 \(writeGain1Textfield.text)\nW Gain 2 \(writeGain2Textfield.text)")
    //
    //    }
    
    
  
    
    
    @objc func graphButtonAction(_ sender: UIButton){
        
        if graphButton.tag == 1{
            line1.start()
            line2.start()
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
  
        
//        {
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
//                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
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
//            let titleString = "LND339_\(dateString)"
//
//
//            isPlotting = false
//            graphButton.tag = 1
//            graphButton.setTitle("Start Graph", for: .normal)
//            txtButton.isHidden = true
//            isGraphRunning = false
//
//            if let peripheral = singlton.shared.peripheral{
//
//                let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
//                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
//
//
//                peripheral.setNotifyValue(true, for: char)
//            }
//        }
//
//    }
    /*
     func writeAction(_ input:String){
     let hexData = Data(hex: input)!
     // peripheral.delegate = self
     // peripheral.writeValue(hexData, for: char, type: CBCharacteristicWriteType.withoutResponse)
     //  peripheral.setNotifyValue(true, for: char)
     
     let writeData = Utils.sharedInst()?.startBioMetricGraph()
     peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
     
     
     print("write packert \(input)")
     } */
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
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
            
            if valuesArray[i] != 0{
                millisecondsGap +=  0.1
                print("line....1",valuesArray[i])
                self.vvaluesArray.add(valuesArray[i])
                secondsArray.add(millisecondsGap)
                
                if self.vvaluesArray.count>2560{
                    self.vvaluesArray.removeObject(at: 0)
                    self.secondsArray.removeObject(at: 0)
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
                print("line....2",valuesArray[i])
                self.vvalues2Array.add(valuesArray[i])
                secondsArray.add(millisecondsGap)
                
                if self.vvalues2Array.count>2560{
                    self.vvalues2Array.removeObject(at: 0)
                    self.secondsArray.removeObject(at: 0)
                }
            }
        }
    }
    
    
    @objc func setDatacount(){
        
        
        //Line 1
        var values = [ChartDataEntry]()
        
        
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
        
        
        let data = LineChartData(dataSet: set1)
        graphView.data = data
        
        
    }
    
    @objc func setDatacount1(){
        
        var values2 = [ChartDataEntry]()
        
        for i in 0..<vvalues2Array.count{
            let value2 = ChartDataEntry(x: secondsArray[i] as! Double, y: vvalues2Array[i] as! Double)
            values2.append(value2)
        }
        let set2 = LineChartDataSet(entries: values2 , label: "\(peri2Name)")
        set2.lineWidth = 2
        set2.setColor(.blue)
        set2.axisDependency = .left
        set2.drawCirclesEnabled = false
        set2.drawCircleHoleEnabled = false
        
        let data = LineChartData(dataSet: set2)
        graphView1.data = data
        
        
    }
    
}


extension MultiLineGraphViewController : ScannerDelegate{
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, ecgPeripheral: CBPeripheral, ppgPeripheral: CBPeripheral) {
    
       
        
        self.peripheral1 = ecgPeripheral
        self.peripheral2 = ppgPeripheral
        
        peri1Name = self.peripheral1.name ?? ""
        peri2Name = self.peripheral2.name ?? ""
        
        print("peripheral 1 ", self.peripheral1.name ?? "P1:No-Name")
        print("peripheral 2 ", self.peripheral2.name ?? "P2:No-Name")
        
        connectButton.tag = 0
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
          
        //Line 1
//            self?.line1.update = { data,char in
//                self?.updateLine1Graph(data)
//            }
            self?.line1.discvoer(peripheral: ecgPeripheral)
            
            self?.line1.isPeripheralReady = {
                self?.connectButton.setTitle("Disconnect", for: .normal)
                self?.graphButton.alpha = 1.0
                self?.graphButton.isUserInteractionEnabled = true
            }
            
        //Line 2
//            self?.line2.update = { data in
//                self?.updateLine2Graph(data)
//            }
            self?.line2.discvoer(peripheral: ppgPeripheral)
            
        }
        
    }
    
}
