# WKCookieWebView

- WKWebView with cookie sharing support

## Requirements
- iOS 8.0+
- XCode 9.0+
- Swift 5
- Swift 4 ([1.1.3](https://github.com/Kofktu/WKCookieWebView/tree/1.1.3))
- Swift 3 ([0.0.3](https://github.com/Kofktu/WKCookieWebView/tree/0.0.3))

## Installation

#### CocoaPods
WKCookieWebView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WKCookieWebView', '~> 2.0'
```

#### Carthage
For iOS 8+ projects with [Carthage](https://github.com/Carthage/Carthage)

```
github "Kofktu/WKCookieWebView"
```

## Usage

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
