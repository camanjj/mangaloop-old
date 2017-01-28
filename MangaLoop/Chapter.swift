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
    init(unboxer: Unboxer) throws {
        self.title = try unboxer.unbox(key: "title")
        self.link = try unboxer.unbox(key: "link")
        self.language = try unboxer.unbox(key: "language")
        self.group = try unboxer.unbox(key: "group")
        self.updateTime = try unboxer.unbox(key: "updateTime")
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
