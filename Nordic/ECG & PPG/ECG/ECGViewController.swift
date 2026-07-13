//
//  ECGViewController.swift
//  HeartMath
//
//  Created by Sai Dammu on 11/1/21.
//

import UIKit
import DGCharts
import MBProgressHUD
import DropDown
import CoreBluetooth

final class ECGViewController: UIViewController, ScannerDelegate, ChartViewDelegate {

    private enum Constants {
        static let navigationTitle = "ECG & SCD"
        static let connectTitle = "Connect"
        static let disconnectTitle = "Disconnect"
        static let startTitle = "Start"
        static let stopTitle = "Stop"
        static let okTitle = "OK"
        static let missingGainMessage = "Gain is required"
        static let gainWrittenMessage = "Gain written"
        static let gainNotUpdatedMessage = "Gain not updated, please try again."
        static let invalidFileNameMessage = "Invalid file name"
        static let fallbackFileName = "ecg"
    }

    // MARK: Outlets

    @IBOutlet weak var ecgGraph: LineChartView!
    @IBOutlet weak var startStopButton : UIButton!
    @IBOutlet weak var startTxtButton : UIButton!
    @IBOutlet weak var fileNameTextfield : UITextField!
    @IBOutlet weak var firstPeriNameLabel : UILabel!
    @IBOutlet weak var secondPeriNameLabel : UILabel!

    // ECG gain controls
    @IBOutlet weak var writeGainTextfield : UITextField!
    @IBOutlet weak var readGainLabel : UILabel!

    // PPG gain controls
    @IBOutlet weak var writeGainTextfield1 : UITextField!
    @IBOutlet weak var readGainLabel1 : UILabel!

    // MARK: Dropdowns

    var gainDropdown = DropDown()
    var gainDropdown1 = DropDown()
    let hexGainArray = ["00","01","02","03","04","05","06","07","08","09","10","11","12"]
    var writeGainSelected : String!
    var writeGainSelected1 : String!

    // MARK: Bluetooth State

    var ecg = ECG()
    var ppgPeripheral : CBPeripheral!
    var ecgPeripheral : CBPeripheral!
    var actionType = ""

    // MARK: Graph / Saving State

    var ecgValuesArray = NSMutableArray()
    let ecgSecondsArray = NSMutableArray()
    var ecgFileNameString : String!
    var millisecondsGap = 0.1
    var timer : Timer!

    private let connectButton = CapsuleButton()

    // MARK: Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.navigationTitle
        self.view.backgroundColor = .white

        NotificationCenter.default.addObserver(self, selector: #selector(self.writtenGainPPG), name: NSNotification.Name(rawValue: "WrittenGainPPG"), object: nil)

        configureControlButtons()
        configureNavigationBar()
        configureDropdowns()
        configureChart()
        startTimer()
    }

    // MARK: Setup

    private func configureControlButtons() {
        styleActionButton(startStopButton, fillColor: DesignSystem.Palette.brand)
        styleActionButton(startTxtButton, fillColor: DesignSystem.Palette.document)
        startStopButton.tag = 0
        startTxtButton.tag = 0
        setControls(enabled: false)
    }

