//
//  SideMenuViewController.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/4/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit

class SideMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var menuItems:[String] = ["Scan Codes", "Settings"] // Names of cells in side menu

    /**
     Initializes the view when view controller appears.
     **/
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     Used by side menu.
     **/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return menuItems.count
    }
    
    /**
     Used by side menu.
     **/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as! CustomTableViewCell
        myCell.menuLabel.text = menuItems[indexPath.row]
        return myCell
    }
    
    /**
     Used by side menu.
     **/
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Shows view selected from the side menu
        switch(indexPath.row) {
            case 0:
                let centerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                let centerNavController = UINavigationController(rootViewController: centerViewController)
                let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = centerNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
            case 1:
                let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
                let settingsNavController = UINavigationController(rootViewController: settingsViewController)
                let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = settingsNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
            default:
                break
        }
    }
}
