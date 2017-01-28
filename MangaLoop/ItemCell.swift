//
//  ChapterCell.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ItemCell: UITableViewCell {
    let headerLabel = UILabel()
    let subHeaderLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        headerLabel.numberOfLines = 0
        subHeaderLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(headerLabel)
        contentView.addSubview(subHeaderLabel)
        
        
        
        headerLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
        }
        
        subHeaderLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(headerLabel.snp_bottom).offset(5)
            make.bottom.equalTo(-10)
            make.left.right.equalTo(10)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ chapter: Chapter) {
        
        headerLabel.text = chapter.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        subHeaderLabel.text = chapter.updateTime
        
    }
    
    func configure(_ header: String, subHeader: String? = nil) {
        headerLabel.text = header
        
        if let subHeader = subHeader {
            subHeaderLabel.text = subHeader
        }
    }
}


