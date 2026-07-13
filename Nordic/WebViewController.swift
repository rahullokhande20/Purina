//
//  WebViewController.swift
//  Purina
//
//  Created by Sai Dammu on 6/7/21.

import UIKit
import WebKit

class WebViewController: UIViewController {

    var fileUrlstring : String!
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        webView = WKWebView()
           // webView.navigationDelegate = self
            view = webView
        
        let url = URL(string: fileUrlstring)!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
