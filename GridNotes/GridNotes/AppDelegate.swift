//
//  AppDelegate.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = GridKeyboardViewController()
        initAudio()
        return true
    }
}

