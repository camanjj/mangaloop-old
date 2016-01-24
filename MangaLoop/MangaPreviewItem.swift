//
//  MangaPreviewItem.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/23/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Unbox

struct MangaPreviewItem {
    var title: String
    var link: String
    var mangaId: String
    var imageLink: String?
    var chapters: [Chapter]?
    
}


extension MangaPreviewItem: Unboxable {
    init(unboxer: Unboxer) {
        self.title = unboxer.unbox("title")
        self.link = unboxer.unbox("link")
        self.mangaId = unboxer.unbox("mangaId")
        self.chapters = unboxer.unbox("chapters")
    }
}