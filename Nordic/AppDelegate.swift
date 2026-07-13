//
//  AppDelegate.swift
//  Nordic
//
//  Created by Sai Dammu on 4/14/21.
//

import UIKit
import DropDown
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DropDown.startListeningToKeyboard()
        //IQKeyboardManager.shared.enable = true
        AppUtility.lockOrientation(.portrait)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }

        /// Locks the allowed orientations and forces an immediate rotation.
        /// `UIDevice.setValue(_:forKey:"orientation")` is the pre-iOS-16 way
        /// to force this; iOS 16+ flags it as unsupported and requires
        /// `UIWindowScene.requestGeometryUpdate(_:)` instead. Deployment
        /// target is iOS 15.6, so both paths are kept.
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            self.lockOrientation(orientation)

            if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
                windowScene.requestGeometryUpdate(preferences) { error in
                    print("Failed to update window scene geometry: \(error)")
                }
            } else {
                UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
            }
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    
}


