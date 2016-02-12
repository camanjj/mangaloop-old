//
//  SettingsViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/10/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {
    
    let allLanguages = ["English", "Spanish", "French", "German", "Portuguese", "Turkish", "Indonesian", "Greek", "Filipino", "Italian", "Polish", "Thai", "Malay", "Hungarian", "Romanian", "Arabic", "Hebrew", "Russian", "Vietnamese", "Dutch"];

    override func viewDidLoad() {
        super.viewDidLoad()

        form +++ Section("Global Settings")
            <<< MultipleSelectorRow<String>() {
                $0.title = "Language"
                $0.options = self.allLanguages
                $0.value = Set(MangaManager.languages())
        }.onChange { row in
            if let langs = row.value {
                MangaManager.setLanguages(Array(langs))
            }
        }
        
            <<< CheckRow() {
                $0.title = "Disable Mature Warning"
        }
        
            <<< CheckRow() {
                $0.title = "Send Anyonmous Data"
        }
    }


}
