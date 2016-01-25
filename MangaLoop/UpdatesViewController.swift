//
//  UpdatesViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit

class UpdatesViewController: UITableViewController {
    
    var page = 1
    var manga: [MangaPreviewItem] = []
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var footerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        // add pull to refresh control
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        
        fetchUpdates()
        
        let footerButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 45))
        footerButton.setTitle("More", forState: .Normal)
        footerButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        footerButton.backgroundColor = UIColor.redColor()
        footerButton.addTarget(self, action: Selector("moreClick"), forControlEvents: .TouchUpInside)
        tableView.tableFooterView = footerButton
        
        self.footerButton = footerButton
        
    }
    
    func refresh(object: AnyObject) {
        page = 1 // reset the page counter
        fetchUpdates()
    }
    
    func moreClick() {
        page++
        activityIndicator.startAnimating()
        tableView.tableFooterView = activityIndicator
        fetchUpdates()
    }
    
    
    func fetchUpdates() {
        
        
        MangaManager.sharedManager.getUpdates { [unowned self](manga) -> Void in
            
            if let refreshControl = self.refreshControl {
                refreshControl.endRefreshing()
            }
            
            if let manga = manga {
                if self.page == 1 {
                    //remove all mangas
                    self.manga = manga
                } else {
                    self.manga += manga
                }
                
                if self.tableView.tableFooterView == self.activityIndicator {
                    self.activityIndicator.stopAnimating()
                    self.tableView.tableFooterView = self.footerButton
                }
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manga.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MangaCell.defaultReusableId, forIndexPath: indexPath) as! MangaCell
        
        cell.configure(manga[indexPath.row])
        
        
        return cell
    }
    
    
}