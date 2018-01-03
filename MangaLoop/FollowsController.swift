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
import PKHUD

class FollowsController: UITableViewController, MangaPageList {
  
  var manga: [MangaPreviewItem]? {
    didSet {
      if let _ = manga {
        // the user is signed in add the sign out message
        searchController.searchBar.isUserInteractionEnabled = true
        searchController.searchBar.placeholder = "Search Follows"
        searchController.searchBar.showsBookmarkButton = false
        footerButton.isHidden = false
      } else {
        //manga is nil so the user is not signed in
        searchController.searchBar.isUserInteractionEnabled = false
        searchController.searchBar.placeholder = "Login to search follows"
        searchController.searchBar.showsBookmarkButton = false
        footerButton.isHidden = true
      }
    }
  }
  
  var page = 1
  var footerButton: UIButton!
  var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
  
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
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(signOutClick))//UIBarButtonItem(image: logoutImage, style: .Plain, target: self, action: #selector(signOutClick))
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = UIView()
    
    tableView.register(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
    tableView.register(ItemCell.self, forCellReuseIdentifier: ItemCell.defaultReusableId)
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
      footerButton.isHidden = true
      searchController.searchBar.isUserInteractionEnabled = false
      searchController.searchBar.placeholder = "Login to search follows"
      searchController.searchBar.showsBookmarkButton = false
      
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.navigationBar.isTranslucent = false
  }

  func refresh(_ object: AnyObject) {
    page = 1 // reset the page counter
    fetchFollows()
  }
  
  @objc func signOutClick() {
    
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
  
  func handleFollows( _ manga: [MangaPreviewItem]?) {
    
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
  
  func loginWithCookies(_ cookies: [String:String]) {
    
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
  
  func showLoginError(_ cookiesError: Bool) {
    // dismiss HUD if it is open
    PKHUD.sharedHUD.hide(animated: false, completion: nil)
    
    attemptingLogin = false
    
    var message = "" // the message for the alert controller
    
    if cookiesError {
      message = "Unfortunately this can occur ocasionally. Try logging in again but immediately close the view again, this should solve the login problem"
    } else {
      message = "Check your internet connection and try again"
    }
    
    let alert = UIAlertController(title: "Problem signing in", message: message, preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
    
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
    
  }
  
  
  //MARK: UITableView Datasource methods
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if searchController.isActive {
      return filteredManga?.count ?? 0
    } else {
      return manga?.count ?? 0
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    
    if searchController.isActive {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: MangaCell.defaultReusableId, for: indexPath) as! MangaCell
      let fm = filteredManga![indexPath.row]
      cell.configure(fm.toMangaItem())
      return cell
      
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.defaultReusableId, for: indexPath) as! ItemCell
    
    let m = manga![indexPath.row]
    cell.configure(m.title, subHeader: m.chapters!.first!.updateTime)
    cell.accessoryType = .none
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedManga = searchController.isActive ? filteredManga![indexPath.row].toMangaItem() : manga![indexPath.row]
    let detailsController = MangaDetailsController(manga: selectedManga)
    navigationController?.pushViewController(detailsController, animated: true)
  }
  
  
}

extension FollowsController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  
  
  //MARK DZNEmptyDataSet Datasource/Delegate methods
  func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
    
    if searchController.isActive {
      return nil
    }
    
    return NSAttributedString(string: "Login")
  }
  
  func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
    
    if searchController.isActive {
      return NSAttributedString(string: "Nothing to see here. Time to follow more manga")
    }
    
    return NSAttributedString(string: "Signing in will allow you to track follows and follow new manga and it will help make this app better because of Bato.to restrictions on guest users.")
  }
  
  func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
    //login
    
    let webController = LoginWebViewController(link: URL(string: "https://bato.to/forums/index.php?app=core&module=global&section=login")!, completeBlock: { [weak self] action in
      
      guard let wself = self else { return }
      wself.dismiss(animated: true, completion: nil)
      
      switch action {
      case .success:
        MangaManager.sharedManager.getFollowsList(wself.page, callback: wself.handleFollows)
        MangaManager.sharedManager.getAllFollowsIfNeeded(nil)
      case .failure:
        wself.showLoginError(false)
      case .cancel: break
      }
      
    })
    let navController = UINavigationController(rootViewController: webController)
    present(navController, animated: true, completion: nil)
    
  }
}

extension FollowsController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    filteredManga = FollowManga.searchFromText(searchController.searchBar.text!)
    tableView.reloadData()
  }
}

extension FollowsController: UISearchBarDelegate {
  func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
    signOutClick()
  }
}
