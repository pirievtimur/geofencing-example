//
//  AppDelegate.swift
//  Geofencing For Noobs
//
//  Created by Hilton Pintor Bezerra Leite on 25/04/2018.
//  Copyright © 2018 Hilton Pintor Bezerra Leite. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import AppSpectorSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var locationManager: CLLocationManager!
    var notificationCenter: UNUserNotificationCenter!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let config = AppSpectorConfig(apiKey: "key", monitorIDs: [Monitor.location])
        AppSpector.run(with: config)
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        
        notificationCenter = UNUserNotificationCenter.current()
        
        // register as it's delegate
        notificationCenter.delegate = self
        
        // define what do you need permission to use
        let options: UNAuthorizationOptions = [.alert, .sound]
        
        // request permission
        notificationCenter.requestAuthorization(options: options) { (granted, error) in
            if !granted {
                print("Permission not granted")
            }
        }
        
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            print("I woke up thanks to geofencing")
        }
        
        
        return true
    }
    
    func handleEvent(forRegion region: CLRegion!, didEnter: Bool) {
        
        let textToShow = "You \(didEnter ? "entered" : "left") place \(region.identifier)"
        
        let content = UNMutableNotificationContent()
        content.title = "Location observing"
        content.body = textToShow
        content.sound = UNNotificationSound.default
        
        let timeInSeconds: TimeInterval = 3
        // the actual trigger object
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInSeconds,
            repeats: false
        )
        
        let identifier = region.identifier
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request, withCompletionHandler: { (error) in
            if error != nil {
                print("Error adding notification with identifier: \(identifier)")
            }
        })
    }
}


extension AppDelegate: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            // Do what you want if this information
            self.handleEvent(forRegion: region, didEnter: false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            self.handleEvent(forRegion: region, didEnter: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.notification.request.identifier
        
        print(identifier)
    }
}
