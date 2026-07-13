//
//  LND2ViewController.swift
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

final class LND2ViewController: UIViewController, CBPeripheralDelegate, ChartViewDelegate, UITextFieldDelegate {

    private enum Constants {
        static let navigationTitle = "ECG"
        static let startGraphTitle = "Start Graph"
        static let stopGraphTitle = "Stop Graph"
        static let startSavingTitle = "Start saving"
        static let stopSavingTitle = "Stop saving"
        static let okTitle = "OK"
        static let okayTitle = "Okay"
        static let missingGainMessage = "Gain is required"
        static let gainWrittenMessage = "Gain written"
        static let missingActivityMessage = "Please select activity"
        static let missingNameMessage = "Please enter valid name"
        static let sensorNotDetectedMessage = "Sensor not detected"
        static let acceptableCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ "
    }

    // MARK: Outlets

    @IBOutlet weak var txtButton : UIButton!
    @IBOutlet weak var graphButton : UIButton!
    @IBOutlet weak var graphView: LineChartView!
    @IBOutlet weak var breedTextfield : UITextField!
    @IBOutlet weak var locationTextfield : UITextField!

    @IBOutlet weak var writeGainTextfield: UITextField!
    @IBOutlet weak var readGainLabel : UILabel!
    @IBOutlet weak var readCurrentLabel : UILabel!
    @IBOutlet weak var activityTextfield: UITextField!

    // MARK: Dropdowns

    var gainDropdown = DropDown()
    var activityDropdown = DropDown()

    let activityArray = ["Laying Down","Sitting","Standing","Walking","Running","Playing","Eating","Drinking", "Other"]
    var hexGainArray : [String]!
    var dropDownGainArray : [String]!

    var writeGainSelected : String!
    var activityIndexString : String!

    // MARK: Bluetooth State

    let uartUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    var peripheral : CBPeripheral!
    var char : CBCharacteristic!
    var titleString : String!
    var serviceType = ""
    var isGainWritten = false
    var isFirst = true

    // MARK: Packet / Saving State

    var valString = ""
    var previousNo : Int!
    var previousPacket : String!
    var fileNameString : String!
    var stopSaving = true
    var newWritePacket = true
    var writePacketGain : String!
    var isStopPacket = false
    var writePacket : String!

    // MARK: Graph State

    var millisecondsGap = 0.1
    let secondsArray = NSMutableArray()
    var vvaluesArray = NSMutableArray()
    var isGraphRunning = false
    var isPlotting = false
    var startDate : Date!
    var startDelay : Double!
    var lapTIme = 0
    var timer : Timer!

