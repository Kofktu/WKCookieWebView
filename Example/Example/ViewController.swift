//
//  ViewController.swift
//  Example
//
//  Created by kofktu on 2017. 6. 24..
//  Copyright © 2017년 Kofktu. All rights reserved.
//

import UIKit
import WebKit
import WKCookieWebView

class ViewController: UIViewController {

    lazy var webView: WKCookieWebView = {
        let webView: WKCookieWebView = WKCookieWebView(frame: self.view.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = false
//        webView.wkNavigationDelegate = self
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupWebView()
        webView.onDecidePolicyForNavigationAction = { (webView, navigationAction, decisionHandler) in
            decisionHandler(.allow)
        }
        
        webView.onDecidePolicyForNavigationResponse = { (webView, navigationResponse, decisionHandler) in
            decisionHandler(.allow)
        }
        
        webView.onUpdateCookieStorage = { [weak self] (webView) in
            self?.printCookie()
        }
        
        webView.load(URLRequest(url: URL(string: "http://github.com")!))
    }
    
    // MARK: - Private
    private func setupWebView() {
        view.addSubview(webView)
        
        let views: [String: Any] = ["webView": webView]
        
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[webView]-0-|",
            options: [],
            metrics: nil,
            views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-0-[webView]-0-|",
            options: [],
            metrics: nil,
            views: views))
    }
    
    private func printCookie() {
        print("=====================Cookies=====================")
        HTTPCookieStorage.shared.cookies?.forEach {
            print($0)
        }
        print("=================================================")
    }
}
