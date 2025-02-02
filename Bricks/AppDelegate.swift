//
//  AppDelegate.swift
//  GoalsForRoles
//
//  Created by Benjamin Patch on 10/21/15.
//  Copyright © 2015 PatchWork. All rights reserved.
//

import UIKit
import Fabric
import DigitsKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NSLog("Starting up...")
        // Override point for customization after application launch.

        Fabric.with([Digits.self])
        
        DateController.loadDownloadDate()
        if DateController.downloadDate == nil {
            DateController.downloadDate = Date()
        }
        

        // push notifications
        
        AppearanceController.setupAppearance()
        
        UserController.loadUserID()
        if UserController.userID != "" {
            // Not first time using the app.
            cloudKitController.registerForNotifications()
            cloudKitController.sharedInstance.updateExpirationRecords()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UserController.sharedInstance.currentUser.save()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        UserController.sharedInstance.currentUser.save()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        DateController.saveDownloadDate()
    
        
        // Setup Push notifications with date
        cloudKitController.sharedInstance.updateExpirationRecords {
            cloudKitController.updateAllAccountableRoles()
        }
        
        // Save notificationData to Firebase
        
    }
    
    // Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error._code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("DID RECIEVE REMOTE NOTIFICATION!!!!!!!")
        
        guard let userInfo = userInfo as? [String : NSObject] else { print("Bad Notifications"); return; }
        
        let cloudKitNotification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        print(cloudKitNotification.alertBody)
        if let queryNotification = cloudKitNotification as? CKQueryNotification , queryNotification.notificationType == .query {
            guard let subscriptionID = queryNotification.subscriptionID, let subscriptionType = cloudKitSubscriptionIDType(rawValue: subscriptionID) else {
                completionHandler(UIBackgroundFetchResult.failed)
                return
            }

            let recordID: CKRecordID = queryNotification.recordID!
            
            switch subscriptionType {
            case .create, .update:
                
                cloudKitController.getRecordWithRecordID(recordID, completion: { (record, error) in
                    
                    if let error = error {
                        
                        print(error)
                        completionHandler(UIBackgroundFetchResult.failed)
                        
                    } else if let record = record {
                        
                        NotificationController.updateNotifications(record)
                        completionHandler(UIBackgroundFetchResult.newData)
                        
                    } else {
                        
                        print("ERROR: No record with recrod id: \(recordID)")
                        completionHandler(UIBackgroundFetchResult.failed)
                        
                    }
                    
                })

            case .delete:
                NotificationController.cancelNotifications(recordID)
            }
            
        }
    }
    
}




//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
//        print("\n\n\n\nRECIEVED REMOTE NOTIFICATION!\n\n\n")
//        guard let userInfo = userInfo as? [String : NSObject] else { print("Bad Notifications"); return; }
//
//        let cloudKitNotification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
//        print(cloudKitNotification.alertBody)
//        if let cloudKitNotification = cloudKitNotification as? CKQueryNotification where cloudKitNotification.notificationType == .Query {
//            let queryNotification: CKQueryNotification = cloudKitNotification
//            let recordID: CKRecordID = queryNotification.recordID!
//            print(recordID)
//        }
//
//
//    }

