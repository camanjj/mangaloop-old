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
import Fuzi
import Pantry
import RealmSwift


typealias MangaList = ([MangaPreviewItem]?) -> Void
typealias SuccessCallback = (Bool) -> Void

enum FollowAction: String {
    case Follow = "follow"
    case UnFollow = "unfollow"
}

class MangaManager {
  
    static let sharedManager = MangaManager()
    
    func getUpdates(_ page: Int, callback: @escaping MangaList) {
        Alamofire.request(MLRouter.get("updates", ["page": page as AnyObject]))
            .validate()
          .responseData( completionHandler: { (response) -> Void in
                
                switch response.result {
                case .success(let data):
                    let mangas: [MangaPreviewItem]? = try? unbox(data: data)
                    callback(mangas)
                case .failure(_):
                    callback(nil)
                }
                
            })

    }
    
    
    func getMangaDetails(_ page: String, callback: @escaping (MangaDetailItem?) -> Void) {
        Alamofire.request(MLRouter.get("info", ["page": page as AnyObject]))
            .validate()
          .responseJSON(completionHandler: { (response) in
            print(response)
          })
            .responseData { (response) -> Void in
                switch response.result {
                case .success(let data):
                    let manga: MangaDetailItem? = try? unbox(data: data)
                    callback(manga)
                case .failure(_):
                    callback(nil)
                }
        }
    }
    
    func searchMangas(_ filter: SearchFilter, callback: @escaping MangaList) {
        Alamofire.request(MLRouter.get("search", filter.getParamaters()))
            .validate()
            .responseData { (response) -> Void in
                switch response.result {
                case .success(let data):
                    let mangas: [MangaPreviewItem]? = try? unbox(data: data)
                    callback(mangas)
                case .failure(_):
                    callback(nil)
                }
        }
    }
    
    func getPopularManga(_ callback: @escaping MangaList) {
        Alamofire.request(MLRouter.get("popular", nil))
            .validate()
            .responseJSON(completionHandler: { (response) -> Void in
                print(response.result.value)
            })
            .responseData { (response) -> Void in
                switch response.result {
                case .success(let data):
                    let mangas: [MangaPreviewItem]? = try? unbox(data: data)
                    callback(mangas)
                case .failure(_):
                    callback(nil)
                }
        }
    }
    
    func getPages(_ link: String, callback: @escaping ([String]?) -> Void) {
        Alamofire.request(MLRouter.get("pages", ["page": link as AnyObject]))
            .validate()
            .responseJSON { (response) -> Void in
                
                switch response.result {
                case .success(let json):
                    let pages = json as? [String]
                    callback(pages)
                case .failure(_):
                    callback(nil)
                    
                }
        }
    }
    
