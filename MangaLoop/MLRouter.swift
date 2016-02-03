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
    
    static let baseUrlString = "http://manga-dev.mangaloop.com/"
    
    
    typealias Parameters = [String:String]
    typealias Endpoint = String
    
    case Get(Endpoint, Parameters?)
    case Post(Endpoint, Parameters)
    
    var method: Alamofire.Method {
        switch self {
        case .Post:
            return .POST
        case .Get:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .Post(let endpoint, _):
            return endpoint
        case .Get(let endpoint, _):
            return endpoint
        }
    }
    
    
    var URLRequest: NSMutableURLRequest {
        
        
        let URL = NSURL(string: MLRouter.baseUrlString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue
        
        
        if let cookies = NSUserDefaults.standardUserDefaults().dictionaryForKey("cookies") {
            let cookiesString = cookies.map {"\($0)=\($1)"}.joinWithSeparator("; ")
            mutableURLRequest.setValue(cookiesString, forHTTPHeaderField: "Cookie")
        }
        
        
        switch self {
        case .Post(_, let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest,
                parameters: parameters).0
        case .Get(_, let paramaters):
            return Alamofire.ParameterEncoding.URLEncodedInURL.encode(mutableURLRequest, parameters: paramaters).0
        default:
            return mutableURLRequest
            
        }
        
        
    }
    
    
}