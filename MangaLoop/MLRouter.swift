//
//  MLRouter.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/24/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import Foundation
import Alamofire

enum MLRouter: URLRequestConvertible {
    
    static let baseUrlString = "https://manga-dev.mangaloop.com/"
    
    
    typealias Parameters = [String:AnyObject]
    typealias Endpoint = String
    
    case get(Endpoint, Parameters?)
    case post(Endpoint, Parameters)
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .post:
            return Alamofire.HTTPMethod.post
        case .get:
            return Alamofire.HTTPMethod.get
        }
    }
    
    var path: String {
        switch self {
        case .post(let endpoint, _):
            return endpoint
        case .get(let endpoint, _):
            return endpoint
        }
    }
    
    
    func asURLRequest() throws -> URLRequest {
        
        
        let URL = Foundation.URL(string: MLRouter.baseUrlString)!
        var mutableURLRequest = URLRequest(url: URL.appendingPathComponent(path))
        mutableURLRequest.httpMethod = method.rawValue
        
        
        var cookies = [String:AnyObject]()
        
        cookies["lang_option"] = MangaManager.languages().joined(separator: "%3B") as AnyObject?
        
        // handle a signed in user
        if let signInCookies = UserDefaults.standard.dictionary(forKey: "cookies") {
            for (key, value) in signInCookies {
                cookies[key] = value as AnyObject?
            }
        }
        
        let cookiesString = cookies.map {"\($0)=\($1)"}.joined(separator: "; ")
        mutableURLRequest.setValue(cookiesString, forHTTPHeaderField: "Cookie")
        
        
        switch self {
        case .post(_, let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)
        case .get(_, let paramaters):
            return try Alamofire.URLEncoding.default.encode(mutableURLRequest, with: paramaters)
        default:
            return mutableURLRequest as URLRequest
            
        }
        
        
    }
    
    
}
