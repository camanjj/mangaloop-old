//
//  MangaCell.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class MangaCell: UITableViewCell {
    let titleLabel = UILabel()
    var chaptersButton: UIButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        titleLabel.text = "Bleach"
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(12, 10, 12, 10))
        }
        
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.redColor().CGColor
        btn.setTitleColor(UIColor.redColor(), forState: .Normal)
//        btn.setTitle("5", forState: .Normal)
        
        self.accessoryView = btn
        chaptersButton = btn
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(manga: MangaPreviewItem, isFollowing: Bool = false) {
        
        titleLabel.text = manga.title
        
        if let chapters = manga.chapters {
            accessoryView = chaptersButton
            chaptersButton.setTitle("\(chapters.count)", forState: .Normal)
        } else {
            accessoryView = nil
        }
        
        if isFollowing == true {
            chaptersButton.backgroundColor = UIColor.redColor()
            chaptersButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        } else {
            chaptersButton.backgroundColor = UIColor.clearColor()
            chaptersButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        }
        
    }
}
