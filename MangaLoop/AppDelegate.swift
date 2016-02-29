//
//  AppDelegate.swift
//  MangaLoop
//
//  Created by Cameron Jackson on 1/21/16.
//  Copyright © 2016 Culdesaq. All rights reserved.
//

import UIKit
import JAMSVGImage
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // sets the status bar to white
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        UINavigationBar.appearance().barStyle = .Black
        
        
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        

        
        // Loads UIWindow and temporary RootViewController
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let updatesController = UpdatesViewController()
        updatesController.title = "Updates"
        updatesController.tabBarItem.image = UIImage(fromSVGNamed: Constants.Images.UpdatesTab)
        let updatesNavigationController = UINavigationController(rootViewController: updatesController)
        
        let followsController = FollowsController()
        followsController.title = "Follows"
        followsController.tabBarItem.image = UIImage(fromSVGNamed: Constants.Images.FollowsTab)
        let followsNavigationController = UINavigationController(rootViewController: followsController)
        
        let searchController = SearchViewController()
        searchController.title = "Search"
        let searchNavigationController = UINavigationController(rootViewController: searchController)
        
        let settingsController = SettingsViewController()
        settingsController.title = "Settings"
        settingsController.tabBarItem.image = UIImage(fromSVGNamed: Constants.Images.SettingsTab)
        let settingsNavigaitonController = UINavigationController(rootViewController: settingsController)
        
        let tabController = UITabBarController()
        tabController.viewControllers = [updatesNavigationController, followsNavigationController, searchNavigationController, settingsNavigaitonController]
        tabController.tabBar.translucent = false
        
        self.window!.rootViewController = tabController
        
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()
        
        let navAppearence = UINavigationBar.appearance()
        navAppearence.barTintColor = UIColor.redColor()
        navAppearence.tintColor = UIColor.whiteColor()
        navAppearence.translucent = false
        navAppearence.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        
//        let navItemAppearence = UINavigationItem.ap
        
        MangaManager.sharedManager.getAllFollowsIfNeeded(nil)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

