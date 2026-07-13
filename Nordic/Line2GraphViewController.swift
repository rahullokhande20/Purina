//
//  Line2GraphViewController.swift
//  Purina
//
//  Created by Sai Dammu on 2/9/22.
//

import UIKit
import DGCharts
import CoreBluetooth

class Line2GraphViewController: UIViewController {
    @IBOutlet weak var graphView: LineChartView!
    var vvalues2Array = NSMutableArray()
    var millisecondsGap = 0.1
    let secondsArray = NSMutableArray()
    var dataString = ""
    var timer : Timer!
    var line2 = Line2()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.line2Connect), name: NSNotification.Name(rawValue: "Line2Connect"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.line2Start), name: NSNotification.Name(rawValue: "Line2Start"), object: nil)
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.setDatacount()
        }
    }
    
    @objc func setDatacount(){
        
        //Line 1
        var values2 = [ChartDataEntry]()
        for i in 0..<vvalues2Array.count{
            let value2 = ChartDataEntry(x: secondsArray[i] as! Double, y: vvalues2Array[i] as! Double)
            values2.append(value2)
        }
        let set2 = LineChartDataSet(entries: values2 , label: "No name")
        set2.lineWidth = 2
        set2.setColor(.blue)
        set2.axisDependency = .left
        set2.drawCirclesEnabled = false
        set2.drawCircleHoleEnabled = false
        
        
        let data = LineChartData(dataSet: set2)
        graphView.data = data
        
        
    }
    
    @objc func line2Start(notification:Notification){
        
        line2.start()
        
    }
    
    @objc func line2Connect(notification:Notification){
        if let peri = notification.userInfo?["peri"] as? CBPeripheral{
//            ppgPeripheral = peri
           
            line2.discvoer(peripheral: peri)
            line2.update = { data in
                self.updateLine2Graph(data)
                
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
        
//        if !isPlotting{ return }

        
        for i in 0..<valuesArray.count{
            
                millisecondsGap +=  0.1
                
                self.vvalues2Array.add(valuesArray[i])
                secondsArray.add(millisecondsGap)
                
                if self.vvalues2Array.count>2560{
                    self.vvalues2Array.removeObject(at: 0)
                    self.secondsArray.removeObject(at: 0)
                }
                
//                if self.stopSaving{ return }
//                let valueString = "\(valuesArray[i])"
//
//                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                    let fileurl = dir.appendingPathComponent(self.fileNameString2)
//                    let string = "\(valueString)\n"
//                    let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)!
//
//                    if FileManager.default.fileExists(atPath: fileurl.path) {
//                        do {
//                            let fileHandle = try FileHandle(forWritingTo: fileurl)
//                            fileHandle.seekToEndOfFile()
//                            fileHandle.write(data)
//                            fileHandle.closeFile()
//                        }
//                        catch let error{
//                            print("could write into txt \(error.localizedDescription)")
//                        }
//
//                    }
//                }
            
        }
    }

}
