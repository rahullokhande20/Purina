//
//  PPGViewController.swift
//  LD-Sana
//
//  Created by Sai Dammu on 5/14/21.
//

import UIKit
import DGCharts
import CoreBluetooth
import MBProgressHUD

class PPGOldViewController: UIViewController,CBPeripheralDelegate,ChartViewDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var saveTxtButton: UIButton!
    @IBOutlet weak var graphView: LineChartView!
    var characteristic : CBCharacteristic!
    var timer:Timer?
    var vvaluesArray = NSMutableArray()
    let secondsArray = NSMutableArray()
    var millisecondsGap = 0.1
    var fileNameString = String()
    var values  = String()
    var isWritingToTXT = false
    var isPlotting = false
    var peripheral : CBPeripheral!
    var index = 0
    var writeIndex = 0
    var graphIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Biometric"
       // saveTxtButton.isHidden = true
        singlton.shared.peripheral.delegate = self
        singlton.shared.peripheral.discoverServices(nil)
        // characteristic = singlton.shared.char
        startStopButton.layer.cornerRadius = 5
        startStopButton.clipsToBounds = true
        startStopButton.tag = 1
        
        startStopButton.setTitleColor(.white, for: .normal)
        
        graphView.delegate = self
        graphView.chartDescription.enabled = false
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
        
        saveTxtButton.setTitle("START TXT", for: .normal)
        saveTxtButton.isHidden = true
      
        
    }
    
    @IBAction func startStopSaving(_ sender: Any) {
        
        isWritingToTXT = !isWritingToTXT
        
        if isWritingToTXT {
            //saveTxtButton.setImage(UIImage(named: "writing"), for: .normal)
            saveTxtButton.setTitle("STOP TXT", for: .normal)
        }else{
           // saveTxtButton.setImage(UIImage(named: "stopWrite"), for: .normal)
            saveTxtButton.setTitle("START TXT", for: .normal)
        }
    }
    
    @IBAction func startStopButton(_ sender: Any) {
        
        if startStopButton.tag == 1{
            isPlotting = true
            saveTxtButton.isHidden = false
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
            let dateString = formatter.string(from: date)
            fileNameString = "PPG_\(dateString).txt"
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent(self.fileNameString)
                                
                do {
                    try "\n".write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print(error)
                }
            }
            
            graphView.noDataText = "Calibrating..."
            graphView.setNeedsDisplay()
            //start
            startStopButton.tag = 0
            startStopButton.setTitle("STOP", for: .normal)
            if let peripheral = singlton.shared.peripheral{
                let writeData = Utils.sharedInst()?.startBioMetricGraph()
                peripheral.writeValue(writeData!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
            
        }else{
            isWritingToTXT = false
            saveTxtButton.setTitle("START TXT", for: .normal)
            saveTxtButton.isHidden = true
            
            graphView.noDataText = "No data available"
            graphView.setNeedsDisplay()
            
            startStopButton.tag = 1
            startStopButton.setTitle("START", for: .normal)
            
            
            if let peripheral = singlton.shared.peripheral{
                isPlotting = false
                //Start command
                timer?.invalidate()
                self.vvaluesArray.removeAllObjects()
                let writeData = Utils.sharedInst()?.stopBioMetricGraph()
                peripheral.writeValue(writeData!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                
            }
        }
        
    }
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
            let hexString = data.hexDescription.separate(every: 4, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            
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
        print("char118 \(service.characteristics)")
        for newChar: CBCharacteristic in service.characteristics!{
            print("ccb \(newChar.properties.rawValue)")
            // MBProgressHUD.hide(for: self.view, animated: true)
            
            //  if newChar.value != nil{
            
            if newChar.properties == CBCharacteristicProperties.notify{
                peripheral.setNotifyValue(true, for: newChar)
            }
            else {
                
                self.characteristic = newChar
                
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
    func addValuesTograph(_ valuesArray:[Int])   {
        if !isPlotting { return }
        graphIndex += 1
        //    if index%2==0{
        print("graph value count \(valuesArray.count)")
        for i in 0..<valuesArray.count{
            millisecondsGap +=  0.1
            
            self.vvaluesArray.add(valuesArray[i])
            secondsArray.add(millisecondsGap)
            
            if self.vvaluesArray.count>640{
                self.vvaluesArray.removeObject(at: 0)
                self.secondsArray.removeObject(at: 0)
            }
            
            DispatchQueue.main.async { 
       
                                    
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
        if graphIndex%12 == 0{
            self.setDataCount()
        }
        
    }
    
        
        func setDataCount(){
            
            let values = NSMutableArray()
            
           
            for i in 0..<vvaluesArray.count{
                if i == 192{
                    
                    break
                }else{
                    
                    let value = ChartDataEntry(x: secondsArray[i] as! Double, y: vvaluesArray[0] as! Double)
                    values.add(value)
                    vvaluesArray.removeObject(at: 0)
                }
                
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
