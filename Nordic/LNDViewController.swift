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

class LNDViewController: UIViewController,CBPeripheralDelegate,ChartViewDelegate,UITextFieldDelegate {

    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }
    
  

    @IBOutlet weak var writeGain1Label : UILabel!
    @IBOutlet weak var writeGain2Label : UILabel!
    @IBOutlet weak var readGain1Label : UILabel!
    @IBOutlet weak var readGain2Label : UILabel!
    
    @IBOutlet weak var txtButton : UIButton!
    @IBOutlet weak var graphButton : UIButton!
    @IBOutlet weak var graphView: LineChartView!
    @IBOutlet weak var breedTextfield : UITextField!
    @IBOutlet weak var locationTextfield : UITextField!
    
    @IBOutlet weak var writeGain1Textfield: UITextField!
    @IBOutlet weak var writeGain2Textfield: UITextField!
    @IBOutlet weak var readGain1Textfield: UITextField!
    @IBOutlet weak var readGain2Textfield: UITextField!
   
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!

    
    var millisecondsGap = 0.1
    var valuesArr = NSMutableArray()
    let secondsArray = NSMutableArray()
    
    var peripheral : CBPeripheral!
    var char : CBCharacteristic!
    var fileNameString : String!
    var values  = String()
    var stopSaving = true
    var isGraphRunning = false
    var vvaluesArray = NSMutableArray()
    var isPlotting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Biometrics-Debug"
        
        txtButton.isHidden = true
        
        readButton.layer.cornerRadius = 5.0
        readButton.clipsToBounds = true
        
        writeButton.layer.cornerRadius = 5.0
        writeButton.clipsToBounds = true
        
        txtButton.layer.cornerRadius = 5.0
        txtButton.clipsToBounds = true
       
        graphButton.layer.cornerRadius = 5.0
        graphButton.clipsToBounds = true
        
        readGain1Textfield.inputView = UIView()
        readGain2Textfield.inputView = UIView()
        
        
        writeGain1Textfield.inputView = MRHexKeyboard()
        writeGain2Textfield.inputView = MRHexKeyboard()
        
        singlton.shared.peripheral.delegate = self
        singlton.shared.peripheral.discoverServices(nil)
        
        
        graphButton.setTitle("Start Graph", for: .normal)
        graphButton.addTarget(self, action: #selector(self.graphButtonAction), for: .touchUpInside)
        graphButton.tag = 1
        
        txtButton.tag = 1
        txtButton.addTarget(self, action: #selector(self.txtButtonAction), for: .touchUpInside)
        txtButton.setTitle("Start saving", for: .normal)
        
       
        
        //graph UI
        /*
        graphView.delegate = self
        graphView.chartDescription?.enabled = false
        graphView.dragEnabled = false
        graphView.setScaleEnabled(true)
        graphView.pinchZoomEnabled = false
         graphView.drawGridBackgroundEnabled = false
        graphView.highlightPerDragEnabled = true
        graphView.backgroundColor = .clear
        graphView.legend.enabled = false
        graphView.rightAxis.labelPosition = .insideChart
         
        let xAxis = graphView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 6)
        
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 3600
        xAxis.setLabelCount(500, force: true)
        // xAxis.labeld = "ms"
        
        xAxis.granularityEnabled = true
        xAxis.granularity = 1.0 //default granularity is 1.0, but it is better to be explicit
        xAxis.decimals = 0
        
        let leftAxis = graphView.leftAxis
        leftAxis.labelPosition = .insideChart
        leftAxis.labelFont = UIFont.systemFont(ofSize: 0)
        leftAxis.labelTextColor = .red
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawGridLinesEnabled = true
        leftAxis.centerAxisLabelsEnabled = true
        leftAxis.granularity = 3600
        leftAxis.setLabelCount(8, force: true)
        */
        
        graphView.delegate = self;
        
        //graphView.chartDescription.enabled = false;
        
        graphView.dragEnabled = false
        graphView.setScaleEnabled(true)
        graphView.drawGridBackgroundEnabled = false
        graphView.pinchZoomEnabled = true
        graphView.backgroundColor = .white

        graphView.chartDescription.enabled = false
        graphView.dragEnabled = false
        graphView.setScaleEnabled(true)
        graphView.pinchZoomEnabled = false
         graphView.drawGridBackgroundEnabled = false
        graphView.highlightPerDragEnabled = true
        graphView.backgroundColor = .clear
        graphView.legend.enabled = false
        
        let l = graphView.legend
        l.form = .line
        l.font = UIFont.systemFont(ofSize: 10)
        l.textColor = .white
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
     
        let xAxis = graphView.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis.labelTextColor = .white
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        
    
        let leftAxis = graphView.leftAxis
        leftAxis.labelTextColor = .red
        leftAxis.axisMinimum = 200
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true;
        leftAxis.drawZeroLineEnabled = false;
        leftAxis.granularityEnabled = true;
        
        let rightAxis = graphView.leftAxis
        rightAxis.labelTextColor = .red
        rightAxis.axisMinimum = 200
        rightAxis.axisMinimum = 0
        rightAxis.drawGridLinesEnabled = true;
        rightAxis.drawZeroLineEnabled = false;
        rightAxis.granularityEnabled = true;
        
        
      
    }
    
 
    @IBAction func readGainAction(){
        
            if let value1 = readGain1Textfield.text, let value2 = readGain2Textfield.text{
                let writeData = Utils.sharedInst()?.sendReadGain()
                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
                peripheral.setNotifyValue(true, for: char)
            }
        
        print("R Gain 1 \(readGain1Textfield.text)\nR Gain 2 \(readGain2Textfield.text)")
        
    }
    @IBAction func writeGainAction(){
        
        
        if let value1 = writeGain1Textfield.text, let value2 = writeGain2Textfield.text {
                        
            guard value1 != "" else {
                let alert = UIAlertController(title: nil, message: "Gain 1 is required", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            guard value2 != "" else {
                let alert = UIAlertController(title: nil, message: "Gain 2 is required", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            
            let value1Int = UInt8(value1, radix:16)
            let value2Int = UInt8(value2, radix:16)
            let writeData = Utils.sharedInst()?.sendWriteGain(Int32(value1Int!), value2: Int32(value2Int!))
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
            peripheral.setNotifyValue(true, for: char)
            
            let alert = UIAlertController(title: nil, message: "Gain written", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        print("W Gain 1 \(writeGain1Textfield.text)\nW Gain 2 \(writeGain2Textfield.text)")
        
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
            fileNameString = "\(breedTextfield.text ?? "")_\(locationTextfield.text ?? ""):\(dateString).txt"
            fileNameString = fileNameString.replacingOccurrences(of: " ", with: "_")
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let fileURL = dir.appendingPathComponent(self.fileNameString)
                
                do {
                    try self.values.write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {/* error handling here */}
                
            }
            
        }
        
        
    }

        
  
    

    @objc func graphButtonAction(_ sender: UIButton){
        
        if graphButton.tag == 1{
            
            isPlotting = true
            
            graphButton.tag = 0
            graphButton.setTitle("Stop Graph", for: .normal)
           // writeAction("AB020201FB")
            txtButton.isHidden = false
            isGraphRunning = true
            
            if let peripheral = singlton.shared.peripheral{
                let writeData = Utils.sharedInst()?.startBioMetricGraph()
                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
                peripheral.setNotifyValue(true, for: char)
            }
            
    
            
        }else{
            isPlotting = false
            graphButton.tag = 1
            graphButton.setTitle("Start Graph", for: .normal)
            txtButton.isHidden = true
          //  writeAction("AB020205F7")
            isGraphRunning = false
            
            if let peripheral = singlton.shared.peripheral{
                let writeData = Utils.sharedInst()?.stopBioMetricGraph()
                peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
                peripheral.setNotifyValue(true, for: char)
            }
        }
        
    }
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
    
    //MARK: BLE delegates

    //MARK: bluetooth delegate
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("write success")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("vals")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("vall")
        
        if let data = characteristic.value{
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            if hexArray.count == 7{
                DispatchQueue.main.async {
                    
                    self.readGain1Textfield.text = hexArray[4]
                    self.readGain2Textfield.text = hexArray[5]
                }
            }
           // print("resp \(hexString)")
            updateGraph(data)
        }else {
            print("value recieved nil")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover char")
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.localizedDescription)")
            return
        }
        print("char115 \(service.characteristics)")
        for newChar: CBCharacteristic in service.characteristics!{
            print("ccb \(newChar.properties.rawValue)")
            // MBProgressHUD.hide(for: self.view, animated: true)
            
            //  if newChar.value != nil{
            
            if newChar.properties == CBCharacteristicProperties.notify{
                peripheral.setNotifyValue(true, for: newChar)
            }
            else {
                
                self.char = newChar
                
            }
            
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // print("Discover services for peripheralIdentifier: \(peripheral.identifier.uuidString)")
        
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            print("services111 \(foundServices)")
            // services = foundServices
            let service = foundServices[0]
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
        
    }
    
    func updateGraph(_ ppgData : Data){
        
        
        
        var valString = ppgData.map { String(format: "%02hhx", $0) }.joined()
   
        
        valString = String(valString.dropFirst(8))
        valString = String(valString.dropLast(2))
        
        let array = valString.map( { String($0) })
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
                    //  print("val x-Hex \(i)")
                    //  print("val x-Hex \(i)")
                    //                  print("\(first)\(second)\(third)\(fourth)")
                    let value = "\(first)\(second)\(third)\(fourth)"
                    let intValue = UInt32(value, radix:16)
                    
                    valuesArray.append(Int("\(intValue!)")!)
                    
                    
                }
                //    index += 1
            }
        }
      //  setDatacount()
        //  let str = String(decoding: qppData, as: UTF8.self)
        // let value1 = UInt64(firstByte, radix:64)
        //  let value2 = UInt64(lastByte, radix:64)
        //      print(valuesArray.count)
        //     index += 1
        addValuesTograph(valuesArray)
        //    let dict = ["name":valuesArray]
        //    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "graphUpdate"),object: nil, userInfo: dict)
        
        //     }
        
    }
    
    /*
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
        // let value = characteristic.value?.hexDescription
        if let data = characteristic.value{
            print("write ack \(data.hexDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("value rec")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
       // print("vall rec \(ch)")
        if let data = characteristic.value{
            print("write ack1 \(data.hexDescription)")
            let hexString = data.hexDescription.separate(every: 4, with: " ")
            let hexString1 = hexString.dropFirst(8)
            let valsArr = NSMutableArray()
            valsArr.addObjects(from: hexString1.components(separatedBy: " "))
           
            
            for i in valsArr{
                let string = i as? String ?? ""
               // let n = 14
                
                if let value = Int(string , radix: 16) {
                  //  print(value)
                  //  print("val \(st)")
                    if self.valuesArr.count>80{
                        valuesArr.removeObject(at: 0)
                        secondsArray.removeObject(at: 0)
                    }
                    
                    valuesArr.add(value)
                    secondsArray.add(millisecondsGap)
                    
                    self.writetoTxt("\(value)")
                    
                          
                }
   
            }
            
            setDatacount()
        }
    }
    */
    
    func addValuesTograph(_ valuesArray:[Int])   {
        
        if !isPlotting{ return }
        
        //    if index%2==0{
        
        for i in 0..<valuesArray.count{
            millisecondsGap +=  0.1
            print("xxx \(valuesArray[i])")
            self.vvaluesArray.add(valuesArray[i])
            secondsArray.add(millisecondsGap)
            
            if self.vvaluesArray.count>3200{
                self.vvaluesArray.removeObject(at: 0)
                self.secondsArray.removeObject(at: 0)
            }
            
            DispatchQueue.main.async {
                self.setDatacount()
                if self.stopSaving{ return }
                let valueString = "\(valuesArray[i])"
                              
                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileurl = dir.appendingPathComponent(self.fileNameString)
                    
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
        
        let values = NSMutableArray()
                
        for i in 0..<vvaluesArray.count{
      
            
            let value = ChartDataEntry(x: secondsArray[i] as! Double, y: vvaluesArray[i] as! Double)
            values.add(value)
            
        }
        
        if let minVal = (vvaluesArray as! [Int]).min(),let maxVal = (vvaluesArray as! [Int]).max(){
       
            graphView.rightAxis.axisMinimum = Double(minVal-50)
            graphView.leftAxis.axisMinimum = Double(minVal-50)
            graphView.rightAxis.axisMaximum = Double(maxVal+50)
            graphView.leftAxis.axisMaximum = Double(maxVal+50)
            
        }
        let set1 = LineChartDataSet(entries: values as? [ChartDataEntry] ?? [], label: "DataSet 1")
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 255/255, green: 241/255, blue: 46/255, alpha: 1))
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
        
        graphView.data = data
        
        
    }
  
}
