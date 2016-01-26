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
    func chaptersControllerDidSelectChapter(chapter: Chapter)
}

class ChaptersController: UITableViewController {
    
    var delegate: ChaptersDelegate!
    var chapters: [Chapter]?
    
    convenience init(chapters: [Chapter]?, delegate: ChaptersDelegate) {
        self.init(style: UITableViewStyle.Grouped)
        
        self.delegate = delegate
        self.chapters = chapters
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(ChapterCell.self, forCellReuseIdentifier: ChapterCell.defaultReusableId)
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier(ChapterCell.defaultReusableId, forIndexPath: indexPath) as! ChapterCell
        
        cell.configure(chapters![indexPath.row])
        
        return cell
        
    }
    
}
