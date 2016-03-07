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
import SafariServices
import PKHUD


class MangaDetailsController: MXSegmentedPagerController, ChaptersDelegate, DetailHeaderDelegate {
    
    var chaptersTable: ChaptersController!
    var detailsView: DetailController = DetailController()
    var headerView = DetailHeaderView.loadFromNib()
    
    var previewItem: MangaPreviewItem!
    var manga: MangaDetailItem?
    var isFollowing: Bool? {
        didSet {
            
            if isFollowing == true {
                
                self.headerView.followButton.endAnimation(0, title: "Following")
//                self.headerView
                
            } else {
                self.headerView.followButton.endAnimation(0, title: "+Follow")

            }
            
        }
    }
    
    convenience init(manga: MangaPreviewItem) {
        self.init()
        previewItem = manga
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationController?.navigationBar.translucent = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("safariClick"))
        extendedLayoutIncludesOpaqueBars = true
        
        self.segmentedPager.backgroundColor = UIColor.whiteColor()
        
        // Parallax Header
        self.segmentedPager.parallaxHeader.view = headerView
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.Fill;
        self.segmentedPager.parallaxHeader.height = 250;
        self.segmentedPager.parallaxHeader.minimumHeight = 80;
        
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
        navigationController?.navigationBar.barTintColor = UIColor.clearColor()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barTintColor = UIColor.redColor()
    }
    
    func fetchInfo() {
        
        HUD.show(.Progress)
        
        MangaManager.sharedManager.getMangaDetails(previewItem.link) { [weak self](manga) -> Void in
            
            HUD.hide(animated: false, completion: nil)

            
            if let manga = manga {
                
                guard let wself = self else { return }
                
                wself.manga = manga
                wself.isFollowing = manga.following
                wself.chaptersTable = ChaptersController(manga: manga, chapters: manga.chapters, delegate: wself)
                wself.detailsView.textView.text = manga.summary
                wself.detailsView.tagsControl.tags = NSMutableArray(array: manga.genre)
                wself.detailsView.tagsControl.reloadTagSubviews()
                
                wself.headerView.titleLabel.text = manga.title
                if let imageUrl = manga.image {
                    wself.headerView.mangaImageView.kf_showIndicatorWhenLoading = true
                    wself.headerView.mangaImageView.kf_setImageWithURL(NSURL(string: imageUrl)!)
                }
                
                if let followers = manga.followers, isFollowing = manga.following {
                    wself.headerView.followersLabel.text = "\(followers) Followers"
                    
                    if isFollowing {
                        wself.headerView.followButton.setTitle("Following", forState: .Normal)
                    } else {
                        wself.headerView.followButton.setTitle("+ Follow", forState: .Normal)
                    }
                    
                    wself.headerView.delegate = wself
                    
                    
                    wself.headerView.followersLabel.hidden = false
                    wself.headerView.followButton.hidden = false
                    
                } else {
                    wself.headerView.followersLabel.hidden = true
                    wself.headerView.followButton.hidden = true
                }
                
                
                // show warning for mature warning
                if let mature = manga.mature where !mature.isEmpty && MangaManager.getToggleSettings(.MatureWarning) == true {
                    
                    let alert = SCLAlertView()
                    alert.addButton("Go back", action: { () -> Void in
                        wself.navigationController?.popViewControllerAnimated(true)
                    })
                    alert.addButton("Continue", action: { () -> Void in
                        wself.segmentedPager.reloadData()
                    })
                    alert.showCloseButton = false
                    alert.showWarning("Mature Manga", subTitle: mature)
                    return
                    
                }
                
                
                
                
                wself.segmentedPager.reloadData()
            } else {
                // failed
                HUD.flash(.Error, withDelay: 2.0)
            }
        }
    }
    
    func followClick() {
        
        guard let manga = self.manga else { return }
        
        let action: FollowAction = isFollowing == true ? .UnFollow : .Follow
        
        MangaManager.sharedManager.followManga(manga, action: action, callback: { (success) -> Void in
            
            if success {
                
                // reverse if the user was following
                self.isFollowing = !self.isFollowing!
                
            } else {
                
            }
            
        })
        
    }
    
    func safariClick() {
        
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let webAction = UIAlertAction(title: "Open webpage", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let link = self.manga?.link, url = NSURL(string: link) {
                let vc = SFSafariViewController(URL: url, entersReaderIfAvailable: false)
                self.presentViewController(vc, animated: true, completion: nil)
            }
        }
        
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(webAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
        

        
    }
    
    //MARK: Chapters Delegate Method
    func chaptersControllerDidSelectChapter(chapter: Chapter, manga: MangaItem) {
        
        let reader = MangaReaderController.createReader(manga, chapter: chapter, allChapters: self.manga!.chapters)
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