# WKCookieWebView

- WKWebView with cookie sharing support

## Requirements
- iOS 8.0+
- XCode 9.0+
- Swift 4
- Swift 3 ([0.0.3](https://github.com/Kofktu/WKCookieWebView/tree/0.0.3))

## Installation

#### CocoaPods
WKCookieWebView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WKCookieWebView'
```

#### Carthage
For iOS 8+ projects with [Carthage](https://github.com/Carthage/Carthage)

```
github "Kofktu/WKCookieWebView"
```

## Usage

#### navigationDelegate -> wkNavigationDelegate

- You should use ```wkNavigationDelegate``` instead of ```navigationDelegate```.
- However, the three methods of WKNavigationDelegate must use closure instead of delegate.



```swift
// @available(iOS 8.0, *)
// optional public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
public var onDecidePolicyForNavigationAction: ((WKWebView, WKNavigationAction, @escaping (WKNavigationActionPolicy) -> Swift.Void) -> Void)?

// @available(iOS 8.0, *)
// optional public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void)
public var onDecidePolicyForNavigationResponse: ((WKWebView, WKNavigationResponse, @escaping (WKNavigationResponsePolicy) -> Swift.Void) -> Void)?

// @available(iOS 8.0, *)
// optional public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void)
public var onDidReceiveChallenge: ((WKWebView, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) -> Void)?
```



#### When HTTPCookieStorage is updated

```swift
public var onUpdateCookieStorage: ((WKCookieWebView) -> Void)?
```

#### If you need to set WKWebViewConfiguration

```swift
let webView = WKCookieWebView(frame: frame, configurationBlock: { (configuration) in
    // customize configuration
})
```

#### Preloader
After running the app, before the first webview was loaded,  
Cookies may not be set properly,  
In that case, use the loader in advance to synchronize.

```swift
WKCookieWebView.preloadWithDomainForCookieSync(urlString: String, completion: (() -> Void)?)
```

## Authors

Taeun Kim (kofktu), <kofktu@gmail.com>

## License

WKCookieWebView is available under the ```MIT``` license. See the ```LICENSE``` file for more info.
