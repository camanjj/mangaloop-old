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
    init(unboxer: Unboxer) throws {
        self.title = try unboxer.unbox(key:"title")
        self.link = try unboxer.unbox(key:"link")
        self.mangaId = try unboxer.unbox(key:"mangaId")
        self.chapters = unboxer.unbox(key:"chapters")
        self.image = unboxer.unbox(key:"image")
        
        self.mature = unboxer.unbox(key:"mature")
        self.status = try unboxer.unbox(key:"status")
        self.genre = try unboxer.unbox(key:"genre")
        self.summary = try unboxer.unbox(key:"summary")
        self.altNames = unboxer.unbox(key:"altNames")
        self.artist = try unboxer.unbox(key:"artist")
        self.author = try unboxer.unbox(key:"author")
        
        self.following = unboxer.unbox(key:"following")
        self.followers = unboxer.unbox(key:"followers")
    }
}
