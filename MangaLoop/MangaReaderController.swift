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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}



class MangaReaderController: UIViewController {
  
  
  var pageController: UIPageViewController?
  var webtoonReader: UITableView? // reader for the webtoons
  var manga: MangaItem // the manga that is being read
  var selectedChapter: Chapter { //  the current chapter
    didSet {
      navigationItem.title = selectedChapter.title
      prefetcher?.stop()
    }
    
  }
  var mangaPages = [MangaPageController(), MangaPageController(), MangaPageController()] // list of pages
  var urls: [URL]? // the list of all the urls for the pages
  
  
  
  var prefetcher: ImagePrefetcher?
  
  
  var allChapters: [Chapter]? // all of the chapters for the current manga
  
  var isReversed: Bool = false
  
  var transitionStyle: UIPageViewControllerTransitionStyle {
    get {
      let trans = MangaManager.getReaderSettings(.Transition)
      return trans == .Curl ? .pageCurl : .scroll
    }
  }
  
  var orientation: UIPageViewControllerNavigationOrientation {
    get {
      let direction = MangaManager.getReaderSettings(.Direction)
      isReversed = direction == .RightToLeft
      return direction == .Webtoon ? .vertical : .horizontal
    }
  }
  
  init(manga: MangaItem, chapter: Chapter) {
    self.manga = manga
    self.selectedChapter = chapter
    super.init(nibName: nil, bundle: nil)
    
  }
  
  // creates the reader and embeds it in a navigation controller
  class func createReader(_ manga: MangaItem, chapter: Chapter, allChapters: [Chapter]? = nil) -> UINavigationController {
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
    
