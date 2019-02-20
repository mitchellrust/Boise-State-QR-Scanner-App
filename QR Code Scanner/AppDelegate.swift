//
//  AppDelegate.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/4/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Container for Side Menu
    var centerContainer: MMDrawerController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Creates side menu
        
        _ = self.window!.rootViewController
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let centerViewController = mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        let sideMenuViewController = mainStoryboard.instantiateViewController(withIdentifier: "SideMenuViewController") as! SideMenuViewController
        
        let leftSideNav = UINavigationController(rootViewController: sideMenuViewController)
        let centerNav = UINavigationController(rootViewController: centerViewController)
        
        centerContainer = MMDrawerController(center: centerNav, leftDrawerViewController: leftSideNav)
        centerContainer!.openDrawerGestureModeMask = MMOpenDrawerGestureMode.panningCenterView
        centerContainer!.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.panningCenterView
        
        window!.rootViewController = centerContainer
        window!.makeKeyAndVisible()
        
        return true
    }

}

