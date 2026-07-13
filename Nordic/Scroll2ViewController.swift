//
//  PPGViewController.swift
//  HeartMath
//
//  Created by Sai Dammu on 11/10/21.
//

import UIKit
import DGCharts
import CoreBluetooth

class Scroll2ViewController: UIViewController {
    
    @IBOutlet weak var ppgGraph: LineChartView!
    var ppg = PPG()
    var millisecondsGap = 0.1
    var ppgValuesArray = NSMutableArray()
    let ppgSecondsArray = NSMutableArray()
    var ppgFileNameString : String!
    var actionType : String!
    var timer: Timer!
    var ppgPeripheral : CBPeripheral!
    
    var previousNo : Int!
    var previousPacket : String!
    var valString = ""
    var readGainString = ""
    var activityString = ""
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.ppgReadFromLabel), name: NSNotification.Name(rawValue: "PPGRead"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.activityUpdate), name: NSNotification.Name(rawValue: "activityUpdate"), object: nil)
        
        
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
    
    @objc func ppgReadFromLabel(noti: Notification){
        if let readGain = noti.userInfo?["PPG"] as? String{
            readGainString = readGain
        }
    }
    
 
    
    @objc func activityUpdate(noti: Notification){
        if let activityStr = noti.userInfo?["activity"] as? String{
            activityString = activityStr
        }
    }
    
    
    
    
    @objc func PPGSave(){
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
        let dateString = formatter.string(from: date)
        
        ppgFileNameString = "\(singlton.shared.ecgPPGfileName!)_\(ppgPeripheral.name!):\(dateString).txt"
        ppgFileNameString = ppgFileNameString.replacingOccurrences(of: " ", with: "_")
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(self.ppgFileNameString)
            
            do {
                
                try "PS , Data , PS State , Gain , Channel , Activity\n".write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
            
        }
        
    }
    
    @objc func timerAction(){
        timer.invalidate()
    }
    
    @objc func ppgWrite(noti:Notification){
        
        if ppgPeripheral != nil{
            actionType = "Write"
            if let writeGain = noti.userInfo?["writeGain"] as? String{
                ppg.writeGain(writeGainSelected: writeGain)
            }
        }else{
            let alert = UIAlertController(title: nil, message: "Please connect to the devices", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @objc func ppgRead(){
        
        if ppgPeripheral != nil{
            
            actionType = "Read"
            ppg.readGain()
        }
        else{
            let alert = UIAlertController(title: nil, message: "Please connect to the devices", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
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
                    ppgRead()
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
        if valString.count == 80 /*|| valString.count == 86*/{
            
            self.updateGraph(ppgData)
          
        }
        
        // validation for hearthMath
//        else{
//
//            if valString.count == 34{
//                valString = String(valString.dropLast(2))
//            }
//            if valString.contains("ab220201"){
//                valString = String(valString.dropFirst(8))
//
//            }
//        }
    
        
    }
    
    
    func updateGraph(_ ppgData : Data){
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
                    print("miss Pack1: ",missedPack)
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
                    print("miss Pack1: ",missedPack)
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
            print("Cuur Pack1: ",packetString)
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
            addValuesToPpggraph(Int(decimalValue))
            
                
            if let saveEcg = singlton.shared.saveEcgPpgText {
                if saveEcg == true{
                 
                
                    
                    let valueString = "\(currNo), \(decimalValue), \(isModified ? 1 : 0), \(self.readGainString), 0 , \(activityString)"
                    
                    
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
    
    
    func addValuesToPpggraph(_ value:Int){
        
      
            millisecondsGap +=  0.1
            
            self.ppgValuesArray.add(value)
            ppgSecondsArray.add(millisecondsGap)
            
            if self.ppgValuesArray.count>1280{
                self.ppgValuesArray.removeObject(at: 0)
                self.ppgValuesArray.removeObject(at: 0)
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
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.ppgRead()
            }
            ppgPeripheral = peri
            ppg.discvoer(ppgPeripheral: peri)
            ppg.update = { data in
                self.updatePPGGraph(data)
                print("value rec ppg")
                
            }
        }
    }
    
}

