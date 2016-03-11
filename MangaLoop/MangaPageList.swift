//
//  MangaPageList.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 3/10/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation

protocol MangaPageList {
    func addFooterButton() -> UIButton
    func setupRefreshControl()
}

extension MangaPageList where Self: UITableViewController {
    
    
    func addFooterButton() -> UIButton {
        
        let footerButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 45))
        footerButton.setTitle("More", forState: .Normal)
        footerButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        footerButton.backgroundColor = UIColor.redColor()
        footerButton.addTarget(self, action: Selector("moreClick"), forControlEvents: .TouchUpInside)
        tableView.tableFooterView = footerButton
        
        return footerButton
        
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
}