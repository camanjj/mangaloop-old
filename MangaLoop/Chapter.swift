//
//  Chapter.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/23/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Unbox
import Pantry

struct Chapter {
    var title: String
    var link: String
    var language: String
    var group: String
    var updateTime: String
}


extension Chapter: Unboxable {
    init(unboxer: Unboxer) {
        self.title = unboxer.unbox("title")
        self.link = unboxer.unbox("link")
        self.language = unboxer.unbox("language")
        self.group = unboxer.unbox("group")
        self.updateTime = unboxer.unbox("updateTime")
    }
}

extension Chapter: Storable {
    
    init(warehouse: Warehouseable) {
        self.title = warehouse.get("title") ?? ""
        self.link = warehouse.get("link") ?? ""
        self.language = warehouse.get("language") ?? ""
        self.group = warehouse.get("group") ?? ""
        self.updateTime = warehouse.get("updateTime") ?? ""
//        self.mangaId = warehouse.get("mangaId") ?? ""
        //        self.age = warehouse.get("age") ?? 20.5
        //        self.number = warehouse.get("number") ?? 10
    }
    
}
