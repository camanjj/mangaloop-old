//
//  MangaReaderController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/28/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit

class MangaReaderController: UIViewController {
    
    
    let pageController = UIPageViewController()
    var manga: MangaItem
    var selectedChapter: Chapter
    var mangaPages = [MangaPageController]()
    
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
        
        automaticallyAdjustsScrollViewInsets = false
        navigationController?.navigationBar.translucent = true
        navigationController?.toolbar.translucent = true
        
        pageController.dataSource = self
        pageController.setViewControllers([UIViewController()], direction: .Forward, animated: true, completion: nil)
        
        // add the page controller to the this view controller
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        fetchPages(selectedChapter.link)
        
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
                self.mangaPages = [MangaPageController]()
                
                // add the new pages
                for page in pages {
                    self.mangaPages.append(MangaPageController(imageLink: page))
                }
                
                
                self.pageController.setViewControllers([self.mangaPages.first!], direction: .Forward, animated: true, completion: nil)
                self.pageController.dataSource = nil
                self.pageController.dataSource = self
                
            }
        }
    }
    
    func closeClick() {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}

extension MangaReaderController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if mangaPages.isEmpty {
            return nil
        }

        guard let index = mangaPages.indexOf(viewController as! MangaPageController) else {
            return nil
        }
        
        let nextIndex = index + 1
        
        if nextIndex >= mangaPages.count {
            return nil
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
        
        let prevIndex = index - 1
        
        if prevIndex < 0 {
            return nil
        }
        return mangaPages[prevIndex]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return mangaPages.count
    }
}