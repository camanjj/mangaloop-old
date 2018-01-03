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
        
        
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(MangaDetailsController.safariClick))
        extendedLayoutIncludesOpaqueBars = true
        
        self.segmentedPager.backgroundColor = UIColor.white
        
        // Parallax Header
        self.segmentedPager.parallaxHeader.view = headerView
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.fill;
        self.segmentedPager.parallaxHeader.height = 250;
        self.segmentedPager.parallaxHeader.minimumHeight = 80;
        
        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = .down;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.white
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.black];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.orange]
        self.segmentedPager.segmentedControl.selectionStyle = .fullWidthStripe
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor.orange
        
        fetchInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = UIColor.clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor.red
    }
    
    func fetchInfo() {
        
        HUD.show(.progress)
        
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
                    wself.headerView.mangaImageView.kf.indicatorType = .activity
                    wself.headerView.mangaImageView.kf.setImage(with: ImageResource(downloadURL: URL(string: imageUrl)!))
                }
                
                if let followers = manga.followers, let isFollowing = manga.following {
                    wself.headerView.followersLabel.text = "\(followers) Followers"
                    
                    if isFollowing {
                        wself.headerView.followButton.setTitle("Following", for: UIControlState())
                    } else {
                        wself.headerView.followButton.setTitle("+ Follow", for: UIControlState())
                    }
                    
                    wself.headerView.delegate = wself
                    
                    
                    wself.headerView.followersLabel.isHidden = false
                    wself.headerView.followButton.isHidden = false
                    
                } else {
                    wself.headerView.followersLabel.isHidden = true
                    wself.headerView.followButton.isHidden = true
                }
                
                
                // show warning for mature warning
                if let mature = manga.mature, !mature.isEmpty && MangaManager.getToggleSettings(.MatureWarning) == true {
                    
                    let alert = SCLAlertView()
                    alert.addButton("Go back", action: { () -> Void in
                        wself.navigationController?.popViewController(animated: true)
                    })
                    alert.addButton("Continue", action: { () -> Void in
                        wself.segmentedPager.reloadData()
                    })
//                    alert.showCloseButton = false
                    alert.showWarning("Mature Manga", subTitle: mature)
                    return
                    
                }
                
                
                
                
                wself.segmentedPager.reloadData()
            } else {
                // failed
                HUD.flash(.error, delay: 2.0)
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
    
    @objc func safariClick() {
        
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let webAction = UIAlertAction(title: "Open webpage", style: UIAlertActionStyle.default) { (action) -> Void in
            if let link = self.manga?.link, let url = URL(string: link) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                self.present(vc, animated: true, completion: nil)
            }
        }
        
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(webAction)
        
        present(actionSheet, animated: true, completion: nil)
        

        
    }
    
    //MARK: Chapters Delegate Method
    func chaptersControllerDidSelectChapter(_ chapter: Chapter, manga: MangaItem) {
        
        let reader = MangaReaderController.createReader(manga, chapter: chapter, allChapters: self.manga!.chapters)
        self.present(reader, animated: true, completion: nil)
    }
    
    //MARK: Pager Data Source Methods
    override func numberOfPages(in segmentedPager: MXSegmentedPager) -> Int {
        return 2
    }
    
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, titleForSectionAt index: Int) -> String {
        return ["Chapters", "Details"][index]
    }
    
//    override func segmentedPager(segmentedPager: MXSegmentedPager, viewForPageAtIndex index: Int) -> UIView {
//        return [(manga == nil ? UIView() : chaptersTable.view), detailsTable][index]
//    }
    
//    override func 
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, viewControllerForPageAt index: Int) -> UIViewController {
        return [(manga == nil ? UIViewController() : chaptersTable), detailsView][index]
    }
    
}
