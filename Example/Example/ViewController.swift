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
        
        let cookie = HTTPCookie(properties: [
            .domain: "github.com",
            .path: "/",
            .name: "[Test] Cookie",
            .value: "value!!"])!
        
        HTTPCookieStorage.shared.setCookie(cookie)
        
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
        
        webView.onUpdateCookieStorage = { [weak self] (webView) in
            self?.printCookie()
        }
    }
    
    @objc private func printCookie() {
        guard let url = webView.url else {
            return
        }
        
        print("=====================Cookies=====================")
        HTTPCookieStorage.shared.cookies(for: url)?.forEach {
            print($0)
        }
        print("=================================================")
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("ViewController.decidePolicyFor.Action")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("ViewController.decidePolicyFor.Response")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail.error : \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation.error : \(error)")
    }
    
}
