//
//  AppDelegate.swift
//  foresite
//
//  Created by David Cheng on 9/8/18.
//  Copyright © 2018 2DGB. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GooglePlaces
import IQKeyboardManagerSwift
import UserNotifications
import UserNotificationsUI
import FirebaseMessaging
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Request notification access
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            
        }

        application.registerForRemoteNotifications()
        registerNotificationTypes()
        
        // Messaging init for accessing FCM registrationToken
        Messaging.messaging().delegate = self
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Setup Google Maps/Places
        GMSServices.provideAPIKey(PrivateConstants.GoogleMapsAPIKey)
        GMSPlacesClient.provideAPIKey(PrivateConstants.GoogleMapsAPIKey)
        
        IQKeyboardManager.shared.enable = true
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        print(userInfo["data"])
        print("\n\n\n\n wowwwwwzaaa was accessed\n\n\\n\n")
        print()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func registerNotificationTypes() {
        // Define the custom actions.
        let yesAction = UNNotificationAction(identifier: "YES_ACTION",
                                                title: "yes",
                                                options: [.foreground])
        let noAction = UNNotificationAction(identifier: "NO_ACTION",
                                                 title: "no",
                                                 options: [.foreground])
        // NOTE: actions bring app to the foreground because Firebase points are plotted in background thread
        
        // Define the notification type
        let nearbyReportNotification =
            UNNotificationCategory(identifier: "NEARBY_REPORT_NOTIFICATION",
                                   actions: [yesAction, noAction],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([nearbyReportNotification])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // https://developer.apple.com/documentation/usernotifications/declaring_your_actionable_notification_types
        print("yahoo")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Get the meeting ID from the original notification.
        let userInfo = response.notification.request.content.userInfo
        
        var responseReport = Report(fromDictionary: userInfo as! [String : Any])

        if response.notification.request.content.categoryIdentifier ==
            "NEARBY_REPORT_NOTIFICATION" {

            switch response.actionIdentifier {
            case "YES_ACTION":
                print("\nthe user responded yes")
                
                var locationManager: CLLocationManager!
                locationManager = CLLocationManager()
                locationManager.startUpdatingLocation()
                
                // break out and don't record data point if the location is inaccessible
                if (locationManager.location == nil) {
                    locationManager.stopUpdatingLocation()
                    return
                } else {
                    print("\n\n\nFound the current location ")
                }
                
                responseReport.latitude = locationManager.location?.coordinate.latitude
                responseReport.longitude = locationManager.location?.coordinate.longitude
                print(responseReport.latitude)
                print(responseReport.longitude)
                locationManager.stopUpdatingLocation()
                
                responseReport.time = Date().toISO8601()
                responseReport.comment = ""
                
                responseReport.deviceID = UIDevice.current.identifierForVendor!.uuidString
                responseReport.isInitialReport = false
                responseReport.hasSeen = true
                
                responseReport.upload()
                
                //responseReport.upload()
                /*
                let dbRef = Database.database().reference().child("reports")
                let reportRef = dbRef.childByAutoId()
                let reportAutoID = reportRef.key
                responseReport.uniqueID = reportAutoID
                reportRef.updateChildValues(responseReport.toDict())*/

                break
            case "NO_ACTION":
                print("\nthe user responded no")
                
                var locationManager: CLLocationManager!
                locationManager = CLLocationManager()
                locationManager.startUpdatingLocation()
                
                // break out and don't record data point if the location is inaccessible
                if (locationManager.location == nil) {
                    locationManager.stopUpdatingLocation()
                    return
                } else {
                    print("\n\n\nFound the current location ")
                }
                
                responseReport.latitude = locationManager.location?.coordinate.latitude
                responseReport.longitude = locationManager.location?.coordinate.longitude
                
                locationManager.stopUpdatingLocation()
                
                responseReport.time = Date().toISO8601()
                responseReport.comment = ""
                
                responseReport.deviceID = UIDevice.current.identifierForVendor!.uuidString
                responseReport.isInitialReport = false
                responseReport.hasSeen = false
                
                responseReport.upload()
                
                break
            case UNNotificationDefaultActionIdentifier,
                 UNNotificationDismissActionIdentifier:
                print("\nthe user declined response")
                break
            default:
                break
            }
        }
        else {
            // Handle other notification types...
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        let fcmTokensRef = Database.database().reference().child("fcmTokens")
        fcmTokensRef.updateChildValues(["\(fcmToken)": "\(fcmToken)"])
        
        // get fcm token
        // https://firebase.google.com/docs/cloud-messaging/ios/client
        /*
         InstanceID.instanceID().instanceID { (result, error) in
         if let error = error {
         print("Error fetching remote instange ID: \(error)")
         } else if let result = result {
         print("Remote instance ID token: \(result.token)")
         self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
         }
         }
         */
    }
}
