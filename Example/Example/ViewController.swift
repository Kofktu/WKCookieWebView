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
        webView.wkNavigationDelegate = self
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let urlString = "http://github.com"
        let isNeedPreloadForCookieSync = false
        
        if isNeedPreloadForCookieSync {
            // After running the app, before the first webview was loaded,
            // Cookies may not be set properly,
            // In that case, use the loader in advance to synchronize.
            // You can use the webview.
            WKCookieWebView.preloadWithDomainForCookieSync(urlString: urlString) { [weak self] in
                self?.setupWebView()
                self?.webView.load(URLRequest(url: URL(string: urlString)!))
            }
        } else {
            setupWebView()
            webView.load(URLRequest(url: URL(string: urlString)!))
        }
        
//        perform(#selector(printCookie), with: nil, afterDelay: 1.0)
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
        
        webView.onDecidePolicyForNavigationAction = { (webView, navigationAction, decisionHandler) in
            decisionHandler(.allow)
        }
        
        webView.onDecidePolicyForNavigationResponse = { (webView, navigationResponse, decisionHandler) in
            decisionHandler(.allow)
        }
        
        webView.onUpdateCookieStorage = { [weak self] (webView) in
            self?.printCookie()
        }
    }
    
    @objc private func printCookie() {
        print("=====================Cookies=====================")
        HTTPCookieStorage.shared.cookies?.forEach {
            print($0)
        }
        print("=================================================")
        
//        perform(#selector(printCookie), with: nil, afterDelay: 1.0)
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail.error : \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation.error : \(error)")
    }
    
}
