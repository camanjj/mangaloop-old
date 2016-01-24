//: [Previous](@previous)

import Foundation
import XCPlayground
import UIKit
import Alamofire
import Kanna
import ObjectMapper
import AlamofireObjectMapper
import Unbox

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


var str = "Hello, playground"

//: [Next](@next)

var info: [String: AnyObject] = [:]

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
        
        
//        if let cookies = NSUserDefaults.standardUserDefaults().dictionaryForKey("cookies") {
            let cookiesString = info.map {"\($0)=\($1)"}.joinWithSeparator("; ")
            print(cookiesString)
            mutableURLRequest.setValue(cookiesString, forHTTPHeaderField: "Cookie")
//        }
        
        
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


let loginParams = [
    "auth_key": "880ea6a14ea49e853634fbdc5015a024",
    "referer": "http://bato.to/",
    "ips_username": "caman8998",
    "ips_password": "cameron",
    "rememberMe": true
]


let loginRequest = Alamofire.request(.POST, "https://bato.to/forums/index.php?app=core&module=global&section=login&do=process", parameters: loginParams, encoding: .URL)
    
    .responseString { (response) -> Void in
        
        if let
            headerFields = response.response?.allHeaderFields as? [String: String],
            URL = response.request?.URL
        {
            let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headerFields, forURL: URL)
            
            if cookies.contains({$0.name == "pass_hash"}) {
                print("User Logged in")
                
                // store the cookies in a dictionary
//                var info: [String: AnyObject] = [:]
                for cookie in cookies {
                    info[cookie.name] = cookie.value
                }
                
                print(info)
                
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
                                        
                                        print(secret)
                                        
                                        let userDefaults = NSUserDefaults.standardUserDefaults()
                                        userDefaults.setObject(info, forKey: "cookies")
                                        userDefaults.setObject(secret, forKey: "secret")
                                        userDefaults.synchronize()
                                        
                                        let followsRequest = Alamofire.request(MLRouter.Get("follows", nil))
                                            .responseJSON(completionHandler: { (response) -> Void in
                                                if let json = response.result.value {
                                                    print(json)
                                                }
                                            })
                                        
                                        debugPrint(followsRequest)
                                }
                                
                                
                        } else {
                            print(response)
                        }
                        
                    })
                
            } else {
                print("Login failed")
            }
            //            print(cookies)
        }
}

