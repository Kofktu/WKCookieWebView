//
//  ObjCWebViewController.m
//  Example
//
//  Created by Taeun Kim on 07/02/2019.
//  Copyright © 2019 Kofktu. All rights reserved.
//

#import "ObjCWebViewController.h"

@import WebKit;
@import WKCookieWebView;

@interface ObjCWebViewController ()

@property (nonatomic, strong) WKCookieWebView *webView;

@end

@implementation ObjCWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupWebView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://github.com"]]];
}

// MARK: - Private
- (void)setupWebView {
    self.webView = [[WKCookieWebView alloc] initWithFrame:CGRectZero configurationBlock:^(WKWebViewConfiguration * _Nonnull configuration) {
        
    }];
    [self.webView setOnDecidePolicyForNavigationAction:^(WKWebView * _Nonnull webView,
                                                         WKNavigationAction * _Nonnull navigationAction,
                                                         void (^ _Nonnull decisionHandler)(WKNavigationActionPolicy)) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }];
    [self.webView setOnUpdateCookieStorage:^(WKCookieWebView * _Nonnull webView) {
    }];
    
    NSDictionary<NSString *, id> *views = @{@"webView": self.webView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
}

@end
