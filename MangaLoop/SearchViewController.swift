//
//  SearchViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 3/6/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import MZFormSheetPresentationController

class SearchViewController: UITableViewController {
    
    var dataSource: ArrayDataSource<MangaCell, MangaPreviewItem>?
    var filter: SearchFilter?
    var searchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(MangaCell.self, forCellReuseIdentifier: MangaCell.defaultReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 60))
        
        let filterButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 120, height: 45)))
        filterButton.setTitle("Filter", forState: .Normal)
        filterButton.layer.cornerRadius = 5
        filterButton.backgroundColor = UIColor.redColor()
        filterButton.addTarget(self, action: Selector("filterClick"), forControlEvents: .TouchUpInside)
        
        headerView.addSubview(filterButton)
        filterButton.center = headerView.center
        
        tableView.tableHeaderView = headerView

        
    }
    
    func filterClick() {
        
        let filterController = SearchFilterViewController(filter: filter)
        filterController.delegate = self
        let navController = UINavigationController()
        navController.viewControllers = [filterController]
        let formSheet = MZFormSheetPresentationViewController(contentViewController: navController)
        
//        formSheet.interactivePanGestureDissmisalDirection = .All;
//        formSheet.presentationController?.shouldDismissOnBackgroundViewTap = true
        formSheet.contentViewControllerTransitionStyle = .Fade
        formSheet.presentationController?.contentViewSize = CGSize(width: UIScreen.mainScreen().bounds.width - 20, height: 350)

        self.presentViewController(formSheet, animated: true, completion: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getResults() {
        
        if let filter = filter {
            
            filter.term = searchText
            
        } else {
            
            // there is no filter, create a filter and add the term
            filter = SearchFilter()
            filter!.term = searchText
            
        }
        
        
        MangaManager.sharedManager.searchMangas(filter!, callback: { [weak self] (manga) -> Void in
            
            if let manga = manga, wself = self {
                
                wself.setDataSource(manga)
                
            }
            
            
        })
        
    }
    
    func setDataSource(manga: [MangaPreviewItem]) {
        self.dataSource = ArrayDataSource<MangaCell, MangaPreviewItem>(items: manga, cellReuseIdentifier: MangaCell.defaultReusableId, configureClosure: { (cell, item) -> Void in
            
            cell.configure(item)
            
        })
        
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let manga = dataSource?.itemAtIndexPath(indexPath)
        
        let detailsController = MangaDetailsController(manga: manga!)
        self.presentingViewController!.navigationController?.pushViewController(detailsController, animated: true)
        
    }

}

extension SearchViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        searchController.searchResultsController!.view.hidden = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //this is when the searching should happen
        getResults()
    }
    
}

extension SearchViewController: SearchFilterViewDelegate {
    
    func didCancel(viewController: SearchFilterViewController) {
        viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func didApplyFilter(viewController: SearchFilterViewController, filter: SearchFilter) {
        viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)

        self.filter = filter
        self.getResults()
    }

    
}
