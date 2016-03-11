//
//  SettingsFilterViewController.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import Eureka

protocol SearchFilterViewDelegate {
    
    func didCancel(viewController: SearchFilterViewController)
    func didApplyFilter(viewController: SearchFilterViewController, filter: SearchFilter?)
    
}

class SearchFilterViewController: FormViewController {
    
    let genres = ["Historical": "20", "Medical": "42", "Shoujo": "35", "Yuri": "31", "Shoujo Ai": "16", "Tragedy": "28", "4-Koma": "40", "Mystery": "4", "Supernatural": "26", "Drama": "10", "Fantasy": "13", "Josei": "34", "Slice of Life": "21", "School Life": "7", "Adventure": "2", "Sci-fi": "8", "Sports": "25", "Martial Arts": "27", "Romance": "6", "Seinen": "32", "[no chapters]": "44", "Shounen": "33", "Comedy": "3", "Oneshot": "38", "Cooking": "41", "Horror": "22", "Mecha": "30", "Action": "1", "Webtoon": "36", "Yaoi": "29", "Smut": "23", "Ecchi": "12", "Doujinshi": "9", "Music": "37", "Gender Bender": "15", "Harem": "17", "Shounen Ai": "19", "Psychological": "5", "Award Winning": "39"]
    
    let types = ["Any": "0", "Manga (Jp)": "jp", "Manhwa (Kr)": "kr", "Manhua (Cn)": "cn", "Artbook": "ar", "Other": "ot"]
    
    var filter: SearchFilter?
    var delegate: SearchFilterViewDelegate?
    
    init(filter: SearchFilter?) {
        super.init(nibName: nil, bundle: nil)
        self.filter = filter
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: Selector("closeClick"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .Plain, target: self, action: Selector("applyClick"))
        title = "Filter"
        
        if filter == nil {
            filter = SearchFilter()
        }
        
        let includeGenreCell = MultipleSelectorRow<String>() {
            $0.title = "Include Genres"
            $0.options = Array(genres.keys)
        }.onChange {
            let values = $0.value
            let genres = Array(values!).map({ self.genres[$0]! })
            self.filter!.includedGenre = ";i" + genres.joinWithSeparator(";i")
        }
        
        let exludeGenreCell = MultipleSelectorRow<String>() {
            $0.title = "Exclude Genres"
            $0.options = Array(genres.keys)
        }.onChange {
            let values = $0.value
            let genres = Array(values!).map({ self.genres[$0]! })
            self.filter!.excludedGenre = ";e" + genres.joinWithSeparator(";e")
        }
        
        let inclusionCell = SegmentedRow<String>() {
            $0.title = "Genre Inclusion"
            $0.options = ["And", "Or"]
            $0.value = "And"
        }.onChange {
            self.filter!.genreIsAnd = $0.value == "And"
        }
        
        form +++ Section("Genres") <<< includeGenreCell <<< exludeGenreCell <<< inclusionCell
        
        
        let completionCell = SegmentedRow<String>() {
            $0.title = "Status"
            $0.options = ["Any", "Complete", "Incomplete"] // should map to c=complete, i=incomplete
            $0.value = "Any"
        }.onChange {
            
            if $0.value == "Any" {
                self.filter!.completion = ""
            } else {
                self.filter!.completion = $0.value == "Complete" ? "c" : "i"
            }
            
        }
        
        let matureCell = CheckRow() {
            $0.title = "Show mature"
            $0.value = true
        }.onChange {
            self.filter!.showMature = $0.value!
            print(self.filter!.getParamaters())
        }
        
        let typesCell = AlertRow<String>() {
            $0.title = "Type"
            $0.options = Array(types.keys)
            $0.value = "Any"
        }.onChange {
            
            let value = $0.value
            
            if value == "Any" {
                self.filter!.types = ""
            } else {
                self.filter!.types = self.types[value!]!
            }
            
        }
        
        form +++ Section("Information") <<< completionCell <<< matureCell <<< typesCell
        
        
        let resetCell = ButtonRow() {
            $0.title = "Reset Filter"
        }.onCellSelection { (cell, row) -> () in
            self.filter = SearchFilter()
            self.tableView?.reloadData()
        }
        
        let removeCell = ButtonRow() {
            $0.title = "Remove Filter"
        }.onCellSelection { (cell, row) -> () in
            self.delegate?.didApplyFilter(self, filter: nil)
        }
        
        form +++ Section() <<< resetCell <<< removeCell

    }
    
    func closeClick() {
        delegate?.didCancel(self)
    }
    
    func applyClick() {
        delegate?.didApplyFilter(self, filter: filter)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
