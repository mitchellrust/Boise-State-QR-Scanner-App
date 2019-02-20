//
//  SettingsViewController.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/4/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit
import KeychainSwift

class SettingsViewController: UIViewController {

    @IBOutlet weak var broncoMode: UISwitch! // On/Off switch for Bronco Mode
    
    let defaults = UserDefaults.standard // UserDefaults allows user preferences to be remembered over different sessions
    
    let keychain = KeychainSwift() // Creates a KeychainSwift object to access ios keychain
    
    @IBAction func broncoModePressed(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "broncoMode") // Adds the state of Bronco Mode to UserDefaults
    }
    
    /**
     Adds new passkey from user input to keychain.
    **/
    @IBAction func newAPIpressed(_ sender: Any) {
        // Prompts user to enter Hobson's Connect API Key
        let alert = UIAlertController(title: "Add Passkey", message: "Please enter a passkey.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            textField?.autocorrectionType = UITextAutocorrectionType.no // Disallows entered key to be stored in cache for autocorrect
            self.keychain.set((textField?.text)!, forKey: "connectKey", withAccess: .accessibleWhenUnlocked) // Adds passkey to keychain
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     Removes the current passkey from the keychain,
     if one exists.
    **/
    @IBAction func deleteKeyPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: "Delete the current passkey from the keychain?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { Void in
            if self.keychain.delete("connectKey") { // If successfully deleted passkey from keychain
                let alert = UIAlertController(title: "Passkey Deleted", message: "Passkey successfully deleted from keychain.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else { // No passkey was found in keychain
                let alert = UIAlertController(title: "Passkey Does Not Exist", message: "A passkey does not exist. Try adding a new passkey.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     Shows side menu if hamburger button pressed.
     **/
    @IBAction func menuButtonPressed(_ sender: Any) {
        let appDelegate:AppDelegate = (UIApplication.shared.delegate as? AppDelegate)!
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    /**
     Initializes the view when view controller appears.
     **/
    override func viewDidLoad() {
        super.viewDidLoad()
        broncoMode.isOn = defaults.bool(forKey: "broncoMode") // Sets state of switch based on previous default set
    }
}
