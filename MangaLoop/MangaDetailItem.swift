//
//  MangaDetailItem.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/23/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Unbox

struct MangaDetailItem: MangaItem {
    var title: String
    var link: String
    var mangaId: String
    var image: String?
    var chapters: [Chapter]?
    
    var artist: String
    var author: String
    var genre: [String]
    var mature: String?
    var altNames: String?
    var status: String
    var summary: String
    
    var following: Bool?
    var followers: String?
    
}


extension MangaDetailItem: Unboxable {
    init(unboxer: Unboxer) {
        self.title = unboxer.unbox("title")
        self.link = unboxer.unbox("link")
        self.mangaId = unboxer.unbox("mangaId")
        self.chapters = unboxer.unbox("chapters")
        self.image = unboxer.unbox("image")
        
        self.mature = unboxer.unbox("mature")
        self.status = unboxer.unbox("status")
        self.genre = unboxer.unbox("genre")
        self.summary = unboxer.unbox("summary")
        self.altNames = unboxer.unbox("altNames")
        self.artist = unboxer.unbox("artist")
        self.author = unboxer.unbox("author")
        
        self.following = unboxer.unbox("following")
        self.followers = unboxer.unbox("followers")
    }
}