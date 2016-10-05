//
//  FollowsController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/4/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import SCLAlertView
import Pantry
import RealmSwift
import WebKit
import PKHUD

class FollowsController: UITableViewController, MangaPageList {
  
  var manga: [MangaPreviewItem]? {
    didSet {
      if let _ = manga {
        // the user is signed in add the sign out message
        searchController.searchBar.userInteractionEnabled = true
        searchController.searchBar.placeholder = "Search Follows"
        searchController.searchBar.showsBookmarkButton = false
        footerButton.hidden = false
      } else {
        //manga is nil so the user is not signed in
        searchController.searchBar.userInteractionEnabled = false
        searchController.searchBar.placeholder = "Login to search follows"
        searchController.searchBar.showsBookmarkButton = false
        footerButton.hidden = true
      }
    }
  }
  
  var page = 1
  var footerButton: UIButton!
  var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
  
  var searchController = UISearchController(searchResultsController: nil)
  var filteredManga: Results<FollowManga>?
  
  var attemptingLogin = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Follows"
    automaticallyAdjustsScrollViewInsets = false
    extendedLayoutIncludesOpaqueBars = false
    
    // setup for searching
    searchController.searchResultsUpdater = self
    searchController.dimsBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    definesPresentationContext = true
    searchController.searchBar.delegate = self
    tableView.tableHeaderView = searchController.searchBar
    
    
//    let logoutImage = UIImage(fromSVGNamed: Constants.Images.Logout, atSize: CGSize(width: 28, height: 28))
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "logout", style: .Plain, target: self, action: #selector(signOutClick))//UIBarButtonItem(image: logoutImage, style: .Plain, target: self, action: #selector(signOutClick))
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = UIView()
    
    tableView.registerClass(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
    tableView.registerClass(ItemCell.self, forCellReuseIdentifier: ItemCell.defaultReusableId)
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 44
    
    
    // add pull to refresh control
    setupRefreshControl()
    
    // add the footer button
    self.footerButton = addFooterButton()
    
    
    if MangaManager.isSignedIn() {
      
      searchController.searchBar.placeholder = "Search All Follows"
      searchController.searchBar.showsBookmarkButton = true
      
      
      // attempt to load from Pantry
      if let manga: [MangaPreviewItem] = Pantry.unpack(Constants.Pantry.Follows) {
        
        self.manga = manga
        tableView.reloadData()
        
      } else {
        fetchFollows()
      }
      
    } else {
      footerButton.hidden = true
      searchController.searchBar.userInteractionEnabled = false
      searchController.searchBar.placeholder = "Login to search follows"
      searchController.searchBar.showsBookmarkButton = false
      
    }
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.navigationBar.translucent = false
  }
  
