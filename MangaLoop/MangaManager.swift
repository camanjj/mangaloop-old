//
//  MangaManager.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Alamofire
import Unbox
import Kanna
import Pantry
import RealmSwift


typealias MangaList = [MangaPreviewItem]? -> Void
typealias SuccessCallback = Bool -> Void

enum FollowAction: String {
    case Follow = "follow"
    case UnFollow = "unfollow"
}

class MangaManager {
    
    static let sharedManager = MangaManager()
    
    func getUpdates(page: Int, callback: MangaList) {
        Alamofire.request(MLRouter.Get("updates", ["page": page]))
            .validate()
            .responseData({ (response) -> Void in
                
                switch response.result {
                case .Success(let data):
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                case .Failure(_):
                    callback(nil)
                }
                
            })

    }
    
    
    func getMangaDetails(page: String, callback: MangaDetailItem? -> Void) {
        Alamofire.request(MLRouter.Get("info", ["page": page]))
            .validate()
            .responseData { (response) -> Void in
                switch response.result {
                case .Success(let data):
                    let manga: MangaDetailItem? = Unbox(data)
                    callback(manga)
                case .Failure(_):
                    callback(nil)
                }
        }
    }
    
    func searchMangas(filter: SearchFilter, callback: MangaList) {
        Alamofire.request(MLRouter.Get("search", filter.getParamaters()))
            .validate()
            .responseData { (response) -> Void in
                switch response.result {
                case .Success(let data):
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                case .Failure(_):
                    callback(nil)
                }
        }
    }
    
    func getPopularManga(callback: MangaList) {
        Alamofire.request(MLRouter.Get("popular", nil))
            .validate()
            .responseJSON(completionHandler: { (response) -> Void in
                print(response.result.value)
            })
            .responseData { (response) -> Void in
                switch response.result {
                case .Success(let data):
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                case .Failure(_):
                    callback(nil)
                }
        }
    }
    
    func getPages(link: String, callback: [String]? -> Void) {
        Alamofire.request(MLRouter.Get("pages", ["page": link]))
            .validate()
            .responseJSON { (response) -> Void in
                
                switch response.result {
                case .Success(let json):
                    let pages = json as? [String]
                    callback(pages)
                case .Failure(_):
                    callback(nil)
                    
                }
        }
    }
    
