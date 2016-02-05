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
                                                userDefaults.setObject(info, forKey: "cookies")
                                                userDefaults.setObject(secret, forKey: "secret")
                                                userDefaults.setBool(true, forKey: "signedIn")
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
        return NSUserDefaults.standardUserDefaults().boolForKey("signedIn")
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
    
    func getAllFollows(callback: [FollowManga]? -> Void) {
        Alamofire.request(MLRouter.Get("all/follows", nil))
            .responseData { (response) -> Void in
                if let data = response.result.value {
                    let mangas: [FollowManga]? = Unbox(data)
                    callback(mangas)
                }
                
                callback(nil)
        }
    }
}