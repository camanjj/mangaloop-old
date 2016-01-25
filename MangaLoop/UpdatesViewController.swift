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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        fetchUpdates()
        
    }
    
    
    func fetchUpdates() {
        
        MangaManager.sharedManager.getUpdates { [unowned self](manga) -> Void in
            if let manga = manga {
                if self.page == 1 {
                    //remove all mangas
                    self.manga = manga
                } else {
                    self.manga += manga
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