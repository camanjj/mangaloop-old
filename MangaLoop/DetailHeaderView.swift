//
//  DetailHeaderView.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/31/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit

protocol DetailHeaderDelegate {
    func followClick()
}

class DetailHeaderView: UIView {
    

    @IBOutlet weak var mangaImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followButton: TKTransitionSubmitButton!
    
    var delegate: DetailHeaderDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        followButton.layer.cornerRadius = 5
//        followButton.layer.borderWidth = 1
//        followButton.layer.borderColor = followButton.tintColor.CGColor
    }
    
    @IBAction func followClick(_ sender: AnyObject) {
        if let delegate = delegate {
            followButton.startLoadingAnimation()
            delegate.followClick()
        }
        
    }
}
