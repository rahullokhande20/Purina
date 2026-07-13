//
//  DetailsViewController.swift
//  Sample
//
//  Created by Sai Dammu on 4/9/21.
//

import UIKit
import DGCharts
import CoreBluetooth

class DetailsViewController: UIViewController,ChartViewDelegate,UITextFieldDelegate,CBPeripheralDelegate {
    var hexArray = [NSArray]()
    var tableView : UITableView!
    var graphView: LineChartView!
    var millisecondsGap = 0.1
    var valuesArr = NSMutableArray()
    let secondsArray = NSMutableArray()
    
    var peripheral : CBPeripheral!
    var char : CBCharacteristic!
    
    var txtfield : UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.view.endEditing(true)
        
        return true
    }
    
    @objc func writeButtonAction(){
        
        if txtfield.text!.count>0{
           // peripheral.setNotifyValue(true, for: char)
            let hexData = Data(hex: txtfield.text!)!
            peripheral.delegate = self
            peripheral.writeValue(hexData, for: char, type: CBCharacteristicWriteType.withResponse)
            peripheral.setNotifyValue(true, for: char)
            print("write ..!")
        }
    }
    /*
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let data = characteristic.value{
       
            let hexString = data.hexDescription.separate(every: 4, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            NotificationCenter.default.post(name: Notification.Name("NotifyValue"), object: hexArray)

        }
        
    }*/
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
       // let value = characteristic.value?.hexDescription
        if let data = characteristic.value{
            print("write ack \(data.hexDescription)")
            let hexString = data.hexDescription.separate(every: 4, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            NotificationCenter.default.post(name: Notification.Name("NotifyValue"), object: hexArray)

        }

    }
    private func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
          // if var data :NSData = characteristic.value {
            print("value rec")
               //output("Data", data: characteristic.value)
          // }

       }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.valuesRecieved), name: NSNotification.Name(rawValue: "NotifyValue"), object: nil)
        
        txtfield = UITextField()
        txtfield.delegate = self
        txtfield.placeholder = "Hex input"
        self.view.addSubview(txtfield)
        txtfield.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width-90, height: 40)
        
        let writeButton = UIButton()
        writeButton.setTitle("Write", for: .normal)
        writeButton.backgroundColor = .systemBlue
        writeButton.frame = CGRect(x: self.view.frame.size.width-80, y: 0, width: 75, height: 44)
        writeButton.addTarget(self, action: #selector(self.writeButtonAction), for: .touchUpInside)
        self.view.addSubview(writeButton)
        
        self.view.backgroundColor = .white
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 320, width: self.view.frame.size.width, height: self.view.frame.size.height-340)
        self.view.addSubview(tableView)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        graphView = LineChartView()
        graphView.frame = CGRect(x: 0, y: 50, width: self.view.frame.size.width, height: 250)
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
        self.view.addSubview(graphView)
        
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
    }
    
    @objc func backAction(){
        self.navigationController?.popViewController(animated: true)
        peripheral.setNotifyValue(false, for: char)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(true)
         
         self.navigationController?.navigationBar.isTranslucent = false
     }
     
    @objc func valuesRecieved(notification: Notification) {
        if let object = notification.object as? NSArray{
            hexArray.append(object)
            tableView.reloadData()
            print("Object \(object)")
            setDatacount()
            
            
            for i in object{
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
                }
   
            }
        }
        
    }
    
    @objc func setDatacount(){
        
        let values = NSMutableArray()
        
            
        millisecondsGap +=  0.1
                     
        for i in 0..<valuesArr.count{
            
            let value = ChartDataEntry(x: secondsArray[i] as! Double, y: valuesArr[i] as! Double)
            values.add(value)
            
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

extension DetailsViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hexArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let hexArr = hexArray[indexPath.row]
        cell?.textLabel?.text = hexArr.componentsJoined(by: "")
        return cell!
        
        
    }
    
    
}

extension Data {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else {
            return nil
        }
        
        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }
        
        guard hex.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }
}