    navigationItem.title = selectedChapter.title
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeClick))
    
    // config the toolbar
    navigationController?.setToolbarHidden(false, animated: false)
    let itemSize = CGSize(width: 25, height: 25)
    let settingsItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.ReaderSettings, at: itemSize), style: .plain, target: self, action: #selector(settingsClick))
    let chaptersItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.List, at: itemSize), style: .plain, target: self, action: #selector(chaptersClick))
    let infoItem = UIBarButtonItem(image: UIImage(fromSVGNamed: Constants.Images.Info, at: itemSize), style: .plain, target: self, action: #selector(infoClick))
    
    let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    fixedSpace.width = 40;
    
    toolbarItems = [settingsItem, fixedSpace, chaptersItem, fixedSpace, infoItem]
    
    view.backgroundColor = UIColor.white
    
    // config the navigation bar
    automaticallyAdjustsScrollViewInsets = false
    navigationController?.navigationBar.isTranslucent = true
    navigationController?.toolbar.isTranslucent = true
    
    fetchPages(selectedChapter.link)
    
  }
  
  func setUpReader() {
    
    var currentPage = -1
    
    if pageController?.view.superview != nil {
      
      let page = pageController!.viewControllers?.last as? MangaPageController
      currentPage = mangaPages.index(of: page!)!
      
      
    } else if webtoonReader?.superview != nil {
      let visibleCells = webtoonReader!.visibleCells
      currentPage = webtoonReader!.indexPath(for: visibleCells.first!)!.row
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
    
    if orientation == .vertical {
      webtoonSetup(currentPage)
    } else {
      pageSetup(currentPage)
    }
  }
  
  func webtoonSetup(_ currentPage: Int) {
    
    if webtoonReader == nil {
      webtoonReader = UITableView(frame: UIScreen.main.bounds)
      
      let nib = UINib(nibName: String(describing: WebtoonCell.self), bundle: nil)
      webtoonReader!.register(nib, forCellReuseIdentifier: "page")
      webtoonReader!.separatorInset = UIEdgeInsets.zero
      webtoonReader!.separatorColor = UIColor.clear
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
      webtoonReader!.scrollToRow(at: IndexPath(row: currentPage, section: 0), at: .none, animated: true)
    }
    
  }
  
  func pageSetup(_ currentPage: Int) {
    
    
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
      pageController.setViewControllers([UIViewController()], direction: .forward, animated: true, completion: nil)
    } else {
      pageController.setViewControllers([selectedPage], direction: .forward, animated: true, completion: nil)
    }
    
    // add the page controller to the this view controller, if applicable
    if pageController.view.superview == nil {
      addChildViewController(pageController)
      view.addSubview(pageController.view)
      pageController.didMove(toParentViewController: self)
    }
    
  }
  
  
  func fetchPages(_ link: String) {
    
    HUD.show(.progress)
    
    MangaManager.sharedManager.getPages(link) { [weak self] (pages) -> Void in
      
      guard let wself = self else {
        return
      }
      
      // make sure that the pages are valid
      if let pages = pages {
        
        if pages.isEmpty {
          print("The pages are empty. Batoto probably is not loading this chapter for some reason")
          HUD.flash(.error, delay: 2.0)
          return
        }
        
        HUD.hide(animated: true, completion: nil)
        
        print("Got pages")
        
        // stop any pending requests
        wself.prefetcher?.stop()
        
        // set up the prefetcher with the urls for the pages
        wself.urls = pages.map { URL(string: $0)! }
        let cache = ImageCache(name: "manga-pages")
        wself.prefetcher = ImagePrefetcher(urls: wself.urls!, options: [.targetCache(cache)], progressBlock: nil, completionHandler: nil)
       
        wself.prefetcher?.start()
        
        // set up the current reader
        wself.setUpReader()
        
      } else {
        HUD.flash(.error, delay: 2.0)
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
  
  @objc func closeClick() {
    stopAllPageDownloads()
    presentingViewController!.dismiss(animated: true, completion: nil)
  }
  
  @objc func settingsClick() {
    
    let settingsController = ReaderSettingsViewController()
    settingsController.delegate = self
    settingsController.title = "Reader Settings"
    let navController = UINavigationController()
    navController.viewControllers = [settingsController]
    let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
    
    formSheet.interactivePanGestureDismissalDirection = .all;
    //                formSheet.allowDismissByPanningPresentedView = true
    formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
    formSheet.contentViewControllerTransitionStyle = .fade
    //                formSheet.presentationController?.shouldApplyBackgroundBlurEffect = true
    
    
    self.present(formSheet, animated: true, completion: nil)
    
  }
  
  @objc func chaptersClick() {
    
    if let allChapters = allChapters {
      
      let chaptersController = ChaptersController(manga: manga, chapters: allChapters, delegate: self)
      let navController = UINavigationController()
      navController.viewControllers = [chaptersController]
      let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
      
      formSheet.interactivePanGestureDismissalDirection = .all;
      //                formSheet.allowDismissByPanningPresentedView = true
      formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
      formSheet.contentViewControllerTransitionStyle = .fade
      //                formSheet.presentationController?.shouldApplyBackgroundBlurEffect = true
      
      
      self.present(formSheet, animated: true, completion: nil)
      
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
  
  @objc func infoClick() {
    SCLAlertView().showInfo(manga.title, subTitle: selectedChapter.title)
  }
  
  
}

extension MangaReaderController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
    if mangaPages.isEmpty {
      return nil
    }
    
    guard let index = urls?.index(of: (viewController as! MangaPageController).mangaImageView.link!) else {
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
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
    if mangaPages.isEmpty {
      return nil
    }
    
    
    guard let index = urls?.index(of: (viewController as! MangaPageController).mangaImageView.link!) else {
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
  
  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return urls?.count ?? 0
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
    
    let direction = MangaManager.getReaderSettings(.Direction)
    
    return direction == .RightToLeft ? UIPageViewControllerSpineLocation.max : UIPageViewControllerSpineLocation.min
  }
  
  
}

extension MangaReaderController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "page", for: indexPath) as! WebtoonCell
    
    
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
  
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
  func chaptersControllerDidSelectChapter(_ chapter: Chapter, manga: MangaItem) {
    self.dismiss(animated: true) { [weak self] () -> Void in
      
      self?.selectedChapter = chapter
      self?.fetchPages(chapter.link)
    }
  }
}
