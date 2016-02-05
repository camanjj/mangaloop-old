//
//  FollowManga.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/3/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import Unbox

class FollowManga : Object, Unboxable {
    dynamic var title = ""
    dynamic var mangaId = ""
    dynamic var link = ""
    
    override static func primaryKey() -> String? {
        return "mangaId"
    }
    
    convenience required init(unboxer: Unboxer) {
        self.init()
        self.title = unboxer.unbox("title")
        self.link = unboxer.unbox("link")
        self.mangaId = unboxer.unbox("mangaId")
    }
    
}