//
//  UIViewLoading.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/31/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    // note that this method returns an instance of type `Self`, rather than UIView
    static func loadFromNib() -> Self {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiateWithOwner(self, options: nil).first as! Self
    }
    
}