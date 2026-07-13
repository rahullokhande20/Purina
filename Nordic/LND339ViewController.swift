//
//  LND339ViewController.swift
//  Purina
//
//  Created by Sai Dammu on 8/9/21.
//

import UIKit
import DropDown
import DGCharts
import CoreBluetooth
import MRHexKeyboard
import MBProgressHUD

final class LND339ViewController: UIViewController, CBPeripheralDelegate, ChartViewDelegate, UITextFieldDelegate {

    private enum Constants {
        static let navigationTitle = "Biometrics"
        static let startGraphTitle = "Start Graph"
        static let stopGraphTitle = "Stop Graph"
        static let startSavingTitle = "Start saving"
        static let stopSavingTitle = "Stop saving"
        static let okTitle = "OK"
        static let okayTitle = "Okay"
        static let missingGainMessage = "Gain is required"
        static let missingCurrentMessage = "Current is required"
        static let missingFileMetadataTitle = "Breed/location is empty"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }
    
    let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
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
    @IBOutlet weak var writeCurrentTextfield: UITextField!
    @IBOutlet weak var readGainLabel : UILabel!
    @IBOutlet weak var readCurrentLabel : UILabel!
    //@IBOutlet weak var writeGain2Textfield: UITextField!
    
    // @IBOutlet weak var readGain2Textfield: UITextField!
    
    //   @IBOutlet weak var readButton: UIButton!
    //  @IBOutlet weak var writeButton: UIButton!
    
    var graphCount = 0
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
    var titleString : String!
    var serviceType = ""
    
