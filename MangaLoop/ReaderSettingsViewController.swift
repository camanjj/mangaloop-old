//
//  ReaderSettingsViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/18/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Eureka

protocol ReaderSettingsDelegate {
    
    func updatedSettings()
    
}

class ReaderSettingsViewController: FormViewController {
    
    var delegate: ReaderSettingsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        
        let transitionRow = SegmentedRow<String>() {
            $0.options = ["Curl", "Scroll"]
            $0.value = MangaManager.getReaderSettings(.Transition).rawValue
        }.onChange { (row) -> () in
            MangaManager.setReaderSettings(.Transition, value: ReaderOptions(rawValue: row.value!)!)
            
            if let delegate = self.delegate {
                delegate.updatedSettings()
            }
        }
        
        let directionRow = SegmentedRow<String>("Direction") {
            $0.options = ["<--", "-->", "↓"]
            $0.value = MangaManager.getReaderSettings(.Direction).rawValue
        }.onChange { (row) -> () in
            
            MangaManager.setReaderSettings(.Direction, value: ReaderOptions(rawValue: row.value!)!)
            
            if let delegate = self.delegate {
                delegate.updatedSettings()
            }
        }

        
        form +++ Section("Reading Type") <<< transitionRow
        

        
        form +++ Section("Reading Direction") <<< directionRow
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
