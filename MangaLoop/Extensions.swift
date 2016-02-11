//
//  Extensions.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/10/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    
    func registerCellClass<T: UITableViewCell where T: ReusableView>(cell: T) {
        registerClass(T.self, forCellReuseIdentifier: T.defaultReusableId)
    }
    
}