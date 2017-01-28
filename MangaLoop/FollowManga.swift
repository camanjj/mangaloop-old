//
//  FollowManga.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/3/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

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
    
    convenience required init(unboxer: Unboxer) throws {
        self.init()
        self.title = try unboxer.unbox(key: "title")
        self.link = try unboxer.unbox(key: "link")
        self.id = try unboxer.unbox(key: "id")
    }
    
    
    func toMangaItem() -> MangaPreviewItem {
        let manga = MangaPreviewItem(title: title, link: link, mangaId: id, imageLink: nil, chapters: nil)
        return manga
    }
    
    
    // MARK: Class helper methods
    class func createAndAddFromManga(_ manga: MangaItem) {
    
        let follow = FollowManga()
        follow.title = manga.title
        follow.id = manga.mangaId
        follow.link = manga.link
        
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(follow)
        }
    
    
    }
    
    class func deleteManga(_ manga: MangaItem) {
        
        let realm = try! Realm()
        
        let deleteFollow = realm.objects(FollowManga).filter("id = %@", manga.mangaId)
        
        try! realm.write {
            realm.delete(deleteFollow)
        }
        
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
    
    class func searchFromText(_ text: String) -> Results<FollowManga> {
    
        let realm = try! Realm()
        let searchPredicate = NSPredicate(format: "SELF.title CONTAINS[c] %@", text)
        let results = realm.objects(FollowManga).filter(searchPredicate)
        return results
        
    }
    
}
