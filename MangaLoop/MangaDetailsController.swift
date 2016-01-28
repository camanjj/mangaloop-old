//
//  MangaDetailsController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/25/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import MXSegmentedPager

class MangaDetailsController: MXSegmentedPagerController, ChaptersDelegate {
    
    var chaptersTable: ChaptersController!
    var detailsTable: UITableView! = UITableView()
    
    var previewItem: MangaPreviewItem!
    var manga: MangaDetailItem?
    
    convenience init(manga: MangaPreviewItem) {
        self.init()
        previewItem = manga
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationController?.navigationBar.translucent = false
        
        
        self.segmentedPager.backgroundColor = UIColor.whiteColor()
        
        // Parallax Header
//        self.segmentedPager.parallaxHeader.view = MXHeaderView.instanceFromNib();
//        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.Fill;
//        self.segmentedPager.parallaxHeader.height = 150;
//        self.segmentedPager.parallaxHeader.minimumHeight = 20;
        
        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.whiteColor()
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blackColor()];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [NSForegroundColorAttributeName : UIColor.orangeColor()]
        self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor.orangeColor()
        
        fetchInfo()
    }
    
    func fetchInfo() {
        MangaManager.sharedManager.getMangaDetails(previewItem.link) { [unowned self](manga) -> Void in
            if let manga = manga {
                
                self.manga = manga
                self.chaptersTable = ChaptersController(chapters: manga.chapters, delegate: self)
                
                self.segmentedPager.reloadData()
            } else {
                // failed
            }
        }
    }
    
    //MARK: Chapters Delegate Method
    func chaptersControllerDidSelectChapter(chapter: Chapter) {
        
    }
    
    //MARK: Pager Data Source Methods
    override func numberOfPagesInSegmentedPager(segmentedPager: MXSegmentedPager) -> Int {
        return 2
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, titleForSectionAtIndex index: Int) -> String {
        return ["Chapters", "Details"][index]
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, viewForPageAtIndex index: Int) -> UIView {
        return [(manga == nil ? UIView() : chaptersTable.view), detailsTable][index]
    }
    
}