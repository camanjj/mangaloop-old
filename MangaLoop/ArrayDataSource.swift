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
    
    init(items: [ItemType], cellReuseIdentifier: String, configureClosure: @escaping (CellType, ItemType) -> Void) {
        self.items = items
        self.cellReuseIdentifier = cellReuseIdentifier
        self.configureClosure = configureClosure
        
        super.init()
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> ItemType {
        return self.items[indexPath.row] as ItemType
    }
    
    func configureCell(_ cell: CellType, atIndexPath indexPath:IndexPath) {
        let item = itemAtIndexPath(indexPath)
        self.configureClosure(cell, item)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if items.count <= 0 {
            return 0
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as! CellType
        configureCell(cell, atIndexPath: indexPath)
        
        return cell as! UITableViewCell
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if items.count <= 0 {
            return 0
        }
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CellType
        configureCell(cell, atIndexPath: indexPath)
        
        return cell as! UICollectionViewCell
    }
}
