//
//  WebViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 10/1/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import JAMSVGImage

class LoginWebViewController: UIViewController {
  
  typealias LoginActionBlock = (LoginAction) -> ()
  
  enum LoadStatus {
    case initial, wait, refresh
  }
  
  enum LoginAction {
    // NOTE: failure happens when getting the secret key fails
    case cancel, success, failure
  }
  
  var initialUrl: URL
  var loginWebView: UIWebView?
  
  var load: LoadStatus = .initial
  var completeBlock: LoginActionBlock
  
  init(link: URL, completeBlock: @escaping LoginActionBlock) {
    initialUrl = link
    self.completeBlock = completeBlock
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup the webview
    let webView = UIWebView()
    webView.delegate = self
    webView.frame = view.bounds
    view.addSubview(webView)
    let req = NSMutableURLRequest(url: initialUrl)
    webView.loadRequest(req as URLRequest)
    self.loginWebView = webView
    
    navigationController?.setToolbarHidden(false, animated: true)
    
    // setup the toolbar items
    let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    spacer.width = 30
    let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancel))
    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
    
    toolbarItems = [flexSpace, closeButton]
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }
  
  
  @objc func cancel() {
    completeBlock(.cancel)
  }
  
  func getSecret(_ cookies: [String:String]) {
    
    MangaManager.sharedManager.getSecret(cookies) { [weak self](success) in
      
      guard let wself = self else { return }
      
      if success == true {
        wself.completeBlock(.success)
      } else {
        wself.completeBlock(.failure)
      }
      
    }
    
  }
  
  func closeWebView() {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }
  
  deinit {
    // webView?.removeObserver(self, forKeyPath: "estimatedProgress")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}



extension LoginWebViewController: UIWebViewDelegate {
  
  func webViewDidFinishLoad(_ webView: UIWebView) {
    if webView.request?.url?.absoluteString != "https://bato.to/forums/index.php?app=core&module=global&section=login" {
      // check of the cookies are present
      if let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "http://bato.to/")!) {
        let loginCookies = cookies.filter { ["member_id", "pass_hash"].contains($0.name) }
        if loginCookies.count == 2 {
          // we have found the proper cookies
          let values = cookies.reduce([String:String](), {
            var dict: [String:String] = $0
            dict[$1.name] = $1.value
            return dict
          })
          
          getSecret(values)
        }
      }
    }
  }
  
}
