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

class MangaManager {
    
    
    static let sharedManager = MangaManager()
    
    func getUpdates(callback: MangaList) {
        Alamofire.request(MLRouter.Get("updates", nil))
            .responseData({ (response) -> Void in
                if let data = response.result.value {
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                }
                
                callback(nil)
            })

    }
    
    
    func getMangaDetails(page: String, callback: MangaDetailItem? -> Void) {
        Alamofire.request(MLRouter.Get("info", ["page": page]))
            .responseData { (response) -> Void in
                if let data = response.result.value {
                    let manga: MangaDetailItem? = Unbox(data)
                    callback(manga)
                }
                callback(nil)
        }
    }
    
    func searchMangas(term: String, callback: MangaList) {
        Alamofire.request(MLRouter.Get("search", ["term": "bleach"]))
            .responseData { (response) -> Void in
                if let data = response.result.value {
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                }
                callback(nil)
        }
    }
    
    func getPages(link: String, callback: [String]? -> Void) {
        Alamofire.request(MLRouter.Get("pages", ["page": link]))
            .responseJSON { (response) -> Void in
                if let json = response.result.value, pages = json as? [String] {
                    callback(pages)
                }
                callback(nil)
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
    
    static func isSignedIn() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.Defaults.IsSignedIn)
    }
    
    //MARK: Follows
    func getFollowsList(page: Int = 1, callback: MangaList) {
        Alamofire.request(MLRouter.Get("follows", nil))
            .responseData { (response) -> Void in
                if let data = response.result.value {
                    let mangas: [MangaPreviewItem]? = Unbox(data)
                    callback(mangas)
                }
                
                callback(nil)
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
            .responseJSON(completionHandler: { (response) -> Void in
                print(response)
            })
            .responseData { (response) -> Void in
                if let data = response.result.value {
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
                }
                
                callback?(fetched: false, error: true)
        }
    }
}