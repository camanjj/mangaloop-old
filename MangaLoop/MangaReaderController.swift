//
//  MangaReaderController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/28/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit
import MZFormSheetPresentationController
import SnapKit

class MangaReaderController: UIViewController {
    
    
    var pageController: UIPageViewController?
    var webtoonReader: UITableView?
    var manga: MangaItem
    var selectedChapter: Chapter
    var pages: [MangaPageImageView]!
    var mangaPages = [MangaPageController]()
    
    var isWebtoonMode : Bool?
    
    var isReversed: Bool = false
    
    var transitionStyle: UIPageViewControllerTransitionStyle {
        get {
            let trans = MangaManager.getReaderSettings(.Transition)
            return trans == .Curl ? .PageCurl : .Scroll
        }
    }
    
    var orientation: UIPageViewControllerNavigationOrientation {
        get {
            let direction = MangaManager.getReaderSettings(.Direction)
            isReversed = direction == .RightToLeft
            return direction == .Webtoon ? .Vertical : .Horizontal
        }
    }
    
    
    
    init(manga: MangaItem, chapter: Chapter) {
        self.manga = manga
        self.selectedChapter = chapter
        super.init(nibName: nil, bundle: nil)

    }
    
    // creates the reader and embeds it in a navigation controller
    class func createReader(manga: MangaItem, chapter: Chapter) -> UINavigationController {
        let reader = MangaReaderController(manga: manga, chapter: chapter)
        let navController = UINavigationController(rootViewController: reader)
        return navController
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: Selector("closeClick"))
        navigationController?.setToolbarHidden(false, animated: false)
        
        let settingsItem = UIBarButtonItem(title: "Settings", style: .Plain, target: self, action: Selector("settingsClick"))
        toolbarItems = [settingsItem]
        
        view.backgroundColor = UIColor.whiteColor()
        
        automaticallyAdjustsScrollViewInsets = false
        navigationController?.navigationBar.translucent = true
        navigationController?.toolbar.translucent = true
        
        fetchPages(selectedChapter.link)
        
    }
    
    func setUpReader() {
        
        var currentPage = -1
        
        if pageController?.view.superview != nil {
            
            let page = pageController!.viewControllers?.last as? MangaPageController
            currentPage = mangaPages.indexOf(page!)!
            
            
        } else if webtoonReader?.superview != nil {
            let visibleCells = webtoonReader!.visibleCells
            currentPage = webtoonReader!.indexPathForCell(visibleCells.first!)!.row
        }
        
        // clean up the current view
        pageController?.removeFromParentViewController()
        pageController?.view.removeFromSuperview()
        webtoonReader?.removeFromSuperview()
        
        
        for page in pages {
            page.removeFromSuperview()
            page.delegate = nil
//            page.setFrame()
        }
        
        if orientation == .Vertical {
            webtoonSetup(currentPage)
        } else {
            pageSetup(currentPage)
        }
    }
    
    func webtoonSetup(currentPage: Int) {
        
        if webtoonReader == nil {
            webtoonReader = UITableView(frame: UIScreen.mainScreen().bounds)

            let nib = UINib(nibName: String(WebtoonCell.self), bundle: nil)
            webtoonReader!.registerNib(nib, forCellReuseIdentifier: "page")
            webtoonReader!.separatorInset = UIEdgeInsetsZero
            webtoonReader!.separatorColor = UIColor.clearColor()
            webtoonReader!.rowHeight = UITableViewAutomaticDimension
            webtoonReader!.estimatedRowHeight = 600
        }

        view.addSubview(webtoonReader!)
        
        for page in pages {
            page.transform = CGAffineTransformIdentity
        }
        
        
        webtoonReader!.delegate = self
        webtoonReader!.dataSource = self
        webtoonReader!.reloadData()
        
        
        if currentPage > -1 {
            webtoonReader!.scrollToRowAtIndexPath(NSIndexPath(forRow: currentPage, inSection: 0), atScrollPosition: .None, animated: true)
        }
        
    }
    
    func pageSetup(currentPage: Int) {
        
        
//        if pageController == nil {
            pageController = UIPageViewController(transitionStyle: transitionStyle, navigationOrientation: orientation, options: nil)
            pageController!.dataSource = self
            pageController!.delegate = self
//        }
        
        
        mangaPages = [MangaPageController]()
        
        
        guard let pageController = pageController else {
            return
        }
        
        
        
        // remove the pages from the previous super view
        for page in pages {
            page.transform = CGAffineTransformIdentity
            let mangaPageController = MangaPageController()
            mangaPageController.addMangaPage(page)
            mangaPages.append(mangaPageController)
        }
        
        var selectedPage: MangaPageController
        
        if currentPage > -1 {
            selectedPage = mangaPages[currentPage]
        } else {
            selectedPage = mangaPages.first!
        }
        
        
        if mangaPages.isEmpty {
            pageController.setViewControllers([UIViewController()], direction: .Forward, animated: true, completion: nil)
        } else {
            pageController.setViewControllers([selectedPage], direction: .Forward, animated: true, completion: nil)
        }
        
        // add the page controller to the this view controller
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
    }
    
    
    func fetchPages(link: String) {
        MangaManager.sharedManager.getPages(link) { [unowned self] (pages) -> Void in
            if let pages = pages {
                
                if pages.isEmpty {
                    print("The pages are empty. Batoto probably is not loading this chapter for some reason")
                    return
                }
                
                print("Got pages")
                
                // Stop any manga page downloads
                for mangaPage in self.mangaPages {
                    mangaPage.cancelDownload()
                }
                
                // remove all the previous pages
                self.pages = [MangaPageImageView]()
                
                // add the new pages
                for page in pages {
                    let mangaPage = MangaPageImageView(link: page)
                    self.pages.append(mangaPage)
                    mangaPage.downloadMangaPage()
                }
                
                
                self.setUpReader()
                
            }
        }
    }
    
    // cancels all of the pending image downloads
    func stopAllPageDownloads() {
        
        for page in mangaPages {
            page.cancelDownload()
        }
        
    }
    
    func closeClick() {
        stopAllPageDownloads()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func settingsClick() {
        
        let settingsController = ReaderSettingsViewController()
        settingsController.delegate = self
        let navController = UINavigationController()
        navController.viewControllers = [settingsController]
        let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
        
        formSheet.interactivePanGestureDissmisalDirection = .All;
        //                formSheet.allowDismissByPanningPresentedView = true
        formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
        formSheet.contentViewControllerTransitionStyle = .Fade
        //                formSheet.presentationController?.shouldApplyBackgroundBlurEffect = true
        
        
        self.presentViewController(formSheet, animated: true, completion: nil)

        
        
    }
    
    
}

