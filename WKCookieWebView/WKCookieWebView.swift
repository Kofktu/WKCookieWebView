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

fileprivate class WKCookieProcessPool: WKProcessPool {
    static let pool = WKCookieProcessPool()
}

open class WKCookieWebView: WKWebView {
    
    // Must use this instead of navigationDelegate
    @objc public weak var wkNavigationDelegate: WKNavigationDelegate?
    
    // If necessary, use clousre instead of delegate
    @objc public var onDecidePolicyForNavigationAction: ((WKWebView, WKNavigationAction, @escaping (WKNavigationActionPolicy) -> Swift.Void) -> Void)?
    @objc public var onDecidePolicyForNavigationResponse: ((WKWebView, WKNavigationResponse, @escaping (WKNavigationResponsePolicy) -> Swift.Void) -> Void)?
    @objc public var onDidReceiveChallenge: ((WKWebView, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) -> Void)?
    
    // The closure where cookie information is called at update time
    @objc public var onUpdateCookieStorage: ((WKCookieWebView) -> Void)?
    
    private var updatedCookies = [String]()
    
    @objc
    public init(frame: CGRect, configurationBlock: ((WKWebViewConfiguration) -> Void)? = nil) {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKCookieProcessPool.pool
        configurationBlock?(configuration)
        super.init(frame: frame, configuration: configuration)
        configuration.userContentController = userContentWithCookies()
        navigationDelegate = self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, init(frame:configurationBlock:)")
    }
    
    // MARK: - Private
    private func userContentWithCookies() -> WKUserContentController {
        let userContentController = configuration.userContentController
        
        if let cookies = HTTPCookieStorage.shared.cookies, cookies.count > 0 {
            
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

    private func update(webView: WKWebView) {
        // WKWebView -> HTTPCookieStorage
        webView.evaluateJavaScript("document.cookie;") { [weak self] (result, error) in
            guard let host = self?.url?.host,
                let documentCookie = result as? String else {
                    return
            }
            
            self?.fetchCookies(fileter: host, completion: { [weak self] (cookies) in
                self?.update(with: cookies, documentCookie: documentCookie, host: host)
            })
        }
    }
    
    private func update(with cachedCookies: [HTTPCookie]?, documentCookie: String, host: String) {
        let cookieValues = documentCookie.components(separatedBy: "; ")
        
        guard cookieValues.isEmpty == false else {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        for value in cookieValues {
            var comps = value.components(separatedBy: "=")
            if comps.count < 2 { continue }
            
            let cookieName = comps.removeFirst()
            let cookieValue = comps.joined(separator: "=")
            let localCookie = cachedCookies?.filter { $0.name == cookieName }.first
            
            if let localCookie = localCookie {
                if !cookieValue.isEmpty && localCookie.value != cookieValue {
                    // set/update cookie
                    var properties: [HTTPCookiePropertyKey: Any] = localCookie.properties ?? [
                        .name: localCookie.name,
                        .domain: localCookie.domain,
                        .path: localCookie.path
                    ]
                    
                    properties[.value] = cookieValue
                    
                    self.delete(cookie: localCookie)
                    
                    if let cookie = HTTPCookie(properties: properties) {
                        // set cookie
                        dispatchGroup.enter()
                        self.set(cookie: cookie) {
                            dispatchGroup.leave()
                        }
                    }
                }
            } else {
                if !cookieName.isEmpty && !cookieValue.isEmpty {
                    let properties: [HTTPCookiePropertyKey: Any] = [
                        .name: cookieName,
                        .value: cookieValue,
                        .domain: host,
                        .path: "/"
                    ]
                    
                    if let cookie = HTTPCookie(properties: properties) {
                        // set cookie
                        dispatchGroup.enter()
                        self.set(cookie: cookie) {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.updateWKCookieToHTTPCookieStorage(cachedCookies)
            
            guard let self = self else {
                return
            }
            
            self.onUpdateCookieStorage?(self)
        }
    }
    
    private func update(cookies: [HTTPCookie]?) {
        guard let cookies = cookies, cookies.isEmpty == false else {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        cookies.forEach {
            if !updatedCookies.contains($0.name) {
                updatedCookies.append($0.name)
            }
            
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
    
    private func updateWKCookieToHTTPCookieStorage(_ wkCookies: [HTTPCookie]?) {
        guard let cookies = HTTPCookieStorage.shared.cookies, #available(iOS 11.0, *) else {
            return
        }
        
        wkCookies?
            .filter { cookies.contains($0) == false }
            .forEach {
                HTTPCookieStorage.shared.setCookie($0)
        }
    }
    
}

extension WKCookieWebView {
    
    typealias HTTPCookieHandler = ([HTTPCookie]?) -> Void
    
    func fetchCookies(completion: @escaping HTTPCookieHandler) {
        if #available(iOS 11.0, *) {
            configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
                completion(cookies)
            }
        } else {
            completion(HTTPCookieStorage.shared.cookies)
        }
    }
    
    func fetchCookies(fileter host: String, completion: @escaping HTTPCookieHandler) {
        fetchCookies { (cookies) in
            completion(cookies?.filter { host.range(of: $0.domain) != nil || $0.domain.range(of: host) != nil })
        }
    }
    
    func set(cookie: HTTPCookie, completion: (() -> Void)? = nil) {
        HTTPCookieStorage.shared.setCookie(cookie)
        
        if #available(iOS 11.0, *) {
            configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: completion)
        } else {
            completion?()
        }
    }
    
    func delete(cookie: HTTPCookie, completion: (() -> Void)? = nil) {
        HTTPCookieStorage.shared.deleteCookie(cookie)
        
        if #available(iOS 11.0, *) {
            configuration.websiteDataStore.httpCookieStore.delete(cookie, completionHandler: completion)
        } else {
            completion?()
        }
    }
    
}


extension WKCookieWebView: WKNavigationDelegate {
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let handler = onDecidePolicyForNavigationAction {
            handler(webView, navigationAction, decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        defer {
            if let handler = onDecidePolicyForNavigationResponse {
                handler(webView, navigationResponse, decisionHandler)
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
        update(webView: webView)
        wkNavigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        wkNavigationDelegate?.webView?(webView, didFinish: navigation)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        wkNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if let handler = onDidReceiveChallenge {
            handler(webView, challenge, completionHandler)
        } else {
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            
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
        var properties = [
            "\(name)=\(value)",
            "domain=\(domain)",
            "path=\(path)"
        ]
        
        if isSecure {
            properties.append("secure=true")
        }
        
        if let expiresDate = expiresDate {
            properties.append("expires=\(HTTPCookie.dateFormatter.string(from: expiresDate))")
        }
        
        return properties.joined(separator: "; ")
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return dateFormatter
    }()
    
}