    //MARK: User methods
    func login(_ username: String, password: String, callback: @escaping (Bool) -> Void) {
        
        
        let loginParams: [String:AnyObject] = [
            "auth_key": "880ea6a14ea49e853634fbdc5015a024" as AnyObject,
            "referer": "http://bato.to/" as AnyObject,
            "ips_username": username as AnyObject,
            "ips_password": password as AnyObject,
            "rememberMe": true as AnyObject
        ]

        Alamofire.request("https://bato.to/forums/index.php?app=core&module=global&section=login&do=process", method: .post, parameters: loginParams, encoding: URLEncoding.default, headers: nil)
            
            .responseString { (response) -> Void in
                
                if let
                    headerFields = response.response?.allHeaderFields as? [String: String],
                    let URL = response.request?.url
                {
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
                    
                    if cookies.contains(where: {$0.name == "pass_hash"}) {
                        print("User Logged in")
                        
                        // store the cookies in a dictionary
                        var info: [String: AnyObject] = [:]
                        for cookie in cookies {
                            info[cookie.name] = cookie.value as AnyObject?
                        }
                        
                        
                        Alamofire.request("https://bato.to/")
                            .responseData(completionHandler: { (response) -> Void in
                                print(response.response)
                                if let data = response.result.value,
                                  let doc = try? HTMLDocument(data: data) {
                                        
                                        // get the secret key from the htnl
                                        if let statusNode = doc.css("#statusForm").first,
                                            let href = statusNode["action"],
                                            let components = NSURLComponents(string: href),
                                            let queryParams = components.queryItems,
                                            let secret = queryParams.filter({$0.name == "k"}).first?.value {
                                                
                                                let userDefaults = UserDefaults.standard
                                                userDefaults.set(info, forKey: Constants.Defaults.Cookies)
                                                userDefaults.set(secret, forKey: Constants.Defaults.Secret)
                                                userDefaults.set(true, forKey: Constants.Defaults.IsSignedIn)
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
  
  func getSecret(_ cookies: [String:String], callback: @escaping SuccessCallback) {
    
    
    Alamofire.request("https://bato.to/")
      .responseData(completionHandler: { (response) -> Void in
        print(response.response)
        if let data = response.result.value,
          let doc = try? HTMLDocument(data: data) {
          
          // get the secret key from the htnl
          if let statusNode = doc.css("#statusForm").first,
            let href = statusNode["action"],
            let components = NSURLComponents(string: href),
            let queryParams = components.queryItems,
            let secret = queryParams.filter({$0.name == "k"}).first?.value {
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(cookies, forKey: Constants.Defaults.Cookies)
            userDefaults.set(secret, forKey: Constants.Defaults.Secret)
            userDefaults.set(true, forKey: Constants.Defaults.IsSignedIn)
            userDefaults.synchronize()
            callback(true)
          }
          
          
        } else {
          callback(false)
        }
        
      })
    
  }
  
    func logout() {
      
        // remove the
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: Constants.Defaults.Cookies)
        userDefaults.removeObject(forKey: Constants.Defaults.IsSignedIn)
        userDefaults.removeObject(forKey: Constants.Defaults.Secret)
        userDefaults.synchronize()
      
      // remove the cookes from the cookie store
      let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "http://bato.to")!)
      let cookieStore = HTTPCookieStorage.shared
      for cookie in cookies! {
        cookieStore.deleteCookie(cookie)
        
      }
      
      
        // remnove all of the follow manga from the db
        let realm = try! Realm()
      let allFollows = realm.objects(FollowManga.self)
      
        try! realm.write {
            realm.delete(allFollows)
        }
      
    }
  
    //MARK: Helper class functions
    static func isSignedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: Constants.Defaults.IsSignedIn)
    }
    
    static func languages() -> [String] {
        if let languages = UserDefaults.standard.stringArray(forKey: Constants.Defaults.Languages) {
            return languages
        } else {
            return ["English"]
        }
    }
    
    static func setLanguages(_ languages: [String]) {
        let defaults = UserDefaults.standard
        defaults.set(languages, forKey: Constants.Defaults.Languages)
        defaults.synchronize()
    }
    
    static func setToggleSettings(_ setting: Constants.Settings, value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: setting.rawValue)
        defaults.synchronize()
    }
    
    static func getToggleSettings(_ setting: Constants.Settings) -> Bool {
        if let value = UserDefaults.standard.object(forKey: setting.rawValue) {
            return value as! Bool
        } else {
            return true
        }
    }
    
    static func getReaderSettings(_ setting: ReaderSetting) -> ReaderOptions {
        
        if let value = UserDefaults.standard.string(forKey: setting.rawValue) {
            return Constants.ReaderSettings.Options(rawValue: value)!
        } else {
            
            // Decide on the default value
            return setting == .Direction ? .LeftToRight : .Curl
        }
        
    }
    
    static func setReaderSettings(_ setting: ReaderSetting, value: ReaderOptions) {
        let defaults = UserDefaults.standard
        defaults.set(value.rawValue, forKey: setting.rawValue)
        defaults.synchronize()
    }
    
    //MARK: Follows
    func getFollowsList(_ page: Int = 1, callback: @escaping MangaList) {
        Alamofire.request(MLRouter.get("follows", ["page": page as AnyObject]))
            .validate()
            .responseData { (response) -> Void in
                switch response.result {
                case .success(let data):
                    let mangas: [MangaPreviewItem]? = try? unbox(data: data)
                    callback(mangas)
                case .failure(_):
                    callback(nil)
                }
        }
    }
    
    func getAllFollowsIfNeeded(_ callback: ((_ fetched: Bool, _ error: Bool) -> Void)?) {
        
        
        if !MangaManager.isSignedIn() {
            print("User not signed in")
            callback?(false, false)
            return
        }
        
        // no reason to query from the server again
        if let shouldFetch: Bool = Pantry.unpack(Constants.Pantry.FetchFollows), shouldFetch == false {
            print("No need to fetch manga")
            callback?(false, false)
            return
        }
        
        Alamofire.request(MLRouter.get("all/follows", nil))
            .validate()
            .responseData { (response) -> Void in
                
                switch response.result {
                case .success(let data):
                    guard let manga: [FollowManga] = try? unbox(data: data) else {
                        callback?(true, true)
                        return
                    }
                    
                    print("Saving followed manga")
                    
                    //save the database
                    let realm = try! Realm()
                    
                    let ids = manga.map({$0.id})
                    //find manga that are not followed anymore
                    let predicate = NSPredicate(format: "NOT(id IN %@)", ids)
                    let unFollowedManga = realm.objects(FollowManga.self).filter(predicate)
                    
                    //save and delete unfollowed manga
                    try! realm.write {
                        realm.delete(unFollowedManga)
                        realm.add(manga, update: true)
                    }
                    
                    // pack for 24 hours
                    Pantry.pack(false, key: Constants.Pantry.FetchFollows, expires: .seconds(60 * 60 * 24))
                    
                    
                    callback?(true, false)
                case .failure(_):
                    callback?(false, true)
                }                
        }
    }

    func followManga(_ manga: MangaItem, action: FollowAction, callback: @escaping SuccessCallback) {
        
        
        let userDefaults = UserDefaults.standard
        
        let secret = userDefaults.string(forKey: Constants.Defaults.Secret)!
        let allCookies = userDefaults.dictionary(forKey: Constants.Defaults.Cookies)!
        let session = allCookies["session_id"]
        
        let params: [String: AnyObject] = ["sKey": secret as AnyObject, "session": session! as AnyObject, "action": action.rawValue as AnyObject, "rid": manga.mangaId as AnyObject]
        
        Alamofire.request(MLRouter.post("follow", params))
            .validate()
            .responseJSON { (response) -> Void in
                switch response.result {
                case .success(_):
                    
                    if action == .Follow {
                        // add the manga to the follow list
                        FollowManga.createAndAddFromManga(manga)
                        
                    } else {
                        // remove the follow from the db
                        FollowManga.deleteManga(manga)
                        
                    }
                    
                    callback(true)
                case .failure(let error):
                    print(error.localizedDescription)
                    callback(false)
                }
        }
        
        
        
    }

}
