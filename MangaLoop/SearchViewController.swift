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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */


}

extension SearchViewController: UISearchBarDelegate {
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        
        let filterController = SearchFilterViewController()
        navigationController?.pushViewController(filterController, animated: true)
        
        
    }
}