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
        navigationItem.titleView = searchController.searchBar
        
        
        let logoutImage = UIImage(fromSVGNamed: Constants.Images.Logout, atSize: CGSize(width: 28, height: 28))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: logoutImage, style: .Plain, target: self, action: Selector("signOutClick"))
        
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
            
            searchController.searchBar.placeholder = "Search Follows"
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
        page++
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
        
        let alert = SCLAlertView()
        let username = alert.addTextField("Username")
        let password = alert.addTextField("Password")
        password.secureTextEntry = true
        
        
        alert.showCircularIcon = false
        alert.addButton("Login") { () -> Void in
            MangaManager.sharedManager.login(username.text ?? "", password: password.text ?? "", callback: { (success) -> Void in
                if success {
                    print("Login Success")
                    MangaManager.sharedManager.getFollowsList(self.page, callback: self.handleFollows)
                    MangaManager.sharedManager.getAllFollowsIfNeeded(nil)
                    
                }
            })
        }
        
        alert.showEdit("Login", subTitle: "Login using your bato.to info.")
        
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
