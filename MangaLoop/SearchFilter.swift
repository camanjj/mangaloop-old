//
//  SearchFilter.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/27/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import RealmSwift

class SearchFilter: Object {

    dynamic var includedGenre = ""
    dynamic var excludedGenre = ""
    dynamic var genreIsAnd = true
    dynamic var completion = ""
    dynamic var types = ""
    dynamic var showMature = true
    dynamic var term = ""
    
    func getParamaters() -> [String:AnyObject] {
        
        var params = [String:String]()
        
        var genres = ""
        
        if includedGenre.isEmpty == false {
            genres += includedGenre
        }
        
        if excludedGenre.isEmpty == false {
            genres += excludedGenre
        }
        
        if genres.isEmpty == false {
            params["genre"] = genres
        }
        
        params["genre_cond"] = genreIsAnd ? "and" : "or"
        
        
        if !completion.isEmpty {
            params["completed"] = completion
        }
        
        if !types.isEmpty {
            params["type"] = types
        }
        
        if !showMature {
            params["mature"] = "n"
        }
        
        params["name"] = term
        
        return params
        
    }
    
    func getParamatersString() -> String {
        
        let params = getParamaters()
        
        
        var paramsString = "?"
        
        for (key, value) in params {
            paramsString += "\(key)=\(value)&"
        }
        
        
        return paramsString
        
        
    }

    
}