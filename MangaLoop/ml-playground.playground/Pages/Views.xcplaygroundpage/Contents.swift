//: [Previous](@previous)

import Foundation
import UIKit
import XCPlayground
import SnapKit


XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: [Next](@next)

class MangaCell: UITableViewCell {
    let titleLabel = UILabel()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        titleLabel.text = "Bleach"
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(8, 10, 8, 10))
        }
        
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.redColor().CGColor
        btn.setTitleColor(UIColor.redColor(), forState: .Normal)
        btn.setTitle("5", forState: .Normal)
        
        self.accessoryView = btn
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


let containerView = UITableView(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0), style: UITableViewStyle.Grouped)
XCPlaygroundPage.currentPage.liveView = containerView


class PlayTableViewController : UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(MangaCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! MangaCell
        
        cell.titleLabel.text = "Maecenas faucibus mollis interdum."
        
        
        return cell
    }
    
}

let tableViewController = PlayTableViewController(style: UITableViewStyle.Plain)
tableViewController.tableView.frame = CGRect(x: 0, y: 0, width: 300, height: 500)

containerView.addSubview(tableViewController.view)

