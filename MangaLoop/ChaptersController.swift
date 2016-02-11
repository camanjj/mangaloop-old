//
//  ChaptersController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit


protocol ChaptersDelegate {
    func chaptersControllerDidSelectChapter(chapter: Chapter, manga: MangaItem)
}

class ChaptersController: UITableViewController {
    
    var delegate: ChaptersDelegate!
    var chapters: [Chapter]?
    var manga: MangaItem!
    
    convenience init(manga: MangaItem, chapters: [Chapter]?, delegate: ChaptersDelegate) {
        self.init(style: UITableViewStyle.Grouped)
        
        self.manga = manga
        self.delegate = delegate
        self.chapters = chapters
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(ItemCell.self, forCellReuseIdentifier: ItemCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        navigationItem.title = "Chapters"
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let chapters = self.chapters else {
            return 0
        }
        
        return chapters.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(ItemCell.defaultReusableId, forIndexPath: indexPath) as! ItemCell
        
        cell.configure(chapters![indexPath.row])
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chapter = self.chapters![indexPath.row]
        
        delegate.chaptersControllerDidSelectChapter(chapter, manga: manga)
    }
    
}

//extension ChaptersDelegate where Self : UpdatesViewController {
//    
//}
