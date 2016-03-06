//
//  SearchViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit

class DiscoverViewController: UICollectionViewController {
    
    let searchBar = UISearchBar()
    
    var dataSource: ArrayDataSource<DiscoverCell, MangaPreviewItem>!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        searchBar.delegate = self
        searchBar.showsBookmarkButton = true
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        
        let cellNib = UINib(nibName: String(DiscoverCell.self), bundle: nil)
        collectionView?.registerNib(cellNib, forCellWithReuseIdentifier: DiscoverCell.defaultReusableId)
        let flowLayout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = (UIScreen.mainScreen().bounds.width - 3) / 3
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        fetchPopularManga()
        
    }
    
    func fetchPopularManga() {
        MangaManager.sharedManager.getPopularManga { (manga) -> Void in
            if let manga = manga {
                self.dataSource = ArrayDataSource<DiscoverCell, MangaPreviewItem>(items: manga, cellReuseIdentifier: DiscoverCell.defaultReusableId, configureClosure: { (cell, manga) -> Void in
                    
                    cell.configure(manga.title, imageLink: manga.imageLink)
                    
                })
                print("Got mangas")
                self.collectionView?.dataSource = self.dataSource
                self.collectionView?.reloadData()
//                self.tableView.dataSource = self.dataSource
//                self.tableView.reloadData()
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let manga = dataSource.itemAtIndexPath(indexPath)
        
        let detailsController = MangaDetailsController(manga: manga)
        navigationController?.pushViewController(detailsController, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DiscoverViewController: UISearchBarDelegate {
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        
        let filterController = SearchFilterViewController()
        navigationController?.pushViewController(filterController, animated: true)
        
        
    }
}