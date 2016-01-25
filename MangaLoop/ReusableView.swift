//
//  ReusableView.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit

protocol ReusableView: class {
    static var defaultReusableId: String { get }
}

extension ReusableView where Self: UIView {
    static var defaultReusableId: String {
        return String(self)
    }
}

extension UITableViewCell: ReusableView {
    
}