    private func styleActionButton(_ button: UIButton, fillColor: UIColor) {
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.backgroundColor = fillColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Typography.button
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func configureNavigationBar() {
        connectButton.tag = 1
        connectButton.setAppearance(
            title: Constants.connectTitle,
            fillColor: DesignSystem.Palette.brand,
            animated: false
        )
        connectButton.addTarget(self, action: #selector(self.scanAction), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: connectButton)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backAction))
    }

    private func configureDropdowns() {
        configureDropdown(
            dropdown: gainDropdown,
            textField: writeGainTextfield,
            action: #selector(writeGainDropDown)
        ) { [weak self] index in
            guard let self else { return }
            self.writeGainSelected = self.hexGainArray[index]
            self.writeGainTextfield.text = self.hexGainArray[index]
        }

        configureDropdown(
            dropdown: gainDropdown1,
            textField: writeGainTextfield1,
            action: #selector(writeGainDropDown1)
        ) { [weak self] index in
            guard let self else { return }
            self.writeGainSelected1 = self.hexGainArray[index]
            self.writeGainTextfield1.text = self.hexGainArray[index]
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

        dropdown.dataSource = hexGainArray
        dropdown.anchorView = textField
        dropdown.selectionAction = { [weak dropdown] index, item in
            print("Selected item: \(item) at index: \(index)")
            dropdown?.hide()
            selection(index)
        }
    }

    private func configureChart() {
        ecgGraph.delegate = self
        ecgGraph.chartDescription.enabled = false
        ecgGraph.dragEnabled = false
        ecgGraph.setScaleEnabled(true)
        ecgGraph.pinchZoomEnabled = false
        ecgGraph.drawGridBackgroundEnabled = false
        ecgGraph.highlightPerDragEnabled = true
        ecgGraph.backgroundColor = .clear
        ecgGraph.legend.enabled = false

        let legend = ecgGraph.legend
        legend.form = .line
        legend.font = UIFont.systemFont(ofSize: 0)
        legend.textColor = DesignSystem.Palette.secondaryText
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false

        let xAxis = ecgGraph.xAxis
        xAxis.labelFont = UIFont.systemFont(ofSize: 0)
        xAxis.labelTextColor = DesignSystem.Palette.secondaryText
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false

        configureAxis(ecgGraph.leftAxis)
        configureAxis(ecgGraph.rightAxis)
    }

    private func configureAxis(_ axis: YAxis) {
        axis.labelFont = UIFont.systemFont(ofSize: 10)
        axis.labelTextColor = DesignSystem.Palette.secondaryText
        axis.gridColor = DesignSystem.Palette.secondaryText.withAlphaComponent(0.18)
        axis.drawGridLinesEnabled = true
        axis.drawZeroLineEnabled = false
        axis.granularityEnabled = true
    }

    // MARK: UI State

    /// Start/save controls stay disabled until the ECG peripheral is ready.
    private func setControls(enabled: Bool) {
        startStopButton.isUserInteractionEnabled = enabled
        startStopButton.alpha = enabled ? 1.0 : 0.3
        startTxtButton.isUserInteractionEnabled = enabled
        startTxtButton.alpha = enabled ? 1.0 : 0.3
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

    /// Appends a line to the ECG capture file, if it exists.
    private func appendToSavedFile(_ string: String) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = dir.appendingPathComponent(ecgFileNameString ?? Constants.fallbackFileName)
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

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.setEcgDatacount()
        }
    }

    // MARK: ECG Gain Actions

    @IBAction func writeGainAction (_ sender:Any){
        actionType = "write"
        guard writeGainSelected != nil else {
            presentAlert(message: Constants.missingGainMessage)
            return
        }
        print("graph packet write")
        ecg.writeGain(writeGainSelected: writeGainSelected, channel: false)
    }

    @IBAction func readGainAction (_ sender:Any){
        actionType = "read"
        ecg.readGain(channel: false)
    }

    // MARK: PPG Gain Actions

    @IBAction func writeGainAction1(_ sender:Any){
        guard writeGainSelected1 != nil else {
            presentAlert(message: Constants.missingGainMessage)
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGwriteGain"), object: nil, userInfo: ["writeGain": writeGainSelected1!])
    }

    @IBAction func readGainAction1 (_ sender:Any){
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGReadGain"), object: nil, userInfo: nil)
    }

    @objc func writtenGainPPG(noti: Notification){
        if let readGain = noti.userInfo?["WrittenGainPPG"] as? String{
            readGainLabel1.text = readGain
        }
    }

    // MARK: Actions

    @IBAction func startStopAction(_ sender:Any){

        if startStopButton.tag == 0{

            startStopButton.tag = 1

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGStart"), object: nil, userInfo: nil)

            self.ecg.start()

            startStopButton.setTitle(Constants.stopTitle, for: .normal)
        }else{
            if (singlton.shared.saveEcgPpgText ?? false) == true{
                startTxt(UIButton())
            }
            startStopButton.tag = 0
            startStopButton.setTitle(Constants.startTitle, for: .normal)

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGStop"), object: nil, userInfo: nil)

            MBProgressHUD.showAdded(to: view, animated: true)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] timer in
                guard let self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)

                self.ecg.stop()
            }
        }

    }

    @IBAction func startTxt(_ sender:Any){

        guard let fileName = fileNameTextfield.text, fileName != "" else {
            presentAlert(message: Constants.invalidFileNameMessage)
            return
        }

        if startTxtButton.tag == 0{
            ecgFileNameString = fileName
            singlton.shared.ecgPPGfileName = fileName
            startTxtButton.tag = 1
            singlton.shared.saveEcgPpgText = true
            startTxtButton.setTitle(Constants.stopTitle, for: .normal)

            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MMM.yyyy-hh:mm:ss"
            let dateString = formatter.string(from: date)
            ecgFileNameString = "\(ecgFileNameString!)_\(ecgPeripheral.name!):\(dateString).txt"

            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

                let fileURL = dir.appendingPathComponent(self.ecgFileNameString)

                do {

                    try " ".write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {/* error handling here */}

            }

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PPGSave"), object: nil, userInfo: nil)

        }else{
            fileNameTextfield.text = ""
            startTxtButton.tag = 0
            singlton.shared.saveEcgPpgText = false
            startTxtButton.setTitle(Constants.startTitle, for: .normal)
        }

    }