    var gainDropdown = DropDown()
    var currentDropdown = DropDown()
    var hexArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C","0D","0E","0F"]
    var dropDownArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15"]
    var writeGainSelected : String!
    var writeCurrentSelected : String!
    var isFirst = true
    var newWritePacket = true
    var writePacketGain : String!
    var writePacketCurrent : String!
    var isStopPacket = false
    var writePacket : String!
    var writePacketString : String!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.navigationTitle
        configureDropdowns()
        configureActionButtons()
        configureChart()
        configureBluetooth()
        newWritePacket = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
    }

    private func configureDropdowns() {
        configureDropdown(
            dropdown: gainDropdown,
            textField: writeGainTextfield,
            action: #selector(writeGainDropDown)
        ) { [weak self] index in
            guard let self else { return }
            self.writeGainSelected = self.hexArray[index]
            self.writeGainTextfield.text = self.dropDownArray[index]
        }

        configureDropdown(
            dropdown: currentDropdown,
            textField: writeCurrentTextfield,
            action: #selector(writeCurrentDropDown)
        ) { [weak self] index in
            guard let self else { return }
            self.writeCurrentSelected = self.hexArray[index]
            self.writeCurrentTextfield.text = self.dropDownArray[index]
        }
    }

    private func configureDropdown(
        dropdown: DropDown,
        textField: UITextField,
        action: Selector,
        selection: @escaping (Int) -> Void
    ) {
        textField.inputView = UIView()
        textField.isUserInteractionEnabled = true
        textField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        dropdown.dataSource = dropDownArray
        dropdown.anchorView = textField
        dropdown.selectionAction = { [weak dropdown] index, item in
            print("Selected item: \(item) at index: \(index)")
            dropdown?.hide()
            selection(index)
        }
    }

    private func configureActionButtons() {
        styleActionButton(graphButton, fillColor: DesignSystem.Palette.brand)
        styleActionButton(txtButton, fillColor: DesignSystem.Palette.document)

        graphButton.addTarget(self, action: #selector(graphButtonAction), for: .touchUpInside)
        txtButton.addTarget(self, action: #selector(txtButtonAction), for: .touchUpInside)
        txtButton.tag = 1
        txtButton.setTitle(Constants.startSavingTitle, for: .normal)
        setGraphRunning(false, animated: false)
    }

    private func styleActionButton(_ button: UIButton, fillColor: UIColor) {
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.backgroundColor = fillColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Typography.button
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func configureBluetooth() {
        peripheral = singlton.shared.peripheral
        peripheral?.delegate = self
        peripheral?.discoverServices(nil)
    }

    private func configureChart() {
        graphView.delegate = self
        graphView.chartDescription.enabled = false
        graphView.dragEnabled = false
        graphView.setScaleEnabled(true)
        graphView.pinchZoomEnabled = false
        graphView.drawGridBackgroundEnabled = false
        graphView.highlightPerDragEnabled = true
        graphView.backgroundColor = .clear
        graphView.legend.enabled = false

        let legend = graphView.legend
        legend.form = .line
        legend.font = UIFont.systemFont(ofSize: 10)
        legend.textColor = DesignSystem.Palette.secondaryText
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false

        let xAxis = graphView.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis.labelTextColor = DesignSystem.Palette.secondaryText
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false

        configureAxis(graphView.leftAxis)
        configureAxis(graphView.rightAxis)
    }

    private func configureAxis(_ axis: YAxis) {
        axis.labelTextColor = DesignSystem.Palette.secondaryText
        axis.gridColor = DesignSystem.Palette.secondaryText.withAlphaComponent(0.18)
        axis.drawGridLinesEnabled = true
        axis.drawZeroLineEnabled = false
        axis.granularityEnabled = true
    }

    private func setGraphRunning(_ running: Bool, animated: Bool = true) {
        isPlotting = running
        isGraphRunning = running
        graphButton.tag = running ? 0 : 1

        let updates = {
            self.graphButton.setTitle(running ? Constants.stopGraphTitle : Constants.startGraphTitle, for: .normal)
            self.txtButton.isHidden = !running
        }

        guard animated else {
            updates()
            return
        }
        UIView.transition(
            with: graphButton,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: updates
        )
        UIView.transition(
            with: txtButton,
            duration: DesignSystem.Motion.transitionDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: updates
        )
    }

    private func setSaving(_ saving: Bool) {
        txtButton.tag = saving ? 0 : 1
        txtButton.setTitle(saving ? Constants.stopSavingTitle : Constants.startSavingTitle, for: .normal)
        stopSaving = !saving
    }

    private func presentAlert(title: String? = nil, message: String? = nil, actionTitle: String = Constants.okTitle) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func backAction(){
       // self.navigationController?.popViewController(animated: true)
      //  peripheral.setNotifyValue(false, for: char)
        if isGraphRunning {
            newWritePacket = false
            isStopPacket = true
            MBProgressHUD.showAdded(to: view, animated: true)
            setGraphRunning(false)
            //  writeAction("AB020205F7")
            
            if let peripheral = singlton.shared.peripheral{
                
                if self.titleString == "DiscOpt"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphDiscOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "DigiOpt"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphDigiOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "LND339"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                peripheral.setNotifyValue(true, for: char)
            }
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
    
    @IBAction func writeGainAction(){
        
        guard writeGainSelected != nil else {
            presentAlert(message: Constants.missingGainMessage)
            return
        }
        newWritePacket = true
        
        let value1Int = UInt8(writeGainSelected, radix:16)
        let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
        
        peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        if self.titleString == "DiscOpt"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainDiscOpt(Int32(value1Int!))
            writePacketGain = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "DigiOpt"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainDigiOpt(Int32(value1Int!))
            writePacketGain = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "LND339"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
            writePacketGain = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        peripheral.setNotifyValue(true, for: char)
        

        presentAlert(message: "Gain written")
        
        
    }
    @IBAction func readGainAction(){
        serviceType = "Gain"
               
        if self.titleString == "DiscOpt"{
            let writeData = Utils.sharedInst()?.sendReadGainDiscOpt()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "DigiOpt"{
            let writeData = Utils.sharedInst()?.sendReadGainDigiOpt()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "LND339"{
            let writeData = Utils.sharedInst()?.sendReadGainLND()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        peripheral.setNotifyValue(true, for: char)
    }
    @IBAction func readCurrentAction(){
        serviceType = "Current"
                
        if self.titleString == "DiscOpt"{
            let writeData = Utils.sharedInst()?.sendReadCurrentDiscOpt()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "DigiOpt"{
            let writeData = Utils.sharedInst()?.sendReadCurrentDigiOpt()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "LND339"{
            let writeData = Utils.sharedInst()?.sendReadCurrentLND()
            peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        
        peripheral.setNotifyValue(true, for: char)
    }
    
    @IBAction func writeCurrentAction(){
        
        guard writeCurrentSelected != nil else {
            presentAlert(message: Constants.missingCurrentMessage)
            return
        }
        newWritePacket = true
        let value1Int = UInt8(writeCurrentSelected, radix:16)
        if self.titleString == "DiscOpt"{
            let responseDict = Utils.sharedInst()?.sendWriteCurrentDiscOpt(Int32(value1Int!))
            writePacketCurrent = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
            peripheral.setNotifyValue(true, for: char)
        }
        else if self.titleString == "DigiOpt"{
            let responseDict = Utils.sharedInst()?.sendWriteCurrentDigiOpt(Int32(value1Int!))
            writePacketCurrent = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
            peripheral.setNotifyValue(true, for: char)
        }
        else if self.titleString == "LND339"{
            let responseDict = Utils.sharedInst()?.sendWriteCurrentLND(Int32(value1Int!))
            writePacketCurrent = responseDict!["Packet"] as? String ?? ""
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
            peripheral.setNotifyValue(true, for: char)
        }
        
     
        
        presentAlert(message: "Current written")
        
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
    
    
    @objc func txtButtonAction(_ sender: UIButton){
        
        if !isGraphRunning {
            return
        }
        if txtButton.tag == 0{
            
            setSaving(false)
            
        }else{
            
            if breedTextfield.text == "" || locationTextfield.text == ""{
                presentAlert(title: Constants.missingFileMetadataTitle, actionTitle: Constants.okayTitle)
                
            }else{
            setSaving(true)
            
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
            let dateString = formatter.string(from: date)
            fileNameString = "\(breedTextfield.text ?? "")_\(locationTextfield.text ?? ""):\(dateString)-\(titleString ?? "").txt"
            fileNameString = fileNameString.replacingOccurrences(of: " ", with: "_")
            if writePacket == nil{
                writePacket = ""
            }
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let fileURL = dir.appendingPathComponent(self.fileNameString)
                
                do {
                    
                    try self.writePacket.write(to: fileURL, atomically: false, encoding: .utf8)
                    stopSaving = false
                }
                catch {/* error handling here */}
                
            }
            
            }
            
        }
        
        
    }
    
    
    
    
    
    @objc func graphButtonAction(_ sender: UIButton){
        
        if graphButton.tag == 1{
            
            setGraphRunning(true)
            // writeAction("AB020201FB")
            
            if let peripheral = singlton.shared.peripheral{
                if self.titleString == "DiscOpt"{
                    let writeData = Utils.sharedInst()?.startBioMetricGraphDiscOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "DigiOpt"{
                    let writeData = Utils.sharedInst()?.startBioMetricGraphDigiOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }else if self.titleString == "LND339"{
                    let writeData = Utils.sharedInst()?.startECGPPGGraph()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                
                peripheral.setNotifyValue(true, for: char)
            }
            
            
            
        }else{
            setGraphRunning(false)
            //  writeAction("AB020205F7")
            
            if let peripheral = singlton.shared.peripheral{
                if self.titleString == "DiscOpt"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphDiscOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "DigiOpt"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphDigiOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "LND339"{
                    let writeData = Utils.sharedInst()?.stopBioMetricGraphLND()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                
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
        
        
        if let data = characteristic.value{
            //var hexStr = data.hexString.dropFirst(4)
            print("resp: \(data.hexDescription)")
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")
            if hexArray.count>4{
                if hexArray[hexArray.count-2] == "00" && isStopPacket{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
            
            
            if hexArray.count == 13{
                DispatchQueue.main.async {
                    
                    if self.serviceType == "Gain"{
                        
                        if let value = UInt8(hexArray[11], radix:16){
                            self.readGainLabel.text = "\(value)"
                        }
                        if self.isFirst{
                            self.readCurrentAction()
                            self.isFirst = false
                        }
                        
                    }
                    else{
                        self.readCurrentLabel.text = hexArray[11]
                    }
                    
                    
                    
                }
                
                if newWritePacket{
                  
                    let hexString = data.hexDescription.separate(every: 2, with: " ")
                    let hexArray = hexString.components(separatedBy: " ")
                    
                    if hexArray[4] == "00"{
                        writePacketGain = hexArray[11]
                        if let value = UInt8(hexArray[11], radix:16){
                            self.readGainLabel.text = "\(value)"
                        }
                    }
                    
                    else if hexArray[4] == "02"{
                        writePacketCurrent = hexArray[5]
                        self.readCurrentLabel.text = hexArray[11]
                    }
                   /* if writePacketGain != nil && writePacketCurrent != nil{
                        writePacket = writePacketGain + writePacketCurrent + "0000"
                        writePacket = "\(writePacket ?? "" )\n"
                        newWritePacket = false
                    }
 */
                    if writePacketGain != nil {
                         writePacket = writePacketGain + "00" + "0000"
                         writePacket = "\(writePacket ?? "" )\n"
                         newWritePacket = false
                     }
                   
                       
                       // let valueString = writePacket
                    
                }
            }
            else if hexArray.count == 12{
                if newWritePacket{
                    
                    if self.stopSaving == false{
                       // let valueString = writePacket
                    if self.writePacketGain == nil {/*|| self.writePacketCurrent == nil{*/
                        return
                    }
                        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileurl = dir.appendingPathComponent(self.fileNameString)
                          
                            let writePacket = writePacketGain + "00" + "0000"
                            let string = "\(writePacket )\n"
                            
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
                                        
                    newWritePacket = false
                    }
                }
                else if isStopPacket{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.navigationController?.popViewController(animated: true)
                }
            }
          
            updateGraph(data)
        }else {
            print("value recieved nil")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover char")
        if let error {
            print("[ERROR] Error discovering characteristics. \(error.localizedDescription)")
            return
        }
        print("char112 \(service.characteristics ?? [])")
        for newChar in service.characteristics ?? [] {
            print("ccb \(newChar.properties.rawValue)")
            if newChar.properties == CBCharacteristicProperties.notify{
                peripheral.setNotifyValue(true, for: newChar)
                if isFirst{
                   
                    self.readGainAction()
                }
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
//            let service = foundServices[0]
//            peripheral.discoverCharacteristics(nil, for: service)
            for service in foundServices{
                if service.uuid == uartUUID{
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            
            
            
        }
        
    }
    
    func updateGraph(_ ppgData : Data){
        
        
        var valString = ppgData.map { String(format: "%02hhx", $0) }.joined()
        print("graph packet before :\(valString)")
        
        
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
        
       
        print("graph packet after:\(valString)")
   
        
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
                //    index += 1
            }
        }
       
        addValuesTograph(valuesArray)
        
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
         
            self.vvaluesArray.add(valuesArray[i])
            secondsArray.add(millisecondsGap)
            
            if self.vvaluesArray.count>2560{
                self.vvaluesArray.removeObject(at: 0)
                self.secondsArray.removeObject(at: 0)
            }
            graphCount += 1
           // DispatchQueue.main.async {
                if self.stopSaving==false{
                let valueString = "\(valuesArray[i])"

                    if fileNameString ==  nil{
                        return
                    }

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
//        if graphCount%10 == 0{
//            self.setDatacount()
//        }

        
        self.setDatacount()
        
    }
    @objc func setDatacount(){
        
        let values = NSMutableArray()
        
        for i in 0..<vvaluesArray.count{
           /* if i == 1600{
                
                break
            }else{ */
                
                let value = ChartDataEntry(x: secondsArray[i] as! Double, y: vvaluesArray[i] as! Double)
                values.add(value)
               //\ vvaluesArray.removeObject(at: 0)
           // }
            
        }
        
        if let minVal = (vvaluesArray as! [Int]).min(),let maxVal = (vvaluesArray as! [Int]).max(){
            
            graphView.rightAxis.axisMinimum = Double(minVal-400)
            graphView.leftAxis.axisMinimum = Double(minVal-400)
            graphView.rightAxis.axisMaximum = Double(maxVal+400)
            graphView.leftAxis.axisMaximum = Double(maxVal+400)
            
        }
        let set1 = LineChartDataSet(entries: values as? [ChartDataEntry] ?? [], label: "DataSet 1")
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 47/255, green: 109/255, blue: 216/255, alpha: 1))
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