    // MARK: Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.navigationTitle
        configureTextFields()
        configureGainOptions()
        configureDropdowns()
        configureActionButtons()
        configureChart()
        configureBluetooth()
        newWritePacket = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
        startTimer()
    }

    // MARK: Setup

    private func configureTextFields() {
        breedTextfield.autocorrectionType = .no
        locationTextfield.autocorrectionType = .no
    }

    /// The available gain values depend on the connected board type.
    private func configureGainOptions() {
        if self.titleString == "DiscOpt"{
            hexGainArray = ["00","01","02","03","04","05"]
            dropDownGainArray = ["00","01","02","03","04","05"]
        }
        else if self.titleString == "DigiOpt"{
            hexGainArray = ["00","01","02"]
            dropDownGainArray = ["00","01","02"]
        }
        else if self.titleString == "LND339"{
            hexGainArray = ["00","01","02","03","04","05","06","07","08","09","0A","0B","0C"]
            dropDownGainArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
        }
    }

    private func configureDropdowns() {
        configureDropdown(
            dropdown: gainDropdown,
            textField: writeGainTextfield,
            dataSource: dropDownGainArray,
            action: #selector(writeGainDropDown)
        ) { [weak self] index in
            guard let self else { return }
            self.writeGainSelected = self.hexGainArray[index]
            self.writeGainTextfield.text = self.dropDownGainArray[index]
        }

        configureDropdown(
            dropdown: activityDropdown,
            textField: activityTextfield,
            dataSource: activityArray,
            action: #selector(activityDropdownAction)
        ) { [weak self] index in
            guard let self else { return }
            self.activityIndexString = "0\(index)"
            self.activityTextfield.text = self.activityArray[index]
        }
    }

    private func configureDropdown(
        dropdown: DropDown,
        textField: UITextField,
        dataSource: [String],
        action: Selector,
        selection: @escaping (Int) -> Void
    ) {
        textField.inputView = UIView()
        textField.isUserInteractionEnabled = true
        textField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        dropdown.dataSource = dataSource
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

    // MARK: UI State

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

    private func presentAlert(
        title: String? = nil,
        message: String? = nil,
        actionTitle: String = Constants.okTitle,
        handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        present(alert, animated: true)
    }

    // MARK: File Saving

    /// Appends a line to the currently recording capture file, if it exists.
    private func appendToSavedFile(_ string: String) {
        guard
            let fileName = fileNameString,
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let fileURL = dir.appendingPathComponent(fileName)
        guard
            FileManager.default.fileExists(atPath: fileURL.path),
            let data = string.data(using: .utf8)
        else { return }
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
        catch let error {
            print("could write into txt \(error.localizedDescription)")
        }
    }

    // MARK: Timers

    func startTimer(){
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.setDatacount()
        }
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = NSCharacterSet(charactersIn: Constants.acceptableCharacters).inverted
        let filtered = string.components(separatedBy: cs).joined(separator: "")

        return (string == filtered)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    // MARK: Actions

    @objc func backAction(){
        if isGraphRunning {
            newWritePacket = false
            isStopPacket = true
            MBProgressHUD.showAdded(to: view, animated: true)
            setGraphRunning(false)

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
    @objc func activityDropdownAction(){
        activityDropdown.show()
    }

    @IBAction func writeGainAction(){

        guard writeGainSelected != nil else {
            presentAlert(message: Constants.missingGainMessage)
            return
        }
        newWritePacket = true
        isGainWritten = true

        let value1Int = UInt8(writeGainSelected, radix:16)
        let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))

        peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        if self.titleString == "DiscOpt"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainDiscOpt(Int32(value1Int!))
            writePacketGain = writeGainSelected
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "DigiOpt"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainDigiOpt(Int32(value1Int!))
            writePacketGain = writeGainSelected
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        else if self.titleString == "LND339"{
            let value1Int = UInt8(writeGainSelected, radix:16)
            let responseDict = Utils.sharedInst()?.sendWriteGainLND(Int32(value1Int!))
            writePacketGain = writeGainSelected
            peripheral.writeValue(responseDict!["Data"] as! Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
        }
        peripheral.setNotifyValue(true, for: char)

        presentAlert(message: Constants.gainWrittenMessage)

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

    @objc func txtButtonAction(_ sender: UIButton){

        if activityIndexString == nil{
            presentAlert(message: Constants.missingActivityMessage)
            return
        }

        if !isGraphRunning {
            return
        }
        if txtButton.tag == 0{

            setSaving(false)

        }else{

            if breedTextfield.text?.count == 0 {
                presentAlert(message: Constants.missingNameMessage)
            }
            else {
                setSaving(true)

                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
                let dateString = formatter.string(from: date)
                fileNameString = "\(breedTextfield.text ?? "")_\(locationTextfield.text ?? ""):\(dateString)-ECG.txt"
                fileNameString = fileNameString.replacingOccurrences(of: " ", with: "_")

                writePacket = "\(writePacket ?? "")\n" + "PS , Data , PS State , Gain , Activity\n"
                timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    self.lapTIme += 1
                    if self.lapTIme%5==0 && self.lapTIme != 0{
                        self.appendToSavedFile("\(self.lapTIme) minute(s)\n")
                    }
                }

                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

                    let fileURL = dir.appendingPathComponent(self.fileNameString)

                    do {

                        try self.writePacket.write(to: fileURL, atomically: false, encoding: .utf8)
                    }
                    catch {/* error handling here */}

                }

            }

        }

    }

    @objc func graphButtonAction(_ sender: UIButton){

        if graphButton.tag == 1{
            startDate = Date()
            setGraphRunning(true)
            startTimer()

            if let peripheral = singlton.shared.peripheral{
                if self.titleString == "DiscOpt"{
                    let writeData = Utils.sharedInst()?.startBioMetricGraphDiscOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if self.titleString == "DigiOpt"{
                    let writeData = Utils.sharedInst()?.startBioMetricGraphDigiOpt()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }else if self.titleString == "LND339"{
                    let writeData = Utils.sharedInst()?.startBioMetricGraphLND()
                    peripheral.writeValue(writeData!, for: char, type: CBCharacteristicWriteType.withResponse)
                }
            }

        }else{
            if timer != nil{
                timer.invalidate()
            }
            setGraphRunning(false)

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

    // MARK: CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("write success")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("vals")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let data = characteristic.value{

            if startDelay == nil && startDate != nil{
                startDelay = Date().timeIntervalSince(startDate)
            }

            print("resp: \(data.hexDescription)")
            let hexString = data.hexDescription.separate(every: 2, with: " ")
            let hexArray = hexString.components(separatedBy: " ")

            if hexArray.count == 13{

                let hexString = data.hexDescription.separate(every: 2, with: " ")
                let hexArray = hexString.components(separatedBy: " ")

                if hexArray[hexArray.count-3] == "01"{
                    writePacketGain = hexArray[hexArray.count-2]

                    print("read gain1 \(hexArray) packet \(data.hexDescription)" )
                    if let value = UInt8(hexArray[hexArray.count-2], radix: 16) {
                        print(value)
                        self.readGainLabel.text = "\(value)"
                    }
                }

                if writePacketGain != nil {
                    writePacket = writePacketGain + "0000"
                    writePacket = "\(writePacket ?? "" )\n"
                    newWritePacket = false
                }

            }
            else if hexArray.count == 7{

                DispatchQueue.main.async {
                    print("data hex stringY \(data.hexDescription)")
                    if data.hexDescription == "ab03a1b309a0" || data.hexDescription == "ab03a1b308a0" {
                        if hexArray[5] == "08" || hexArray[5] == "09"{
                            self.presentAlert(
                                message: Constants.sensorNotDetectedMessage,
                                actionTitle: Constants.okayTitle
                            ) { _ in
                                self.navigationController?.popViewController(animated: true)
                            }
                            return
                        }
                    }
                    if self.serviceType == "Gain"{
                        print("read gain \(hexArray) packet \(data.hexDescription)" )

                        if let value = UInt8(hexArray[hexArray.count-2], radix: 16) {
                            print(value)
                            self.readGainLabel.text = "\(value)"
                        }

                        if self.isFirst{
                            self.isFirst = false
                        }

                    }
                    else{
                        self.readCurrentLabel.text = hexArray[5]
                    }

                }

                if newWritePacket{

                    let hexString = data.hexDescription.separate(every: 2, with: " ")
                    let hexArray = hexString.components(separatedBy: " ")

                    if hexArray[hexArray.count-3] == "01"{
                        writePacketGain = hexArray[hexArray.count-2]

                        print("read gain1 \(hexArray) packet \(data.hexDescription)" )

                        if let value = UInt8(hexArray[hexArray.count-2], radix: 16) {
                            print(value)
                            self.readGainLabel.text = "\(value)"
                        }
                    }

                    if writePacketGain != nil{
                        writePacket = writePacketGain + "0000"
                        writePacket = "\(writePacket ?? "" )\n"
                        newWritePacket = false
                    }

                }
            }
            else if hexArray.count == 6{

                if data.hexDescription == "ab03a1b309a0" || data.hexDescription == "ab03a1b308a0" {
                    print("data hex stringx \(data.hexDescription)")
                    DispatchQueue.main.async {

                        if hexArray[4] == "08" || hexArray[4] == "09"{
                            self.presentAlert(
                                message: Constants.sensorNotDetectedMessage,
                                actionTitle: Constants.okayTitle
                            ) { _ in
                                self.navigationController?.popViewController(animated: true)
                            }
                            return
                        }
                    }
                }

                else if newWritePacket{

                    if !self.stopSaving{
                        if self.writePacketGain != nil {
                            appendToSavedFile("\(writePacketGain + "0000")\n")
                        }
                    }

                    newWritePacket = false
                }
                else if isStopPacket{
                    if timer != nil{
                        timer.invalidate()
                    }
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.navigationController?.popViewController(animated: true)
                }

                if isGainWritten{
                    isGainWritten = false
                    self.readGainAction()
                }

            }
            else if hexArray.count == 40{
                updateGraph(data)
            }

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
        for newChar in service.characteristics ?? [] {

            if newChar.properties.rawValue == CBCharacteristicProperties.notify.rawValue{
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

        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let foundServices = peripheral.services{
            for service in foundServices{
                if service.uuid == uartUUID{
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }

    }

    // MARK: Graph Data

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
            addValuesTograph(Int(decimalValue))

            if !self.stopSaving{

                let valueString = "\(currNo), \(decimalValue), \(isModified ? 1 : 0), \(readGainLabel.text ?? "-1"), \(activityIndexString ?? "")"

                print("value into txt \(valueString)")
                appendToSavedFile("\(valueString)\n")
            }

        }

    }

    func addValuesTograph(_ value:Int)   {

        if !isPlotting{ return }

        millisecondsGap +=  0.1
        self.vvaluesArray.add(value)
        secondsArray.add(millisecondsGap)

        if self.vvaluesArray.count>2560{
            self.vvaluesArray.removeObject(at: 0)
            self.secondsArray.removeObject(at: 0)
        }

    }

    @objc func setDatacount(){

        var values = [ChartDataEntry]()

        for i in 0..<vvaluesArray.count{

            let value = ChartDataEntry(x: secondsArray[i] as! Double, y: vvaluesArray[i] as! Double)
            values.append(value)

        }
        let set1 = LineChartDataSet(entries: values , label: "DataSet 1")
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

        let data = LineChartData(dataSet: set1)
        graphView.data = data

    }

}

//Milliseconds to date
extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}
