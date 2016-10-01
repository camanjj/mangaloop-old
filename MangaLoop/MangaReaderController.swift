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
import JAMSVGImage
import SCLAlertView
import PKHUD
import Kingfisher


class MangaReaderController: UIViewController {
  
  
  var pageController: UIPageViewController?
  var webtoonReader: UITableView? // reader for the webtoons
  var manga: MangaItem // the manga that is being read
  var selectedChapter: Chapter { //  the current chapter
    didSet {
      prefetcher?.stop()
    }
    
  }
  var mangaPages = [MangaPageController(), MangaPageController(), MangaPageController()] // list of pages
  var urls: [NSURL]? // the list of all the urls for the pages
  
  
  
  var prefetcher: ImagePrefetcher?
  
  
  var allChapters: [Chapter]? // all of the chapters for the current manga
  
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
  class func createReader(manga: MangaItem, chapter: Chapter, allChapters: [Chapter]? = nil) -> UINavigationController {
    let reader = MangaReaderController(manga: manga, chapter: chapter)
    reader.allChapters = allChapters
    let navController = UINavigationController(rootViewController: reader)
    return navController
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(closeClick))
    
    // config the toolbar
    navigationController?.setToolbarHidden(false, animated: false)
    let itemSize = CGSize(width: 25, height: 25)
    let settingsItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.ReaderSettings, atSize: itemSize), style: .Plain, target: self, action: #selector(settingsClick))
    let chaptersItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.List, atSize: itemSize), style: .Plain, target: self, action: #selector(chaptersClick))
    let infoItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.Info, atSize: itemSize), style: .Plain, target: self, action: #selector(infoClick))
    toolbarItems = [settingsItem, chaptersItem, infoItem]
    
    view.backgroundColor = UIColor.whiteColor()
    
    // config the navigation bar
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
    
    
    /* for page in pages {
      page.removeFromSuperview()
      page.delegate = nil
      //            page.setFrame()
    } */
    
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
    
    /* for page in pages {
      page.transform = CGAffineTransformIdentity
    } */
    
    
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
    
    
    
    guard let pageController = pageController else {
      return
    }
    
    var selectedPage: MangaPageController
    
    if currentPage > -1 {
      // selectedPage = mangaPages[currentPage]
      
      if currentPage == 0 {
        selectedPage = mangaPages.first!
      } else if currentPage == urls!.count - 1 {
        selectedPage = mangaPages.last!
      } else {
        selectedPage = mangaPages[1]
      }
      
      selectedPage.mangaImageView.link = urls![currentPage]
      
    } else {
      
      selectedPage = mangaPages.first!
      selectedPage.mangaImageView.link = urls![0]
    }
    
    
    if mangaPages.isEmpty {
      pageController.setViewControllers([UIViewController()], direction: .Forward, animated: true, completion: nil)
    } else {
      pageController.setViewControllers([selectedPage], direction: .Forward, animated: true, completion: nil)
    }
    
    // add the page controller to the this view controller, if applicable
    if pageController.view.superview == nil {
      addChildViewController(pageController)
      view.addSubview(pageController.view)
      pageController.didMoveToParentViewController(self)
    }
    
  }
  
  
  func fetchPages(link: String) {
    
    HUD.show(.Progress)
    
    MangaManager.sharedManager.getPages(link) { [weak self] (pages) -> Void in
      
      guard let wself = self else {
        return
      }
      
      // make sure that the pages are valid
      if let pages = pages {
        
        if pages.isEmpty {
          print("The pages are empty. Batoto probably is not loading this chapter for some reason")
          HUD.flash(.Error, withDelay: 2.0)
          return
        }
        
        HUD.hide(animated: true, completion: nil)
        
        print("Got pages")
        
        // stop any pending requests
        wself.prefetcher?.stop()
        
        // set up the prefetcher with the urls for the pages
        wself.urls = pages.map { NSURL(string: $0)! }
        let cache = ImageCache(name: "manga-pages")
        wself.prefetcher = ImagePrefetcher(urls: wself.urls!, optionsInfo: [.TargetCache(cache)], progressBlock: nil, completionHandler: nil)
       
        wself.prefetcher?.start()
        
        // set up the current reader
        wself.setUpReader()
        
      } else {
        HUD.flash(.Error, withDelay: 2.0)
      }
    }
  }
  
  // cancels all of the pending image downloads
  func stopAllPageDownloads() {
    
    for page in mangaPages {
      page.cancelDownload()
    }
    
    prefetcher?.stop()
    
  }
  
  func closeClick() {
    stopAllPageDownloads()
    presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func settingsClick() {
    
    let settingsController = ReaderSettingsViewController()
    settingsController.delegate = self
    settingsController.title = "Reader Settings"
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
  
  func chaptersClick() {
    
    if let allChapters = allChapters {
      
      let chaptersController = ChaptersController(manga: manga, chapters: allChapters, delegate: self)
      let navController = UINavigationController()
      navController.viewControllers = [chaptersController]
      let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
      
      formSheet.interactivePanGestureDissmisalDirection = .All;
      //                formSheet.allowDismissByPanningPresentedView = true
      formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
      formSheet.contentViewControllerTransitionStyle = .Fade
      //                formSheet.presentationController?.shouldApplyBackgroundBlurEffect = true
      
      
      self.presentViewController(formSheet, animated: true, completion: nil)
      
    } else {
      //fetch the chapters
      
      MangaManager.sharedManager.getMangaDetails(manga.link, callback: { [weak self] (manga) -> Void in
        guard let wself = self else {
          return
        }
        
        guard let manga = manga else {
          return
        }
        
        wself.allChapters = manga.chapters
        wself.chaptersClick()
        })
    }
    
  }
  
  func infoClick() {
    
    SCLAlertView().showInfo(manga.title, subTitle: selectedChapter.title)
    
  }
  
  
}

extension MangaReaderController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    
    if mangaPages.isEmpty {
      return nil
    }
    
    guard let index = urls?.indexOf((viewController as! MangaPageController).mangaImageView.link!) else {
      return nil
    }
    
    
    let nextIndex = isReversed ? index - 1 : index + 1;
    if isReversed {
      if nextIndex < 0 {
        return nil
      }
    } else {
      if nextIndex >= urls?.count {
        return nil
      }
    }
    
    let page = mangaPages[nextIndex % 3]
    page.mangaImageView.link = urls![nextIndex]
    return page

  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    
    if mangaPages.isEmpty {
      return nil
    }
    
    
    guard let index = urls?.indexOf((viewController as! MangaPageController).mangaImageView.link!) else {
      return nil
    }
    
    
    let prevIndex = isReversed ? index + 1 : index - 1
    
    if isReversed {
      if prevIndex >= urls?.count {
        return nil
      }
    } else {
      if prevIndex < 0 {
        return nil
      }
    }
    
    let page = mangaPages[prevIndex % 3]
    page.mangaImageView.link = urls![prevIndex]
    return page
  }
  
  func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
    return urls?.count ?? 0
  }
  
  func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
    
    let direction = MangaManager.getReaderSettings(.Direction)
    
    return direction == .RightToLeft ? UIPageViewControllerSpineLocation.Max : UIPageViewControllerSpineLocation.Min
  }
  
  
}

extension MangaReaderController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("page", forIndexPath: indexPath) as! WebtoonCell
    
    
    /* let page = pages[indexPath.row]
    
    for view in cell.contentView.subviews {
      view.removeFromSuperview()
    }
    
    cell.contentView.addSubview(page)
    
    cell.contentView.snp_remakeConstraints { (make) -> Void in
      make.edges.equalTo(page)
    }
    
    page.updateConstraintsIfNeeded()
    
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = false; */
    
    return cell
    
    
  }
  
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return urls?.count ?? 0
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

extension MangaReaderController: ChaptersDelegate {
  func chaptersControllerDidSelectChapter(chapter: Chapter, manga: MangaItem) {
    self.dismissViewControllerAnimated(true) { [weak self] () -> Void in
      
      self?.selectedChapter = chapter
      self?.fetchPages(chapter.link)
    }
  }
}
