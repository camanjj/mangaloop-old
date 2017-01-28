//
//  SearchViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Pantry


class DiscoverViewController: UICollectionViewController {
    
//    let searchBar = UISearchBar()
    
    let mangaSearchController = SearchViewController()
//    let searchController = UISearchController(searchResultsController: mangaSearchController)
    
    var searchController: UISearchController!
    
    var dataSource: ArrayDataSource<DiscoverCell, MangaPreviewItem>!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        searchController = UISearchController(searchResultsController: mangaSearchController)
        searchController.searchResultsUpdater = mangaSearchController
        searchController.searchBar.delegate = mangaSearchController
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    
        navigationItem.titleView = searchController.searchBar
        
        let cellNib = UINib(nibName: String(describing: DiscoverCell.self), bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: DiscoverCell.defaultReusableId)
        let flowLayout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = (UIScreen.main.bounds.width - 3) / 3
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        if let _: String = Pantry.unpack(Constants.Pantry.PopularFlag),
            let manga: [MangaPreviewItem] = Pantry.unpack(Constants.Pantry.Popular) {
           setDataSource(manga)
        } else {
            fetchPopularManga()
        }
        
        
    }
    
    func fetchPopularManga() {
        MangaManager.sharedManager.getPopularManga { (manga) -> Void in
            if let manga = manga {
                
                Pantry.pack(manga, key: Constants.Pantry.Popular) // store for six hours
                Pantry.pack("flag", key: Constants.Pantry.PopularFlag, expires: StorageExpiry.seconds(60 * 60 * 6))
                
                self.setDataSource(manga)
            }
        }
    }
    
    func setDataSource(_ manga: [MangaPreviewItem]) {
        self.dataSource = ArrayDataSource<DiscoverCell, MangaPreviewItem>(items: manga, cellReuseIdentifier: DiscoverCell.defaultReusableId, configureClosure: { (cell, manga) -> Void in
            
            cell.configure(manga.title, imageLink: manga.imageLink)
            
        })
        self.collectionView?.dataSource = self.dataSource
        self.collectionView?.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let manga = dataSource.itemAtIndexPath(indexPath)
        
        let detailsController = MangaDetailsController(manga: manga)
        navigationController?.pushViewController(detailsController, animated: true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DiscoverViewController: UISearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async(execute: {
            searchController.searchResultsController!.view.isHidden = false;
        })
    }
    
}
