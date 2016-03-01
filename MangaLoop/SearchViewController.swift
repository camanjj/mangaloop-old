//
//  SearchViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController {
    
    let searchBar = UISearchBar()
    
    var dataSource: ArrayDataSource<MangaCell, MangaPreviewItem>!

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
        
        tableView.registerClass(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        fetchPopularManga()
        
    }
    
    func fetchPopularManga() {
        MangaManager.sharedManager.getPopularManga { (manga) -> Void in
            if let manga = manga {
                self.dataSource = ArrayDataSource<MangaCell, MangaPreviewItem>(items: manga, cellReuseIdentifier: MangaCell.defaultReusableId, configureClosure: { (cell, manga) -> Void in
                    
                    cell.configure(manga)
                    
                })
                
                self.tableView.dataSource = self.dataSource
                self.tableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SearchViewController: UISearchBarDelegate {
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        
        let filterController = SearchFilterViewController()
        navigationController?.pushViewController(filterController, animated: true)
        
        
    }
}