//
//  UpdatesViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit
import MZFormSheetPresentationController
import Pantry
import RealmSwift



class UpdatesViewController: UITableViewController, MangaPageList, ChaptersDelegate {
    
    var page = 1
    var manga: [MangaPreviewItem] = []
    
    var followManga: [FollowManga]?
    var followToken: NotificationToken!
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var footerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        followManga = FollowManga.getAllFollows()
        let realm = try! Realm()
        followToken = realm.objects(FollowManga).addNotificationBlock { (changes: RealmCollectionChange) in
            self.followManga = FollowManga.getAllFollows()
            self.tableView.reloadData()
        }
        
        
        navigationController?.navigationBar.isTranslucent = false
        
        title = "Updates"
        
        tableView.register(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        // add pull to refresh control
        setupRefreshControl()
        
        
        if let manga: [MangaPreviewItem] = Pantry.unpack("update-list") {
            
            self.manga = manga
            tableView.reloadData()
            
        } else {
            fetchUpdates()
        }
        
        footerButton = addFooterButton()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(UpdatesViewController.longPress(_:)))
        self.tableView.addGestureRecognizer(longPressRecognizer)
        
    }
    
    func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            
            let touchPoint = longPressGestureRecognizer.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchPoint) {
                
                // your code here, get the row for the indexPath or do whatever you want
                print(indexPath)
                
                let selectedManga = manga[indexPath.row]
                self.showChapters(selectedManga)
                
            }
        }
    }
    
    func showChapters(_ manga: MangaPreviewItem) {
        
        
        let chaptersController = ChaptersController(manga: manga, chapters: manga.chapters, delegate: self)
        let navController = UINavigationController()
        navController.viewControllers = [chaptersController]
        let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
        
        formSheet.interactivePanGestureDismissalDirection = .all;
        //                formSheet.allowDismissByPanningPresentedView = true
        formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
        formSheet.contentViewControllerTransitionStyle = .fade
        //                formSheet.presentationController?.shouldApplyBackgroundBlurEffect = true
        
        
        self.present(formSheet, animated: true, completion: nil)
    }
    
    func refresh(_ object: AnyObject) {
        page = 1 // reset the page counter
        fetchUpdates()
    }
    
    func moreClick() {
        page += 1
        activityIndicator.startAnimating()
        tableView.tableFooterView = activityIndicator
        fetchUpdates()
    }
    
    
    func fetchUpdates() {
        
        
        MangaManager.sharedManager.getUpdates (page) { [unowned self](manga) -> Void in
            
            if let refreshControl = self.refreshControl {
                refreshControl.endRefreshing()
            }
            
            if let manga = manga {
                if self.page == 1 {
                    //remove all mangas
                    self.manga = manga
                    
                    Pantry.pack(manga, key: "update-list")
                    
                } else {
                    self.manga += manga
                }
                
                if self.tableView.tableFooterView == self.activityIndicator {
                    self.activityIndicator.stopAnimating()
                    self.tableView.tableFooterView = self.footerButton
                }
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    //MARK: Chapter Delegate
    func chaptersControllerDidSelectChapter(_ chapter: Chapter, manga: MangaItem) {
        
        self.dismiss(animated: true) { [weak self] () -> Void in
            
            let reader = MangaReaderController.createReader(manga, chapter: chapter)
            self?.present(reader, animated: true, completion: nil)
            
        }
    }
    
    // MARK: UITableView DataSource/Delegate Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manga.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MangaCell.defaultReusableId, for: indexPath) as! MangaCell
        
        let manga = self.manga[indexPath.row]
        let isFollowing: Bool! = followManga != nil ? !followManga!.filter({$0.id == manga.mangaId}).isEmpty : false
        cell.configure(manga, isFollowing: isFollowing)
        cell.chaptersButton.addTarget(self, action: #selector(UpdatesViewController.accessoryClick(_:)), for: .touchUpInside)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedManga = manga[indexPath.row]
        let detailsController = MangaDetailsController(manga: selectedManga)
        navigationController?.pushViewController(detailsController, animated: true)
    }
    
    
    func accessoryClick(_ sender: UIButton!) {
        
        let rect = tableView.convert(sender.center, from: sender.superview)
        let indexPath = tableView.indexPathForRow(at: rect)!
        print(indexPath)
        let selectedManga = manga[indexPath.row]
        
        showChapters(selectedManga)
        
    }
    
    
    deinit {
        followToken.stop()
    }
    
}
