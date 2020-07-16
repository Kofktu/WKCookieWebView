import PackageDescription

let package = Package(
    name: "WKCookieWebView"
    platforms: [
        .macOS(.v10_10), .iOS(.v8), .tvOS(.v9), .watchOS(.v3)
    ],
    products: [
        .library(name: "WKCookieWebView", targets: ["WKCookieWebView"])
    ],
    targets: [
        .target(name: "WKCookieWebView", dependencies: [], path: "WKCookieWebView")
    ],
    swiftLanguageVersions: [.v5]
)
