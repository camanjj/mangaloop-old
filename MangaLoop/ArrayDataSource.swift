//
//  ArrayDataSource.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/29/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit


class ArrayDataSource<CellType: UIView, ItemType>: NSObject, UITableViewDataSource, UICollectionViewDataSource {
    var items: [ItemType]
    var cellReuseIdentifier: String
    var configureClosure: (CellType, ItemType) -> Void
    
    init(items: [ItemType], cellReuseIdentifier: String, configureClosure: (CellType, ItemType) -> Void) {
        self.items = items
        self.cellReuseIdentifier = cellReuseIdentifier
        self.configureClosure = configureClosure
        
        super.init()
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> ItemType {
        return self.items[indexPath.row] as ItemType
    }
    
    func configureCell(cell: CellType, atIndexPath indexPath:NSIndexPath) {
        let item = itemAtIndexPath(indexPath)
        self.configureClosure(cell, item)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if items.count <= 0 {
            return 0
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! CellType
        configureCell(cell, atIndexPath: indexPath)
        
        return cell as! UITableViewCell
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if items.count <= 0 {
            return 0
        }
        
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! CellType
        configureCell(cell, atIndexPath: indexPath)
        
        return cell as! UICollectionViewCell
    }
}