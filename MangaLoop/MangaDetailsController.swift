//
//  MangaDetailsController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/25/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import MXSegmentedPager
import Kingfisher
import SCLAlertView


class MangaDetailsController: MXSegmentedPagerController, ChaptersDelegate {
    
    var chaptersTable: ChaptersController!
    var detailsView: DetailController = DetailController()
    var headerView = DetailHeaderView.loadFromNib()
    
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
        self.segmentedPager.parallaxHeader.view = headerView
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.Fill;
        self.segmentedPager.parallaxHeader.height = 250;
        self.segmentedPager.parallaxHeader.minimumHeight = 65;
        
        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.whiteColor()
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blackColor()];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [NSForegroundColorAttributeName : UIColor.orangeColor()]
        self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor.orangeColor()
        
        fetchInfo()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barTintColor = UIColor.redColor()
    }
    
    func fetchInfo() {
        MangaManager.sharedManager.getMangaDetails(previewItem.link) { [unowned self](manga) -> Void in
            if let manga = manga {
                
                self.manga = manga
                self.chaptersTable = ChaptersController(manga: manga, chapters: manga.chapters, delegate: self)
                self.detailsView.textView.text = manga.summary
                
                self.headerView.titleLabel.text = manga.title
                if let imageUrl = manga.image {
                    self.headerView.mangaImageView.kf_setImageWithURL(NSURL(string: imageUrl)!)
                }
                
                
                // show warning for mature warning
                if let mature = manga.mature where MangaManager.getToggleSettings(.MatureWarning) == true {
                    
                    let alert = SCLAlertView()
                    alert.addButton("Go back", action: { () -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                    alert.addButton("Continue", action: { () -> Void in
                        self.segmentedPager.reloadData()
                    })
                    alert.showCloseButton = false
                    alert.showWarning("Mature Manga", subTitle: mature)
                    return
                    
                }
                
                
                
                
                self.segmentedPager.reloadData()
            } else {
                // failed
            }
        }
    }
    
    //MARK: Chapters Delegate Method
    func chaptersControllerDidSelectChapter(chapter: Chapter, manga: MangaItem) {
        
        let reader = MangaReaderController.createReader(manga, chapter: chapter)
        self.presentViewController(reader, animated: true, completion: nil)
    }
    
    //MARK: Pager Data Source Methods
    override func numberOfPagesInSegmentedPager(segmentedPager: MXSegmentedPager) -> Int {
        return 2
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, titleForSectionAtIndex index: Int) -> String {
        return ["Chapters", "Details"][index]
    }
    
//    override func segmentedPager(segmentedPager: MXSegmentedPager, viewForPageAtIndex index: Int) -> UIView {
//        return [(manga == nil ? UIView() : chaptersTable.view), detailsTable][index]
//    }
    
//    override func 
    override func segmentedPager(segmentedPager: MXSegmentedPager, viewControllerForPageAtIndex index: Int) -> UIViewController {
        return [(manga == nil ? UIViewController() : chaptersTable), detailsView][index]
    }
    
}