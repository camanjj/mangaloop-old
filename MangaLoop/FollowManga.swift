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
    dynamic var id = ""
    dynamic var link = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience required init(unboxer: Unboxer) {
        self.init()
        self.title = unboxer.unbox("title")
        self.link = unboxer.unbox("link")
        self.id = unboxer.unbox("id")
    }
    
    class func getAllFollows() -> [FollowManga]? {
        
        if !MangaManager.isSignedIn() {
            return nil
        }
        
        
        let realm = try! Realm()
        
        let results = realm.objects(FollowManga)
        var manga = [FollowManga]()
        for m in results {
            manga.append(m)
        }
        
        return manga
        
    }
    
}