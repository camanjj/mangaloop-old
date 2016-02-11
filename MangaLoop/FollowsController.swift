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

class FollowsController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    var manga: [MangaPreviewItem]?
    
    var page = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Follows"
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
        
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = UIView()
        
        tableView.registerClass(ItemCell.self, forCellReuseIdentifier: ItemCell.defaultReusableId)
//        tableView.registerCellClass(MangaCell)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        
        // add pull to refresh control
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        
        if MangaManager.isSignedIn() {
            
            // attempt to load from Pantry
            if let manga: [MangaPreviewItem] = Pantry.unpack(Constants.Pantry.Follows) {
                
                self.manga = manga
                tableView.reloadData()
                
            } else {
                fetchFollows()
            }
            
        }
        
    }
    
    func refresh(object: AnyObject) {
        page = 1 // reset the page counter
        fetchFollows()
    }
    
    func fetchFollows() {
        
        
        MangaManager.sharedManager.getFollowsList(page, callback: handleFollows)
        
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
            
//            if self.tableView.tableFooterView == self.activityIndicator {
//                self.activityIndicator.stopAnimating()
//                self.tableView.tableFooterView = self.footerButton
//            }
            
            self.tableView.reloadData()
            
        }
        
        
    }

    
    //MARK DZNEmptyDataSet Datasource/Delegate methods
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "Login")
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
    
    
    //MARK: UITableView Datasource methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manga?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ItemCell.defaultReusableId, forIndexPath: indexPath) as! ItemCell
        
//        cell.configure(manga![indexPath.row])
        let m = manga![indexPath.row]
        cell.configure(m.title, subHeader: m.chapters!.first!.updateTime)
        cell.accessoryType = .None
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedManga = manga![indexPath.row]
        let detailsController = MangaDetailsController(manga: selectedManga)
        navigationController?.pushViewController(detailsController, animated: true)
    }

    
}
