//
//  DiscoverCell.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 3/6/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Kingfisher

class DiscoverCell: UICollectionViewCell {
    
    @IBOutlet weak var mangaImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(title: String, imageLink: String?) {
        titleLabel.text = title
        
        if let imageLink = imageLink {
            mangaImageView.kf_setImageWithURL(NSURL(string: imageLink)!)
        }
        
    }

}
