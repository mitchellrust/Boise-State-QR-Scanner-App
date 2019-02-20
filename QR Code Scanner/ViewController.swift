//
//  ViewController.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/4/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit
import KeychainSwift


class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let date = Date() // Gets current date
    let dateFormatter = DateFormatter()
        
    var eventNames:[String] = [""] // Will hold list of today's event names
    var eventGIDs:[String] = [""] // Will hold list of today's events' GIDs
    var passKey:String = "" // Holds the Connect passkey used for web requests
    var gid:String? // Holds the GID for the event that is selected to scan for

    @IBOutlet weak var eventPicker: UIPickerView! // UIPicker for events displayed on the ViewController
    
    /**
     Shows side menu if hamburger button pressed.
    **/
    @IBAction func menuButtonPressed(_ sender: Any) {
        let appDelegate:AppDelegate = (UIApplication.shared.delegate as? AppDelegate)!
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    /**
     Runs when "Scan" button is pressed.
     Gets the event GID of the selected event and
     triggers the transition to ScannerViewController.
     **/
    @IBAction func eventSelected(_ sender: Any) {
        let selectedEvent = eventNames[eventPicker.selectedRow(inComponent: 0)] // Gets event the user selects
        gid = eventGIDs[eventNames.firstIndex(of: selectedEvent)!] // Gets the selected event's GID
        if gid == "" { // if no event is selected...
            let alert = UIAlertController(title: "No Event Selected", message: "An event must be selected in order to scan QR codes.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else { // an event is selected
            performSegue(withIdentifier: "showCamera", sender: self) // performs segue to ScannerViewController
        }
    }
    
    /**
     Passes event GID to ScannerViewController.swift.
    **/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? ScannerViewController // Gets Scanner View
        vc?.eventGID = self.gid! // Passes GID to ScannerViewController.swift
        vc?.passKey = self.passKey // Passes passKey to ScannerViewController.swift
    }
    
    /**
    Runs initialization methods.
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        sendRequest()
    }
    
    /**
     Get's list of events for the current day from
     Hobsons so the user can select one to scan for.
    **/
    func sendRequest() {
        
        let keychain = KeychainSwift() // Creates KeychainSwift object
        passKey = keychain.get("connectKey") ?? "null" // Get's Connect passkey from keychain
        
        dateFormatter.dateFormat = "dd MMM yyyy " // formats SOAP request dates to comply with Hobsons' standards
        
        //let startFrom = dateFormatter.string(from: date) + "12:00 AM" // Doesn't get events earlier than current date at 12:00AM
        let startFrom = "05 Oct 2019 12:00 AM" // Date used for testing
        
        //let startTo = dateFormatter.string(from: date) + "11:59 PM" // Doesn't get events later than current date at 11:59PM
        let startTo = "05 Oct 2019 11:59 PM" // Date used for testing
        
        // SOAP request body with date parameters
        let body:String = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:web='http://connect2.askadmissions.net/webservices/'>" +
            "<soapenv:Header/>" +
            "<soapenv:Body>" +
            "<web:GetEventsAndInterviews>" +
            "<web:clientName>boisestate</web:clientName>" +
            "<web:passKey>\(passKey)</web:passKey>" +
            "<web:classification>1</web:classification>" +
            "<web:startsOnFrom>\(startFrom)</web:startsOnFrom>" +
            "<web:startsOnTo>\(startTo)</web:startsOnTo>" +
            "<web:status>2</web:status>" +
            "</web:GetEventsAndInterviews>" +
            "</soapenv:Body>" +
        "</soapenv:Envelope>";
        
        // Connect's endpoint URL
        let is_URL: String = "https://services01.askadmissions.net/ws/bridge.asmx?wsdl"
        
        // Creates framework for SOAP request
        let lobj_Request = NSMutableURLRequest(url: NSURL(string: is_URL)! as URL)
        let session = URLSession.shared
        let _: NSError?
        lobj_Request.httpMethod = "POST" // Always POST, does not accept GET
        lobj_Request.httpBody = body.data(using: String.Encoding.utf8)
        lobj_Request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // Sends the SOAP request and parses response
        let task = session.dataTask(with: lobj_Request as URLRequest, completionHandler: {data, response, error -> Void in
            let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            let string = String(describing: strData) // SOAP response in human-readable format
            if string.range(of:"Passkey is invalid") != nil { // If the passkey is invalid...
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Invalid Passkey", message: "Go to the app settings to add a valid passkey.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else { // The passkey is valid
                self.getEventNames(in: string)
                self.getEventGIDs(in: string)
                DispatchQueue.main.async { // Must run all view changes in main thread
                    self.eventPicker.delegate = self // Displays event data in view
                    self.eventPicker.dataSource = self // Displays event data in view
                }
            }
            if error != nil { // If the request does not work...
                print("Error: " + error.debugDescription)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: "An error occured. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        })
        task.resume() // Starts the SOAP request, which is built in a non-active state
    }
    
    /*
     Add's event names from Connect to a eventNames list
     */
    func getEventNames(in text: String) {
        do {
            let regex = try NSRegularExpression(pattern: "Name&gt;&lt;!\\[CDATA\\[(.+?)\\]", options: .caseInsensitive)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var events = results.map {
                String(text[Range($0.range, in: text)!])
            }
            
            // Adds all found events to eventNames list
            for i in 0..<events.count {
                let start = events[i].index(events[i].startIndex, offsetBy: 20)
                let end = events[i].index(events[i].endIndex, offsetBy: -1)
                let range = start..<end
                let newStr = events[i][range]
                let event = String(newStr)
                eventNames.append(event)
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
        }
    }
    
    /*
     Add's event GIDs from Connect to eventGIDs list
     */
    func getEventGIDs(in text: String) {
        do {
            let regex = try NSRegularExpression(pattern: "GID&gt;&lt;!\\[CDATA\\[(.+?)\\]", options: .caseInsensitive)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var ids = results.map {
                String(text[Range($0.range, in: text)!])
            }
            
            // Adds all found event GIDs to eventGIDs list
            for i in 0..<ids.count {
                let start = ids[i].index(ids[i].startIndex, offsetBy: 19)
                let end = ids[i].index(ids[i].endIndex, offsetBy: -1)
                let range = start..<end
                let newStr = ids[i][range]
                let id = String(newStr)
                eventGIDs.append(id)
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
        }
    }
    
    /**
     Used by eventPicker.
    **/
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /**
     Used by eventPicker.
     **/
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return eventNames.count
    }
    
    /**
     Used by eventPicker.
     **/
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return eventNames[row]
    }
}
