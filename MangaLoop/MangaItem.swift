//
//  MangaItem.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/28/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation

protocol MangaItem {
    var title: String { get }
    var link: String  { get }
    var chapters: [Chapter]? { get }
}