    @objc func writeGainDropDown(){
        gainDropdown.show()
    }

    @objc func writeGainDropDown1(){
        gainDropdown1.show()
    }

    @objc func backAction(){
        timer.invalidate()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Timer"), object: nil, userInfo: nil)
        self.navigationController?.popViewController(animated: true)
        if ecgPeripheral != nil && ppgPeripheral != nil{
            singlton.shared.centralManager.cancelPeripheralConnection(ecgPeripheral)
            singlton.shared.centralManager.cancelPeripheralConnection(ppgPeripheral)
        }
    }

    @objc func scanAction(){

        if connectButton.tag == 1{

            let dvc = DevicesViewController()
            dvc.isEcgPPG = true
            dvc.delegate = self
            self.present(dvc, animated: true, completion: nil)

        }else{

            singlton.shared.centralManager.cancelPeripheralConnection(ecgPeripheral)
            singlton.shared.centralManager.cancelPeripheralConnection(ppgPeripheral)
            connectButton.tag = 1
            connectButton.setAppearance(
                title: Constants.connectTitle,
                fillColor: DesignSystem.Palette.brand,
                animated: true
            )
        }
    }

    // MARK: ScannerDelegate

    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, ecgPeripheral: CBPeripheral, ppgPeripheral: CBPeripheral) {

        firstPeriNameLabel.text = ecgPeripheral.name
        secondPeriNameLabel.text = ppgPeripheral.name
        self.ecgPeripheral = ecgPeripheral
        self.ppgPeripheral = ppgPeripheral

        connectButton.tag = 0

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] timer in
            self?.ecg.update = { data in

                self?.updateECGGraph(data)
            }

            self?.ecg.updateGain = {

            }

            self?.ecg.discvoer(ecgPeripheral: ecgPeripheral)
            self?.ecg.updateRead = { readString in

            }

            self?.ecg.ecgReady = { char in

                self?.connectButton.setAppearance(
                    title: Constants.disconnectTitle,
                    fillColor: DesignSystem.Palette.accent,
                    animated: true
                )
                self?.setControls(enabled: true)
            }

        }

    }

    // MARK: Graph Data

    func updateECGGraph(_ ppgData : Data){

        var valString = ppgData.map { String(format: "%02hhx", $0) }.joined()

        let hexString = ppgData.hexDescription.separate(every: 2, with: " ")
        let hexArray = hexString.components(separatedBy: " ")

        if actionType == "write"{
            if hexArray.count == 6{

                if hexArray[4] == "00"{
                    presentAlert(message: Constants.gainWrittenMessage)
                }else{
                    presentAlert(message: Constants.gainNotUpdatedMessage)
                }

            }
        }
        else if actionType == "read"{

            if hexArray.count == 6{

                if hexArray[4] == "00"{
                    print("Read gain success")
                }
            }

            if hexArray.count == 13{
                DispatchQueue.main.async {
                    self.readGainLabel.text = hexArray[11]
                }
            }

        }
        else if hexArray.count == 40{
            print("")
        }

        print("graph packet before :\(valString)")

        if valString.count == 86 || valString.count<34{
            return
        }

        //Validation for purina board
        if valString.count == 74 {
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
            }
        }

        addValuesToEcggraph(valuesArray)

    }

    func addValuesToEcggraph(_ valuesArray:[Int])  {

        for i in 0..<valuesArray.count{
            millisecondsGap +=  0.1

            self.ecgValuesArray.add(valuesArray[i])
            ecgSecondsArray.add(millisecondsGap)

            if self.ecgValuesArray.count>1280{
                self.ecgValuesArray.removeObject(at: 0)
                self.ecgSecondsArray.removeObject(at: 0)
            }

            if let saveEcg = singlton.shared.saveEcgPpgText {
                if saveEcg == true{
                    appendToSavedFile("\(valuesArray[i])\n")
                }
            }

        }

    }

    @objc func setEcgDatacount(){

        let values = NSMutableArray()

        for i in 0..<ecgValuesArray.count{

            let value = ChartDataEntry(x: ecgSecondsArray[i] as! Double, y: ecgValuesArray[i] as! Double)
            values.add(value)

        }

        if let minVal = (ecgValuesArray as! [Int]).min(),let maxVal = (ecgValuesArray as! [Int]).max(){

            ecgGraph.rightAxis.axisMinimum = Double(minVal-50)
            ecgGraph.leftAxis.axisMinimum = Double(minVal-50)
            ecgGraph.rightAxis.axisMaximum = Double(maxVal+50)
            ecgGraph.leftAxis.axisMaximum = Double(maxVal+50)

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

        ecgGraph.data = data

    }

}
