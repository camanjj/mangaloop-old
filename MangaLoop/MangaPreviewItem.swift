//
//  MangaPreviewItem.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/23/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Unbox
import Pantry
import RealmSwift

struct MangaPreviewItem: MangaItem {
    var title: String
    var link: String
    var mangaId: String
    var imageLink: String?
    var chapters: [Chapter]?
    
    
    
    func isFollowing() -> Bool {
        
        if UserDefaults.standard.bool(forKey: Constants.Defaults.IsSignedIn) {
            
            let realm = try! Realm()
            if let _ = realm.objects(FollowManga).filter("id = %@", mangaId).first {
                return true
            } else {
                return false
            }
            
            
        } else {
            return false
        }
        
    }
    
}


extension MangaPreviewItem: Unboxable {
    init(unboxer: Unboxer) throws{
        self.title = try unboxer.unbox(key: "title")
        self.link = try unboxer.unbox(key: "link")
        self.mangaId = try unboxer.unbox(key: "mangaId")
        self.chapters = try unboxer.unbox(key: "chapters")
        self.imageLink = try unboxer.unbox(key: "imageLink")
    }
}

extension MangaPreviewItem: Storable {
    
    init(warehouse: Warehouseable) {
        self.title = warehouse.get("title") ?? ""
        self.link = warehouse.get("link") ?? ""
        self.mangaId = warehouse.get("mangaId") ?? ""
        self.imageLink = warehouse.get("imageLink") ?? ""
        self.chapters = warehouse.get("chapters") ?? [Chapter]()
//        self.age = warehouse.get("age") ?? 20.5
//        self.number = warehouse.get("number") ?? 10
    }
    
}
