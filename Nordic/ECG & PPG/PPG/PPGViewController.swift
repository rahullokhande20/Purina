//
//  PPGViewController.swift
//  HeartMath
//
//  Created by Sai Dammu on 11/10/21.
//

import UIKit
import DGCharts
import CoreBluetooth

class PPGViewController: UIViewController {
    
    @IBOutlet weak var ppgGraph: LineChartView!
    var ppg = PPG()
    var millisecondsGap = 0.1
    var ppgValuesArray = NSMutableArray()
    let ppgSecondsArray = NSMutableArray()
    var ppgFileNameString : String!
    var actionType : String!
    var timer: Timer!
    var ppgPeripheral : CBPeripheral!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnected), name: NSNotification.Name(rawValue: "PPGPeripheral"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.ppgStart), name: NSNotification.Name(rawValue: "PPGStart"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.PPGSave), name: NSNotification.Name(rawValue: "PPGSave"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.ppgStop), name: NSNotification.Name(rawValue: "PPGStop"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.ppgWrite), name: NSNotification.Name(rawValue: "PPGwriteGain"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.ppgRead), name: NSNotification.Name(rawValue: "PPGReadGain"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.timerAction), name: NSNotification.Name(rawValue: "Timer"), object: nil)
        
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.setPpDatacount()
        }
        
        //ppgGraph.delegate = self;
        
        //graphView.chartDescription.enabled = false;
        
        ppgGraph.dragEnabled = false
        ppgGraph.setScaleEnabled(true)
        ppgGraph.drawGridBackgroundEnabled = false
        ppgGraph.pinchZoomEnabled = true
        ppgGraph.backgroundColor = .white
        
        ppgGraph.chartDescription.enabled = false
        ppgGraph.dragEnabled = false
        ppgGraph.setScaleEnabled(true)
        ppgGraph.pinchZoomEnabled = false
        ppgGraph.drawGridBackgroundEnabled = false
        ppgGraph.highlightPerDragEnabled = true
        ppgGraph.backgroundColor = .clear
        ppgGraph.legend.enabled = false
        
        let l = ppgGraph.legend
        l.form = .line
        l.font = UIFont.systemFont(ofSize: 0)
        l.textColor = .white
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        
        let xAxis = ppgGraph.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 0)
        xAxis.labelTextColor = .white
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        
        
        let leftAxis = ppgGraph.leftAxis
        leftAxis.labelFont = UIFont.systemFont(ofSize: 10)
        leftAxis.labelTextColor = .black
        leftAxis.drawGridLinesEnabled = true;
        leftAxis.drawZeroLineEnabled = false;
        leftAxis.granularityEnabled = true;
        
        let rightAxis = ppgGraph.rightAxis
        rightAxis.labelFont = UIFont.systemFont(ofSize: 10)
        rightAxis.labelTextColor = .black
        rightAxis.drawGridLinesEnabled = true;
        rightAxis.drawZeroLineEnabled = false;
        rightAxis.granularityEnabled = true;
        
        
        
        
    }
    
    @objc func PPGSave(){
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
        let dateString = formatter.string(from: date)
        
        ppgFileNameString = "\(singlton.shared.ecgPPGfileName!)_\(ppgPeripheral.name!):\(dateString).txt"
     
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(self.ppgFileNameString)
            
            do {
                
                try " ".write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
            
        }
        
    }
    
    @objc func timerAction(){
        timer.invalidate()
    }
    
    @objc func ppgWrite(noti:Notification){
        
        actionType = "Write"
        if let writeGain = noti.userInfo?["writeGain"] as? String{
            ppg.writeGain(writeGainSelected: writeGain) 
        }
        
    }
    
    @objc func ppgRead(){
        actionType = "Read"
        ppg.readGain()
    }
    
    
    func updatePPGGraph(_ ppgData : Data){
        
        
        var valString = ppgData.map { String(format: "%02hhx", $0) }.joined()
        //        print("graph packet before :\(valString)")
        
        let hexString = ppgData.hexDescription.separate(every: 2, with: " ")
        //        print("graph packet check :\(hexString)")
        let hexArray = hexString.components(separatedBy: " ")
        
        if actionType == "Write"{
            if hexArray.count == 6{
                
                if hexArray[4] == "00"{
                    let alert = UIAlertController(title: nil, message: "Gain written", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else{
                    let alert = UIAlertController(title: nil, message: "Gain not updated, please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }
        }
        else if actionType == "Read"{
            
            if hexArray.count == 6{
                
                if hexArray[4] == "00"{
                    print("Read gain success")
                }
            }
            
            if hexArray.count == 7 {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WrittenGainPPG"), object: nil, userInfo: ["WrittenGainPPG": hexArray[5]])
                
                
            }
            
        }
        
        
        if valString.count == 86 || valString.count<34{
            return
        }
        
        //Validation for purina board
        if valString.count == 74 /*|| valString.count == 86*/{
            valString = String(valString.dropFirst(8))
            valString = String(valString.dropLast(2))
        }
        
        // validation for hearthMath
        else{
            
            if valString.count == 34{
                valString = String(valString.dropLast(2))
            }
            if valString.contains("ab220201"){
                valString = String(valString.dropFirst(8))
                
            }
        }
        
        
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
                    
                    let value = "\(first)\(second)\(third)\(fourth)"
                    let intValue = UInt32(value, radix:16)
                    
                    valuesArray.append(Int("\(intValue!)")!)
                    
                    
                }
                
            }
        }
        
        addValuesToPpggraph(valuesArray)
        
        
    }
    
    func addValuesToPpggraph(_ valuesArray:[Int]){
        
        //    if !isPlotting{ return }
        
        //    if index%2==0{
        
        for i in 0..<valuesArray.count{
            millisecondsGap +=  0.1
            
            self.ppgValuesArray.add(valuesArray[i])
            ppgSecondsArray.add(millisecondsGap)
            
            if self.ppgValuesArray.count>1280{
                self.ppgValuesArray.removeObject(at: 0)
                self.ppgValuesArray.removeObject(at: 0)
            }
            
            
            
            
            if let saveEcg = singlton.shared.saveEcgPpgText {
                if saveEcg == true{
                    
                    let valueString = "\(valuesArray[i])"
                    
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileurl = dir.appendingPathComponent(self.ppgFileNameString ?? "PPG")
                        
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
    
    
    @objc func setPpDatacount(){
        
        let values = NSMutableArray()
        
        for i in 0..<ppgValuesArray.count{
            
            let value = ChartDataEntry(x: ppgSecondsArray[i] as! Double, y: ppgValuesArray[i] as! Double)
            values.add(value)
            
        }
        
        if let minVal = (ppgValuesArray as! [Int]).min(),let maxVal = (ppgValuesArray as! [Int]).max(){
            
            ppgGraph.rightAxis.axisMinimum = Double(minVal-100)
            ppgGraph.leftAxis.axisMinimum = Double(minVal-100)
            ppgGraph.rightAxis.axisMaximum = Double(maxVal+100)
            ppgGraph.leftAxis.axisMaximum = Double(maxVal+100)
            
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
        
        ppgGraph.data = data
        
        
    }
    
    @objc func ppgStart(noti:Notification){
        ppg.start()
    }
    @objc func ppgStop(noti:Notification){
        ppg.stop()
    }
    
    @objc func deviceConnected(notification:Notification){
        if let peri = notification.userInfo?["peri"] as? CBPeripheral{
            ppg.readGain()
            ppgPeripheral = peri
            ppg.discvoer(ppgPeripheral: peri)
            ppg.update = { data in
                
                self.updatePPGGraph(data)
                print("value rec ppg")
                
            }
        }
    }
    
}
