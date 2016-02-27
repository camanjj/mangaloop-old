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
    
    struct ReaderSettings {
        enum Options: String {
            case RightToLeft = "<--"
            case LeftToRight = "-->"
            case Webtoon = "↓"
            case Curl = "Curl"
            case Scroll = "Scroll"
        }
        
        enum Setting: String {
            case Direction = "direction"
            case Transition = "transition"
        }

    }
    
    struct Images {
        static let UpdatesTab = "updates_icon"
        static let Logout = "logout_icon"
        static let FollowsTab = "follows_icon"
        static let SettingsTab = "settings_icon"
        
        static let ReaderSettings = "ios-toggle"
        static let Search = "search"
        static let Info = "info"
        static let List = "ios-list"
    }
    
    static let PageCache = "manga-pages"
    
}

typealias ReaderOptions = Constants.ReaderSettings.Options
typealias ReaderSetting = Constants.ReaderSettings.Setting