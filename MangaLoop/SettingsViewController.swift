//
//  SettingsViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/10/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Eureka
import Kingfisher

class SettingsViewController: FormViewController {
    
    let allLanguages = ["English", "Spanish", "French", "German", "Portuguese", "Turkish", "Indonesian", "Greek", "Filipino", "Italian", "Polish", "Thai", "Malay", "Hungarian", "Romanian", "Arabic", "Hebrew", "Russian", "Vietnamese", "Dutch"];

    var memoryCell: ButtonRow?
    var memory: Int = 0 {
        didSet {
          if let memoryCell = memoryCell {
            memoryCell.title = "Clear Image Cache (\(memory)mb)"
            memoryCell.updateCell()
          }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        form +++ Section("Global Settings")
            <<< MultipleSelectorRow<String>() {
                $0.title = "Language"
                $0.options = self.allLanguages
                $0.value = Set(MangaManager.languages())
            }
            .onChange { row in
                if let langs = row.value {
                    MangaManager.setLanguages(Array(langs))
                }
            }
        
            <<< CheckRow() {
                $0.title = "Show Mature Warning"
                $0.value = MangaManager.getToggleSettings(.MatureWarning)
            }
            .onChange { row in
                
                guard let value = row.value else { return }
                
                MangaManager.setToggleSettings(.MatureWarning, value: value)
            }
            
//            <<< CheckRow() {
//                $0.title = "Send Anyonmous Data"
//                $0.value = MangaManager.getToggleSettings(.AllowData)
//            }
//            .onChange { row in
//                guard let value = row.value else { return }
//                MangaManager.setToggleSettings(.AllowData, value: value)
//            }
        
        
        
        let readerSettingsCell = LabelRow() {
            $0.title = "Reader Settings"
        }.onCellSelection { (cell, row) -> () in
            let readerSettingsController = ReaderSettingsViewController()
            self.navigationController?.pushViewController(readerSettingsController, animated: true)
        }
        
        form +++ Section() <<< readerSettingsCell
        
        
        memoryCell = ButtonRow() {
            $0.title = "Clear Image Cache"
        }.onCellSelection({ (cell, row) -> () in
            let pageCache = ImageCache(name: Constants.PageCache)
            pageCache.clearDiskCache {
                self.memory = 0
            }
        }).cellUpdate({ (cell, row) -> () in
            row.title = "Clear Image Cache (\(self.memory)mb)"
        })
        
        
        
        form +++ Section("") <<< memoryCell!
        
        // fetch the memory
        let pageCache = ImageCache(name: Constants.PageCache)
        pageCache.calculateDiskCacheSize { (size) -> () in
            self.memory = Int(size) / 1000000
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let pageCache = ImageCache(name: Constants.PageCache)
        pageCache.calculateDiskCacheSize { (size) -> () in
            self.memory = Int(size) / 1000000
        }
    }


}