    //MARK: User methods
    func login(username: String, password: String, callback: Bool -> Void) {
        
        
        let loginParams: [String:AnyObject] = [
            "auth_key": "880ea6a14ea49e853634fbdc5015a024",
            "referer": "http://bato.to/",
            "ips_username": username,
            "ips_password": password,
            "rememberMe": true
        ]

        
        Alamofire.request(.POST, "https://bato.to/forums/index.php?app=core&module=global&section=login&do=process", parameters: loginParams, encoding: .URL)
            
            .responseString { (response) -> Void in
                
                if let
                    headerFields = response.response?.allHeaderFields as? [String: String],
                    URL = response.request?.URL
                {
                    let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headerFields, forURL: URL)
                    
                    if cookies.contains({$0.name == "pass_hash"}) {
                        print("User Logged in")
                        
                        // store the cookies in a dictionary
                        var info: [String: AnyObject] = [:]
                        for cookie in cookies {
                            info[cookie.name] = cookie.value
                        }
                        
                        
                        Alamofire.request(.GET, "https://bato.to/")
                            .responseData({ (response) -> Void in
                                print(response.response)
                                if let data = response.result.value,
                                    html = NSString(data: data, encoding: NSASCIIStringEncoding),
                                    doc = Kanna.HTML(html: html as String, encoding: NSUTF8StringEncoding) {
                                        
                                        // get the secret key from the htnl
                                        if let statusNode = doc.css("#statusForm").first,
                                            href = statusNode["action"],
                                            components = NSURLComponents(string: href),
                                            queryParams = components.queryItems,
                                            secret = queryParams.filter({$0.name == "k"}).first?.value {
                                                
                                                let userDefaults = NSUserDefaults.standardUserDefaults()
                                                userDefaults.setObject(info, forKey: Constants.Defaults.Cookies)
                                                userDefaults.setObject(secret, forKey: Constants.Defaults.Secret)
                                                userDefaults.setBool(true, forKey: Constants.Defaults.IsSignedIn)
                                                userDefaults.synchronize()
                                                callback(true)
                                        }
                                        
                                        
                                } else {
                                    callback(false)
                                }
                                
                            })
                        
                    } else {
                        callback(false)
                    }
                }
        }

    }
    
    func logout() {
        
        // remove the
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(Constants.Defaults.Cookies)
        userDefaults.removeObjectForKey(Constants.Defaults.IsSignedIn)
        userDefaults.removeObjectForKey(Constants.Defaults.Secret)
        userDefaults.synchronize()
        
        
        // remnove all of the follow manga from the db
        let realm = try! Realm()
        let allFollows = realm.objects(FollowManga)
        
        try! realm.write {
            realm.delete(allFollows)
        }
        
    }
    
    //MARK: Helper class functions
    static func isSignedIn() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.Defaults.IsSignedIn)
    }
    
    static func languages() -> [String] {
        if let languages = NSUserDefaults.standardUserDefaults().stringArrayForKey(Constants.Defaults.Languages) {
            return languages
        } else {
            return ["English"]
        }
    }
    
    static func setLanguages(languages: [String]) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(languages, forKey: Constants.Defaults.Languages)
        defaults.synchronize()
    }
    
    static func setToggleSettings(setting: Constants.Settings, value: Bool) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(value, forKey: setting.rawValue)
        defaults.synchronize()
    }
    
    static func getToggleSettings(setting: Constants.Settings) -> Bool {
        if let value = NSUserDefaults.standardUserDefaults().objectForKey(setting.rawValue) {
            return value as! Bool
        } else {
            return true
        }
    }
    
    static func getReaderSettings(setting: ReaderSetting) -> ReaderOptions {
        
        if let value = NSUserDefaults.standardUserDefaults().stringForKey(setting.rawValue) {
            return Constants.ReaderSettings.Options(rawValue: value)!
        } else {
            
            // Decide on the default value
            return setting == .Direction ? .LeftToRight : .Curl
        }
        
    }
    
    static func setReaderSettings(setting: ReaderSetting, value: ReaderOptions) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(value.rawValue, forKey: setting.rawValue)
        defaults.synchronize()
    }
    
    //MARK: Follows
    func getFollowsList(page: Int = 1, callback: MangaList) {
        Alamofire.request(MLRouter.Get("follows", ["page": page]))
            .validate()
            .responseData { (response) -> Void in
                switch response.result {
                case .Success(let data):
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                case .Failure(_):
                    callback(nil)
                }
        }
    }
    
    func getAllFollowsIfNeeded(callback: ((fetched: Bool, error: Bool) -> Void)?) {
        
        
        if !MangaManager.isSignedIn() {
            print("User not signed in")
            callback?(fetched: false, error: false)
            return
        }
        
        // no reason to query from the server again
        if let shouldFetch: Bool = Pantry.unpack(Constants.Pantry.FetchFollows) where shouldFetch == false {
            print("No need to fetch manga")
            callback?(fetched: false, error: false)
            return
        }
        
        Alamofire.request(MLRouter.Get("all/follows", nil))
            .validate()
            .responseData { (response) -> Void in
                
                switch response.result {
                case .Success(let data):
                    guard let manga: [FollowManga] = Unbox(data) else {
                        callback?(fetched: true, error: true)
                        return
                    }
                    
                    print("Saving followed manga")
                    
                    //save the database
                    let realm = try! Realm()
                    
                    let ids = manga.map({$0.id})
                    //find manga that are not followed anymore
                    let predicate = NSPredicate(format: "NOT(id IN %@)", ids)
                    let unFollowedManga = realm.objects(FollowManga).filter(predicate)
                    
                    //save and delete unfollowed manga
                    try! realm.write {
                        realm.delete(unFollowedManga)
                        realm.add(manga, update: true)
                    }
                    
                    // pack for 24 hours
                    Pantry.pack(false, key: Constants.Pantry.FetchFollows, expires: .Seconds(60 * 60 * 24))
                    
                    
                    callback?(fetched: true, error: false)
                case .Failure(_):
                    callback?(fetched: false, error: true)
                }                
        }
    }

    func followManga(manga: MangaItem, action: FollowAction, callback: SuccessCallback) {
        
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let secret = userDefaults.stringForKey(Constants.Defaults.Secret)!
        let allCookies = userDefaults.dictionaryForKey(Constants.Defaults.Cookies)!
        let session = allCookies["session_id"]
        
        let params: [String: AnyObject] = ["sKey": secret, "session": session!, "action": action.rawValue, "rid": manga.mangaId]
        
        Alamofire.request(MLRouter.Post("follow", params))
            .validate()
            .responseJSON { (response) -> Void in
                switch response.result {
                case .Success(_):
                    
                    if action == .Follow {
                        // add the manga to the follow list
                        FollowManga.createAndAddFromManga(manga)
                        
                    } else {
                        // remove the follow from the db
                        FollowManga.deleteManga(manga)
                        
                    }
                    
                    callback(true)
                case .Failure(let error):
                    print(error.localizedDescription)
                    callback(false)
                }
        }
        
        
        
    }

}