  lazy private var configuration: WKWebViewConfiguration = {
    let configuration = WKWebViewConfiguration()
    
    
    // enable javascript
    let preferences = WKPreferences()
    preferences.javaScriptEnabled = true
    
    configuration.preferences = preferences
    configuration.processPool = WKProcessPool()
    return configuration
  }()
  
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // HACK used to get the cookies from the WKWebView for bato.to
    // webview has some weird behvior when showing the cookies after login
    if MangaManager.isSignedIn() == false && attemptingLogin == true {
    
      // show HUD
      PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = false
      PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Signing in...")
      PKHUD.sharedHUD.show()
      
      
      // create a webview to fetch the cookies from bato.to
      let webView = WKWebView(frame: CGRectZero, configuration: configuration)
      webView.navigationDelegate = self
      
      // going to be removed later after getting the cookies
      view.addSubview(webView)
      
      let url = NSURL(string: "https://bato.to/")!
      let request = NSURLRequest(URL: url)
      webView.loadRequest(request)
    

    }
    
  }
  
  func refresh(object: AnyObject) {
    page = 1 // reset the page counter
    fetchFollows()
  }
  
  func signOutClick() {
    
    let alert = SCLAlertView()
    
    alert.addButton("Sign Out") { () -> Void in
      MangaManager.sharedManager.logout()
      Pantry.expire(Constants.Pantry.Follows) // remove the cached follows
      Pantry.expire(Constants.Pantry.FetchFollows)
      self.manga = nil // reset the list
      self.tableView.reloadData()
      self.tableView.reloadEmptyDataSet() // show the empty data view
    }
    
    alert.showWarning("Sign out", subTitle: "", closeButtonTitle: "Cancel")
    
  }
  
  
  func fetchFollows() {
    MangaManager.sharedManager.getFollowsList(page, callback: handleFollows)
  }
  
  func moreClick() {
    page += 1
    activityIndicator.startAnimating()
    tableView.tableFooterView = activityIndicator
    fetchFollows()
  }
  
  func handleFollows( manga: [MangaPreviewItem]?) {
    
    if let refreshControl = self.refreshControl {
      refreshControl.endRefreshing()
    }
    
    if let manga = manga {
      
      if self.page == 1 {
        //remove all mangas
        self.manga = manga
        
        Pantry.pack(manga, key: Constants.Pantry.Follows)
        
      } else {
        self.manga! += manga
      }
      
      if self.tableView.tableFooterView == self.activityIndicator {
        self.activityIndicator.stopAnimating()
        self.tableView.tableFooterView = self.footerButton
      }
      
      self.tableView.reloadData()
      
    }
    
    
  }
  
  func loginWithCookies(cookies: [String:String]) {
    
    attemptingLogin = false
    print("Attempting secret...")
    MangaManager.sharedManager.getSecret(cookies, callback: { [weak self] (success) in
      
      guard let wself = self else  { return }
      
      print("Secret callback")
      
      if success == true {
        PKHUD.sharedHUD.hide(animated: true, completion: nil)
        MangaManager.sharedManager.getFollowsList(wself.page, callback: wself.handleFollows)
        MangaManager.sharedManager.getAllFollowsIfNeeded(nil)
        
      } else {
        // Error during login, dismiss the HUD w/o animation and show alert
        wself.showLoginError(false)
        
      }
      
      
    })
    
  }
  
  func showLoginError(cookiesError: Bool) {
    // dismiss HUD if it is open
    PKHUD.sharedHUD.hide(animated: false, completion: nil)
    
    attemptingLogin = false
    
    var message = "" // the message for the alert controller
    
    if cookiesError {
      message = "Unfortunately this can occur ocasionally. Try logging in again but immediately close the view again, this should solve the login problem"
    } else {
      message = "Check your internet connection and try again"
    }
    
    let alert = UIAlertController(title: "Problem signing in", message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
    
    alert.addAction(okAction)
    presentViewController(alert, animated: true, completion: nil)
    
  }
  
  
  //MARK: UITableView Datasource methods
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if searchController.active {
      return filteredManga?.count ?? 0
    } else {
      return manga?.count ?? 0
    }
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    
    if searchController.active {
      
      let cell = tableView.dequeueReusableCellWithIdentifier(MangaCell.defaultReusableId, forIndexPath: indexPath) as! MangaCell
      let fm = filteredManga![indexPath.row]
      cell.configure(fm.toMangaItem())
      return cell
      
    }
    
    let cell = tableView.dequeueReusableCellWithIdentifier(ItemCell.defaultReusableId, forIndexPath: indexPath) as! ItemCell
    
    let m = manga![indexPath.row]
    cell.configure(m.title, subHeader: m.chapters!.first!.updateTime)
    cell.accessoryType = .None
    
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selectedManga = searchController.active ? filteredManga![indexPath.row].toMangaItem() : manga![indexPath.row]
    let detailsController = MangaDetailsController(manga: selectedManga)
    navigationController?.pushViewController(detailsController, animated: true)
  }
  
  
}

extension FollowsController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  
  
  //MARK DZNEmptyDataSet Datasource/Delegate methods
  func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
    
    if searchController.active {
      return nil
    }
    
    return NSAttributedString(string: "Login")
  }
  
  func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
    
    if searchController.active {
      return NSAttributedString(string: "Nothing to see here. Time to follow more manga")
    }
    
    return NSAttributedString(string: "Signing in will allow you to track follows and follow new manga and it will help make this app better because of Bato.to restrictions on guest users.")
  }
  
  func emptyDataSet(scrollView: UIScrollView!, didTapButton button: UIButton!) {
    //login
    
    attemptingLogin = true
    let webController = LoginWebViewController(link: NSURL(string: "https://bato.to/forums/index.php?app=core&module=global&section=login")!)
    let navController = UINavigationController(rootViewController: webController)
    presentViewController(navController, animated: true, completion: nil)
    
  }
}

extension FollowsController: UISearchResultsUpdating {
  
  func updateSearchResultsForSearchController(searchController: UISearchController) {
    filteredManga = FollowManga.searchFromText(searchController.searchBar.text!)
    tableView.reloadData()
  }
}

extension FollowsController: UISearchBarDelegate {
  func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
    signOutClick()
  }
}

extension FollowsController: WKNavigationDelegate {
  
  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    
    // remove the webview fromt the view after one request
    if webView.superview != nil {
      webView.stopLoading()
      webView.removeFromSuperview()
    }
    
  }
  
  func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
    
    
    if let httpResponse = navigationResponse.response as? NSHTTPURLResponse {
      if let headers = httpResponse.allHeaderFields as? [String: String], url = httpResponse.URL {
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headers, forURL: url)
        
        let loginCookies = cookies.filter { ["member_id", "pass_hash"].contains($0.name) }
        print("Checking cookies")
        
        
        if loginCookies.count == 2 {
          
          // we got the cookies
          let values = cookies.reduce([String:String](), combine: {
            var dict: [String:String] = $0
            dict[$1.name] = $1.value
            return dict
          })
          
          NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: httpResponse.URL, mainDocumentURL: nil)
          
         loginWithCookies(values)
          
        } else {
          // we don't have the cookies needed
          showLoginError(true)
        }
      }
    }
    
    decisionHandler(.Allow)
  }
  
  func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
    
    // only allow request for bato.to
    if navigationAction.request.URL?.absoluteString == "https://bato.to/" {
      decisionHandler(.Allow)
    } else {
      decisionHandler(.Cancel)
    }
    
    
    
  }
}
