//
//  TxtViewController.swift
//  Nordic
//
//  Created by Sai Dammu on 5/1/21.
//

import UIKit
import MessageUI
import MBProgressHUD

class TxtViewController: UIViewController,MFMailComposeViewControllerDelegate,UINavigationControllerDelegate {

    var txtFiles = [String]()
    var tableView : UITableView!
    var documentsUrl : URL!
    
    
    var sendButton : UIButton!
    var selectButton : UIButton!
    
    
    var isEdit = false
    var fileDataArray = Array<Data>() //[Data]()
    var fileNamesArray = Array<String>()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        self.title = "Text files"
        tableView = UITableView()
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = true
        self.view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Get the document directory url
        
        documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        txtFiles = filesSortedList(atPath: documentsUrl) ?? []
        tableView.reloadData()
        
        
        selectButton = UIButton(type: .custom)
        selectButton.setImage(UIImage(named: "menu"), for: .normal)
        selectButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        selectButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        let item2 = UIBarButtonItem(customView: selectButton)
        
        
        sendButton = UIButton(type: .custom)
        sendButton.setImage(UIImage(named: "mail"), for: .normal)
        sendButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        sendButton.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
        let item3 = UIBarButtonItem(customView: sendButton)
        self.navigationItem.setRightBarButtonItems([item2,item3], animated: true)
        sendButton.isHidden = true

/*
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            print(directoryContents)

           // print("txt urls:",txtFiles)
            tableView.reloadData()

        } catch {
            print(error)
        }
        */
       
         //   print("\(urls)")
       
        /*
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let directoryURL = URL(string: paths.path) else {return}
        do {
           let contents = try
           FileManager.default.contentsOfDirectory(at: directoryURL,
                  includingPropertiesForKeys:[.contentModificationDateKey],
                  options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
               .filter { $0.lastPathComponent.hasSuffix(".swift") }
               .sorted(by: {
                   let date0 = try $0.promisedItemResourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate!
                   let date1 = try $1.promisedItemResourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate!
                   return date0.compare(date1) == .orderedDescending
                })
          
            // Print results
            for item in contents {
                guard let t = try? item.promisedItemResourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate
                    else {return}
                print ("\(t)   \(item.lastPathComponent)")
            }
        } catch {
            print (error)
        }
 */
        
       // txtFiles = fetchFiles()
       
      //  print("urls \(urls)")
        
    }

    @objc func sendAction(_ sender:Any){
        
        if fileDataArray.count == 0 { return }
        
        let ac = UIAlertController(title: "Enter Email address", message: nil, preferredStyle: .alert)
       
        ac.addTextField { (textField : UITextField!) -> Void in
            textField.text = "ldtesting339@gmail.com"
        }
        
        let submitAction = UIAlertAction(title: "Send", style: .default) { [unowned ac] _ in
            let emailAddress = ac.textFields![0]
            // do something interesting with "answer" here
            if MFMailComposeViewController.canSendMail() {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                
               
                
                let mail = MFMailComposeViewController()
                mail.delegate = self
                mail.setToRecipients([emailAddress.text ?? ""])
                mail.setSubject("TXT Files")
                mail.setMessageBody("Attached are the Txt Files", isHTML: true)
                mail.mailComposeDelegate = self
        
                for i in 0..<self.fileDataArray.count{
                    mail.addAttachmentData(self.fileDataArray[i], mimeType: "text/txt", fileName: self.fileNamesArray[i])
                }
                self.present(mail, animated: true)
                
            }
            else {
                print("Email cannot be sent")
            }
        }
        
        ac.addAction(submitAction)
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(ac, animated: true)
        
    }
    
    @objc func buttonAction(_ sender:Any){
        isEdit = !isEdit
        
        sendButton.isHidden = isEdit ? false : true
        tableView.setEditing(isEdit, animated: true)
        
        if isEdit{
            selectButton.setImage(UIImage(named: "cancel"), for: .normal)
        }else{
            selectButton.setImage(UIImage(named: "menu"), for: .normal)
        }

      
    }
    
    
    func fetchFiles() -> [String]{
        
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options:.skipsHiddenFiles) {

            return urlArray.map { url in
                    (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }
                .sorted(by: { $0.1 > $1.1 }) // sort descending modification dates
                .map { $0.0 } // extract file names

        } else {
            return []
        }
        
        
    }
    func filesSortedList(atPath: URL) -> [String]? {

        var fileNames = [String]()
        let keys = [URLResourceKey.contentModificationDateKey]

        guard let fullPaths = try? FileManager.default.contentsOfDirectory(at: atPath, includingPropertiesForKeys:keys, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) else {
            return [""]
        }

        let orderedFullPaths = fullPaths.sorted(by: { (url1: URL, url2: URL) -> Bool in
            do {
                let values1 = try url1.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                let values2 = try url2.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])

                if let date1 = values1.creationDate, let date2 = values2.creationDate {
                    //if let date1 = values1.contentModificationDate, let date2 = values2.contentModificationDate {
                    return date1.compare(date2) == ComparisonResult.orderedDescending
                }
            } catch _{

            }
            return true
        })

        for fileName in orderedFullPaths {
            do {
                let values = try fileName.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                if let date = values.creationDate{
                    //let date : Date? = values.contentModificationDate
                    print(fileName.lastPathComponent, " ", date)
                    let theFileName = fileName.lastPathComponent
                    fileNames.append(theFileName)
                }
            }
            catch _{

            }
        }
        return fileNames
    }




}

extension TxtViewController : UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return txtFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
      
        let path = txtFiles[indexPath.row]
        let tempArray = path.components(separatedBy: "/")
        cell?.textLabel?.text = tempArray.last
        
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isEdit{
            self.updateFileData(indexPath.row)
        }else{
            
            let alert = UIAlertController(title: nil, message: "Choose any option", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            
            alert.addAction(UIAlertAction(title: "View", style: .default, handler: { _IOFBF in
                
                DispatchQueue.main.async {
                    let vc = WebViewController()
                    vc.fileUrlstring = self.documentsUrl.absoluteString + self.txtFiles[indexPath.row]
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
       
     }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEdit{
            self.updateFileData(indexPath.row)
        }
    }
    
    func updateFileData(_ index : Int){
        
        let path = self.txtFiles[index]
        let tempArray = path.components(separatedBy: "/")
        let fileName = tempArray.last
        
        let url = self.documentsUrl.absoluteString + self.txtFiles[index]
        if let fileUrl = URL(string: url){
            do {
                let fileData = try Data(contentsOf: fileUrl)
                
                if fileDataArray.contains(fileData){
                    
                    if let index = fileDataArray.firstIndex(of: fileData){
                        self.fileDataArray.remove(at: index)
                        self.fileNamesArray.remove(at: index)
                    }
                    
                }else{
                    fileDataArray.append(fileData)
                    fileNamesArray.append(fileName ?? "")
                }
                
            }catch {
                print("error")
            }
        }else {
            print("not valid url")
        }
        
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
        MBProgressHUD.hide(for: self.view, animated: true)
        sendButton.isHidden = true
        tableView.setEditing(false, animated: true)
        fileDataArray.removeAll()
        fileNamesArray.removeAll()
        isEdit = false
        
       
        selectButton.setImage(UIImage(named: "menu"), for: .normal)
    
        
    }
}
