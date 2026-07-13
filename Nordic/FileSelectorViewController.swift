
import UIKit

import NordicDFU

class FileSelectorViewController<T>: UIViewController, AlertPresenter, UITableViewDataSource, UITableViewDelegate {
    
    private let documentPicker: DocumentPicker<T>
    
    private var firmware: DFUFirmware!
    private var documentFileManager = DocumentFileManager()
    private (set) var dataSource = FSDataSource()
    var filterExtension: String? = nil  {
        didSet {
            dataSource.fileExtensionFilter = filterExtension
        }
    }
    
    @IBOutlet private var emptyView: UIView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var selectButton: NordicButton!
    @IBOutlet private var docImage: UIImageView!
    
    init(documentPicker: DocumentPicker<T>) {
        self.documentPicker = documentPicker
        super.init(nibName: "FileSelectorViewController", bundle: .main)
        navigationItem.title = "Select Package"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //    private lazy var firmwareInfoSection = DFUFirmwareSizeSection(firmware: firmware) { [unowned self] in
    //        self.documentPicker.openDocumentPicker(presentOn: self) { (result) in
    //            switch result {
    //            case .success(let firmware):
    //                self.firmware = firmware
    //                (self.sections[1] as? DFUFirmwareSizeSection)?.firmware = firmware
    //                self.tableView.reloadSections([1], with: .none)
    //            case .failure(let error): self.displayErrorAlert(error: error)
    //            }
    //        }
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterExtension = "zip"
        
        tableView.registerCellNib(cell: FileTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        selectButton.style = .mainAction
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadData))
        
        if #available(iOS 13, *) {
            UIImage(systemName: "doc").map { self.docImage.image = $0 }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    private func reloadItemList() {
        do {
            let directory = try documentFileManager.buildDocumentDir()
            dataSource.updateItems(directory)
        } catch let error {
            displayErrorAlert(error: error)
            return
        }
    }
    
    @objc
    func reloadData() {
        reloadItemList()
        
        if !dataSource.items.isEmpty {
            view = tableView
            tableView.reloadData()
            tableView.backgroundColor = .groupTableViewBackground
        } else {
            view = emptyView
        }
    }
    
    func documentWasOpened(document: DFUFirmware) {
        print("doc opened")
    }
    
    func fileWasSelected(file: File) {
        //        DFUFirmware
        //        let firmwareInfo = DFUFirmwareSizeSection(firmware: firmware) {
        //            self.firmware = firmware
        //        }
        
        //            let vc = DFUUpdateViewController()
        //            self.navigationController?.pushViewController(vc, animated: true)
        
        //        guard let firmware = DFUFirmware(urlToZipFile: file.url) else {
        //            displayErrorAlert(error: QuickError(message: "Can not create Firmware from selected file"))
        //            return
        //        }
        //
        //        documentWasOpened(document: firmware)
    }
    
    @IBAction private func openDocumentPicker() {
        print("doc opened 1")
        documentPicker.openDocumentPicker(presentOn: self) { [unowned self] (result) in
            switch result {
            case .success(let result):
                self.documentWasOpened(document: result as! DFUFirmware)
            case .failure(let error):
                self.displayErrorAlert(error: error)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? dataSource.items.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Import Another"
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: FileTableViewCell.self)
        let item = dataSource.items[indexPath.row]
        cell.update(item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0
            ? UIDevice.current.userInterfaceIdiom == .pad
            ? 80
            : 66
            : 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            openDocumentPicker()
        } else if let file = dataSource.items[indexPath.row].node as? File, dataSource.items[indexPath.row].valid {
            fileWasSelected(file: file)
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Documents Directory" : ""
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = self.dataSource.items[indexPath.row]
        
        let deleteItem: (FSNode) -> (Error?) = { [weak self] node in
            guard let `self` = self else { return QuickError(message: "Unknown Error") }
            
            do {
                try self.documentFileManager.deleteNode(node)
            } catch let error {
                return error
            }
            return nil
        }
        
        if let directory = item.node as? Directory {
            let alert = UIAlertController(title: "Remove Directory", message: "Do you want to delete entire directory with all nested items?", preferredStyle: .alert)
            let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.removeDirectory(directory, rootItem: item, deleteAction: deleteItem)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(delete)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            deleteFile(item.node, deleteAction: deleteItem)
        }
        
    }
    
    private func removeDirectory(_ dir: Directory, rootItem: FSNodeRepresentation, deleteAction: (FSNode) -> (Error?)) {
        let indexPaths = ([rootItem] + dataSource.items(dir))
            .compactMap { item in
                self.dataSource.items.firstIndex { item.node.url == $0.node.url }
            }
            .map { IndexPath(row: $0, section: 0)}
        if let error = deleteAction(rootItem.node) {
            displayErrorAlert(error: error)
            return
        }
        self.reloadItemList()
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }
    
    private func deleteFile(_ item: FSNode, deleteAction: (FSNode) -> (Error?)) {
        guard let ip = self.dataSource.items
                .firstIndex (where: { item.url == $0.node.url })
                .map ({ IndexPath(row: $0, section: 0) }) else {
            return
        }
        
        if let error = deleteAction(item) {
            displayErrorAlert(error: error)
            return
        }
        self.reloadItemList()
        tableView.deleteRows(at: [ip], with: .automatic)
    }
    
}

class DFUFileSelectorViewController: FileSelectorViewController<DFUFirmware> {
    
    
    override init(documentPicker: DocumentPicker<DFUFirmware>) {
        
        super.init(documentPicker: documentPicker)
        filterExtension = "zip"
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: DFUFirmware) {
        // router?.goToFirmwareInfo(firmware: document)
        print("doc opened")
        let peri = singlton.shared.peripheral
        let peripheral = Peripheral(peripheral: peri!, rssi: peri?.rssi ?? 0, name: peri?.name ?? "")
        let logger = DFULogObserver()
        let vc = DFUUpdateViewController(firmware: document, peripheral: peripheral, logger: logger)
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    override func fileWasSelected(file: File) {
        do {
            let firmware = try DFUFirmware(urlToZipFile: file.url)
            documentWasOpened(document: firmware)
        } catch {
          //  displayErrorAlert(error: QuickError(message: "Can not create Firmware from selected file"))
        }
    }
}


