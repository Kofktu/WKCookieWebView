//
//  WKCookieWebView.swift
//  Example
//
//  Created by kofktu on 2017. 6. 24..
//  Copyright © 2017년 Kofktu. All rights reserved.
//

import UIKit
import Foundation
import WebKit

fileprivate final class WKCookieProcessPool: WKProcessPool {
    static let pool = WKCookieProcessPool()
}

open class WKCookieWebView: WKWebView {
    
    open override var navigationDelegate: WKNavigationDelegate? {
        didSet {
            guard navigationDelegate?.isEqual(self) == false else {
                return
            }
            
            wkNavigationDelegate = navigationDelegate
            navigationDelegate = self
        }
    }
    
    // Must use this instead of navigationDelegate
    @objc public weak var wkNavigationDelegate: WKNavigationDelegate?
    
    // The closure where cookie information is called at update time
    @objc public var onUpdateCookieStorage: ((WKCookieWebView) -> Void)?
    
    @objc
    public init(frame: CGRect, configurationBlock: ((WKWebViewConfiguration) -> Void)? = nil) {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKCookieProcessPool.pool
        configurationBlock?(configuration)
        super.init(frame: frame, configuration: configuration)
        navigationDelegate = self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, init(frame:configurationBlock:)")
    }
    
    @discardableResult
    open override func load(_ request: URLRequest) -> WKNavigation? {
        request.url.flatMap {
            configuration.userContentController = userContentWithCookies($0)
        }
        
        return super.load(request)
    }
    
    // MARK: - Private
    private func userContentWithCookies(_ url: URL) -> WKUserContentController {
        let userContentController = configuration.userContentController
        
        if let cookies = HTTPCookieStorage.shared.cookies(for: url), cookies.count > 0 {
            
            // https://stackoverflow.com/a/32845148
            var scripts: [String] = ["var cookieNames = document.cookie.split('; ').map(function(cookie) { return cookie.split('=')[0] } )"]
            let now = Date()

            for cookie in cookies {
                if let expiresDate = cookie.expiresDate, now.compare(expiresDate) == .orderedDescending {
                    // Expire
                    delete(cookie: cookie)
                    continue
                }
                
                scripts.append("if (cookieNames.indexOf('\(cookie.name)') == -1) { document.cookie='\(cookie.javaScriptString)'; }")
            }
            
            let mainScript = scripts.joined(separator: ";\n")
            userContentController.addUserScript(WKUserScript(source: mainScript,
                                                             injectionTime: .atDocumentStart,
                                                             forMainFrameOnly: false))
        }
        
        return userContentController
    }

    private func updateHigherOS11(webView: WKWebView) {
        // WKWebView -> HTTPCookieStorage
        guard #available(iOS 11.0, *) else {
            return
        }

        guard let url = url, let host = url.host else {
            return
        }

        let httpCookies = HTTPCookieStorage.shared.cookies(for: url)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else {return}
            self.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] (cookies) in
                let wkCookies = cookies.filter { host.range(of: $0.domain) != nil || $0.domain.range(of: host) != nil }
                for wkCookie in wkCookies {
                    httpCookies?
                        .filter { $0.name == wkCookie.name }
                        .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
                    
                    HTTPCookieStorage.shared.setCookie(wkCookie)
                }
                
                self.flatMap { $0.onUpdateCookieStorage?($0) }
            }
        }
    }
    
    private func update(cookies: [HTTPCookie]?) {
        guard let cookies = cookies, cookies.isEmpty == false else {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        cookies.forEach {
            dispatchGroup.enter()
            set(cookie: $0) {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                return
            }
            
            self.onUpdateCookieStorage?(self)
        }
    }
    
}

extension WKCookieWebView {
    
    typealias HTTPCookieHandler = ([HTTPCookie]?) -> Void
    
    func set(cookie: HTTPCookie, completion: (() -> Void)? = nil) {
        set(httpCookieStorage: cookie)
        
        if #available(iOS 11.0, *) {
            DispatchQueue.main.async { [weak self] in
                guard let self else {return}
                    self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: completion)
            }
        } else {
            completion?()
        }
    }
    
    func set(httpCookieStorage cookie: HTTPCookie) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
    
    func delete(cookie: HTTPCookie, completion: (() -> Void)? = nil) {
        HTTPCookieStorage.shared.deleteCookie(cookie)
        
        if #available(iOS 11.0, *) {
            DispatchQueue.main.async { [weak self] in
                guard let self else {return}
                self.configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: completion)
            }
        } else {
            completion?()
        }
    }
    
}


extension WKCookieWebView: WKNavigationDelegate {
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        guard (wkNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)) == nil else {
            return
        }
        
        decisionHandler(.allow)
    }
    
    @available(iOS 13.0, *)
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard (wkNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, preferences: preferences, decisionHandler: decisionHandler)) == nil else {
            return
        }
        
        self.webView(webView, decidePolicyFor: navigationAction) { (policy) in
            decisionHandler(policy, preferences)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) ->
        Swift.Void) {
        defer {
            if (wkNavigationDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)) != nil {
            } else {
                decisionHandler(.allow)
            }
        }
        
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let allHeaderFields = response.allHeaderFields as? [String: String],
            let url = response.url else {
                return
        }
        
        update(cookies: HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url))
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        wkNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateHigherOS11(webView: webView)
        wkNavigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didFinish: navigation)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        wkNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        guard (wkNavigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)) == nil else {
            return
        }
        
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        DispatchQueue.global(qos: .default).async { [weak webView] in
            guard webView != nil else {return}
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    credential = URLCredential(trust: serverTrust)
                    disposition = .useCredential
                }
            } else {
                disposition = .cancelAuthenticationChallenge
            }
            
            completionHandler(disposition, credential)
        }
    }
    
    @available(iOS 9.0, *)
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        wkNavigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }
    
}

// MARK: - HTTPCookie
extension HTTPCookie {
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HTTPCookie else {
            return false
        }
        
        return name == other.name &&
               value == other.value &&
               domain == other.domain &&
               path == other.path
    }
    
}

private extension HTTPCookie {
        
    var javaScriptString: String {
        if var properties = properties {
            properties.removeValue(forKey: .name)
            properties.removeValue(forKey: .value)
                
            return properties.reduce(into: ["\(name)=\(value)"]) { result, property in
                result.append("\(property.key.rawValue)=\(property.value)")
            }.joined(separator: "; ")
        }
        
        var script = [
            "\(name)=\(value)",
            "domain=\(domain)",
            "path=\(path)"
        ]
        
        if isSecure {
            script.append("secure=true")
        }
        
        if let expiresDate = expiresDate {
            script.append("expires=\(HTTPCookie.dateFormatter.string(from: expiresDate))")
        }
        
        return script.joined(separator: "; ")
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return dateFormatter
    }()
    
}
