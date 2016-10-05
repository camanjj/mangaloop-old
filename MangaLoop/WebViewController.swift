//
//  WebViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 10/1/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import WebKit
import JAMSVGImage

class LoginWebViewController: UIViewController {
  
  
  enum LoadStatus {
    case Initial, Wait, Refresh
  }
  
  var initialUrl: NSURL
  var loginWebView: WKWebView?
  lazy var processPool = WKProcessPool()
  
  var load: LoadStatus = .Initial
  
  lazy var userContentController = WKUserContentController()
  
  lazy private var configuration: WKWebViewConfiguration = {
    let configuration = WKWebViewConfiguration()
    
    
    // enable javascript
    let preferences = WKPreferences()
    preferences.javaScriptEnabled = true
    
    configuration.userContentController = self.userContentController
    configuration.preferences = preferences
    configuration.processPool = self.processPool
    return configuration
  }()
  
  init(link: NSURL) {
    initialUrl = link
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let webView = setupWebView()
    view.addSubview(webView)
    let req = NSMutableURLRequest(URL: initialUrl)
    webView.loadRequest(req)
    
    self.loginWebView = webView
    
    navigationController?.setToolbarHidden(false, animated: true)
    
    // create label for the toolbar
    let label = UILabel()
    label.text = "close after login"
    label.sizeToFit()
    
    // setup the toolbar items
    let messageButton = UIBarButtonItem(customView: label)
    let canelItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(cancel))
    let spacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
    spacer.width = 30
    let closeButton = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(closeWebView))
    let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil);
    
    toolbarItems = [canelItem, flexSpace, messageButton, flexSpace, closeButton]
    
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
  }
  
  func setupWebView() -> WKWebView {
    let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
    webView.navigationDelegate = self
    webView.allowsBackForwardNavigationGestures = true
    webView.frame = view.bounds
    return webView;
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if (keyPath == "estimatedProgress") { // listen to changes and updated view
      
    }
  }
  
  func cancel() {
    
    if let tabController = presentingViewController as? UITabBarController,
      navController = tabController.selectedViewController as? UINavigationController,
      followsController = navController.topViewController as? FollowsController {
      // used to make sure the follows view does not attempt login after
      followsController.attemptingLogin = false
    }
    
    closeWebView()
  }
  
  func closeWebView() {
    resetProcessPool()
    loginWebView?.removeFromSuperview()
    loginWebView = nil;
    //completeCallback?()
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func check() {
    self.processPool = WKProcessPool()
    resetProcessPool()
    loginWebView?.removeFromSuperview()
    loginWebView = nil;
    
    let delay = 2 * Double(NSEC_PER_SEC)
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
    dispatch_after(time, dispatch_get_main_queue()) {
      // After 2 seconds this line will be executed
      self.loginWebView = self.setupWebView()
      self.view.addSubview(self.loginWebView!)
      let req = NSMutableURLRequest(URL: NSURL(string: "http://bato.to/")!)
      self.loginWebView!.loadRequest(req)
    }
    
  }
  
  deinit {
    // webView?.removeObserver(self, forKeyPath: "estimatedProgress")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func resetProcessPool() {
    assert(NSThread.isMainThread())
    configuration.processPool = WKProcessPool()
  }
  
  
  
}

extension LoginWebViewController: WKNavigationDelegate {
  
  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    
    
    if load == .Initial {
      load = .Refresh
    }
    
    
    /*if load == .Refresh {
      resetProcessPool()
      self.loginWebView?.removeFromSuperview()
      // self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
      self.loginWebView = setupWebView()
      let req = NSMutableURLRequest(URL: webView.URL!)
      self.loginWebView!.loadRequest(req)
      view.addSubview(self.loginWebView!)
      load = .Wait
    }*/
    
    if webView.URL?.absoluteString?.containsString("app=core&module=global&section=login") != true {
      // closeWebView()
    }
    
  }
  
  func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
    
    if let httpResponse = navigationResponse.response as? NSHTTPURLResponse {
      if let headers = httpResponse.allHeaderFields as? [String: String], url = httpResponse.URL {
        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headers, forURL: url)
        
//        for cookie in cookies {
//          print("found cookie " + cookie.name + " " + cookie.value)
//        }
      }
    }
    
    decisionHandler(.Allow)
  }
  
}