extension MangaReaderController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if mangaPages.isEmpty {
            return nil
        }

        guard let index = mangaPages.indexOf(viewController as! MangaPageController) else {
            return nil
        }
        
        var nextIndex = 0
        if isReversed {
            
            nextIndex = index - 1
            
            if nextIndex < 0 {
                return nil
            }
            
        } else {
            
            nextIndex = index + 1
            
            if nextIndex >= mangaPages.count {
                return nil
            }

        }
        
        return mangaPages[nextIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if mangaPages.isEmpty {
            return nil
        }
        
        
        guard let index = mangaPages.indexOf(viewController as! MangaPageController) else {
            return nil
        }
        
        var prevIndex = 0
        
        if isReversed {
            
            prevIndex = index + 1
            
            if prevIndex >= mangaPages.count {
                return nil
            }
            
        } else {
            
            prevIndex = index - 1
            
            if prevIndex < 0 {
                return nil
            }
            
        }
        
        return mangaPages[prevIndex]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return mangaPages.count
    }
    
    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        
        let direction = MangaManager.getReaderSettings(.Direction)
        
        return direction == .RightToLeft ? UIPageViewControllerSpineLocation.Max : UIPageViewControllerSpineLocation.Min
    }
    
    
}

extension MangaReaderController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("page", forIndexPath: indexPath) as! WebtoonCell
        

        let page = pages[indexPath.row]
        
        for view in cell.contentView.subviews {
            view.removeFromSuperview()
        }
        
        cell.contentView.addSubview(page)
        
        cell.contentView.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(page)
        }
        
//        page.frame.origin = CGPoint.zero
        page.updateConstraintsIfNeeded()
//        print(page.frame.size)
        
        
        cell.layoutMargins = UIEdgeInsetsZero;
        cell.preservesSuperviewLayoutMargins = false;
        
        return cell
        
        
    }
    
//    func tableViewWillEnd
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pages.count
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        let page = pages[indexPath.row]
//        
//        if page.image != nil {
//            return page.bounds.height
//        } else {
//            return UITableViewAutomaticDimension
//        }
//    }
    
}

extension MangaReaderController: ReaderSettingsDelegate {
    func updatedSettings() {
        // update the settings for the reader
        setUpReader()
    }
}