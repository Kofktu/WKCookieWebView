//
//  CookieWebView.swift
//  WKCookieWebView
//
//  Created by Kofktu on 2020/09/13.
//  Copyright © 2020 Kofktu. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI
import Combine
import WebKit

@available(iOS 13.0.0, macOS 10.15, *)
open class CookieWebViewStore {
    
    public let webView: WKCookieWebView
    
    public weak var navigationDelegate: WKNavigationDelegate? {
        get { webView.navigationDelegate }
        set { webView.navigationDelegate = newValue }
    }
    
    public weak var uiDelegate: WKUIDelegate? {
        get { webView.uiDelegate }
        set { webView.uiDelegate = newValue }
    }
    
    public var title = PassthroughSubject<String?, Never>()
    public var url = PassthroughSubject<URL, Never>()
    public var isLoading = PassthroughSubject<Bool, Never>()
    public var estimatedProgress = PassthroughSubject<Double, Never>()
    public var canGoBack = PassthroughSubject<Bool, Never>()
    public var canGoForward = PassthroughSubject<Bool, Never>()
    
    private var observers: [NSKeyValueObservation] = []
    
    deinit {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }
    
    public init(_ configurationBlock: ((WKWebViewConfiguration) -> Void)? = nil) {
        webView = WKCookieWebView(frame: .zero, configurationBlock: configurationBlock)
        setupObservers()
    }
    
    open func load(url: URL) {
        load(request: URLRequest(url: url))
    }
    
    open func load(request: URLRequest) {
        webView.load(request)
    }
    
    open func loadHTMLString(_ string: String, baseURL: URL?) {
        webView.loadHTMLString(string, baseURL: baseURL)
    }
    
    // MARK: - Private
    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKCookieWebView, Value>,
                               onChanged: @escaping (Value) -> Void) -> NSKeyValueObservation {
          webView.observe(keyPath, options: [.prior]) { _, change in
            if let newValue = change.newValue, change.isPrior {
                onChanged(newValue)
            }
          }
        }
        
        observers = [
            subscriber(for: \.title,
                       onChanged: { [weak self] in self?.title.send($0) }),
            subscriber(for: \.url,
                       onChanged: { [weak self] in $0.flatMap { self?.url.send($0) }}),
            subscriber(for: \.isLoading,
                       onChanged: { [weak self] in self?.isLoading.send($0) }),
            subscriber(for: \.estimatedProgress,
                       onChanged: { [weak self] in self?.estimatedProgress.send($0) }),
            subscriber(for: \.canGoBack,
                       onChanged: { [weak self] in self?.canGoBack.send($0) }),
            subscriber(for: \.canGoForward,
                       onChanged: { [weak self] in self?.canGoForward.send($0) }),
        ]
    }
    
}

@available(iOS 13.0.0, macOS 10.15, *)
public struct CookieWebView: View, UIViewRepresentable {
    
    public typealias UIViewType = UIViewWrapper<WKCookieWebView>
    
    public let store: CookieWebViewStore
    
    public init(store: CookieWebViewStore) {
        self.store = store
    }

    public func makeUIView(context: Context) -> CookieWebView.UIViewType {
        UIViewWrapper()
    }
    
    public func updateUIView(_ uiView: CookieWebView.UIViewType, context: Context) {
        guard uiView.contentView !== store.webView else {
            return
        }
        
        uiView.contentView = store.webView
    }
    
}

@available(iOS 13.0.0, macOS 10.15, *)
public class UIViewWrapper<ContentView: UIView>: UIView {
    
    var contentView: ContentView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        
        didSet {
            guard let contentView = contentView else {
                return
            }
            
            addSubview(contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
              contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
              contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
              contentView.topAnchor.constraint(equalTo: topAnchor),
              contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
}

@available(iOS 13.0.0, *)
struct CookieWebView_Previews: PreviewProvider {
    static var store: CookieWebViewStore {
        let store = CookieWebViewStore()
        store.load(url: URL(string: "http://github.com")!)
        return store
    }
    
    static var previews: some View {
        CookieWebView(store: store)
    }
}

#endif
