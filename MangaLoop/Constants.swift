//
//  Constants.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 2/5/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation

struct Constants {
    
    struct Pantry {
        
        static let Updates = "update-list"
        static let Follows = "follow-list"
        static let FetchFollows = "fetch-follows"
    }

    struct Defaults {
        static let IsSignedIn = "signedIn"
        static let Cookies = "cookies"
        static let Secret = "secret"
        
        static let Languages = "languages"
    }
    
    enum Settings: String {
        case AllowData = "allowData"
        case MatureWarning = "matureWarning"
    }
    
    struct Images {
        static let UpdatesTab = "updates_icon"
        static let Logout = "logout_icon"
        static let FollowsTab = "follows_icon"
        static let SettingsTab = "settings_icon"
    }
    
    static let PageCache = "manga-pages"
    
}