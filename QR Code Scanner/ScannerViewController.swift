//
//  ScannerViewController.swift
//  QR Code Scanner
//
//  Created by Mitch Rust on 12/5/18.
//  Copyright © 2019 Mitch Rust. All rights reserved.
//

import UIKit
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var passKey = "" // Value is populated with Connect passkey from the keychain    
    var eventGID = "" // Value is populated with selected eventGID when view loads
    
    let broncoMode = UserDefaults.standard.bool(forKey: "broncoMode") // Checks if Bronco Mode is enabled
    var success:String! // Holds name of "success" audio file
    var successAudioPlayer = AVAudioPlayer() // Audio player for "success" tone
    var failedAudioPlayer = AVAudioPlayer() // Audio player for "failure" tone
    
    @IBOutlet weak var greenSquare: UIImageView! // Visual for successful attendance
    @IBOutlet weak var redSquare: UIImageView! // Visual for failed attendance
    @IBOutlet weak var toolbar: UIToolbar! // Holds camera switch at bottom of view
    
    var frontCamera:Bool = false // Always start with back camera on initial view load
    
    @IBOutlet var previewView: UIView! // Main view of the view controller, holds all elements
    var captureSession: AVCaptureSession? // Gets live camera feed
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? //Displays camera feed
    
    /**
     Changes to front/back camera when switch button
     is pressed.
    **/
    @IBAction func switchCamera(_ sender: Any) {
        if frontCamera == false {
            frontCamera = true
        } else {
            frontCamera = false
        }
        viewDidLoad() // Reloads view to show new camera view
    }
    
    /**
     Initializes the view when view controller appears.
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = UIColor.black // Set back button color to black
        
        // Sets the "success" tone
        if broncoMode == false {
            success = Bundle.main.path(forResource: "success", ofType: "wav")
        } else {
            success = Bundle.main.path(forResource: "bronco", ofType: "wav")
        }
        
        let failure = Bundle.main.path(forResource: "failure", ofType: "wav") // Sets the "failure" tone
        
        // Creates audio players with "success" and "failure" tones
        do {
            successAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: success))
            failedAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: failure!))
        } catch {
            print("Error: \(error)")
        }
        
        let captureDevice:AVCaptureDevice! // Declares a camera device, not yet instantiated
        
        // Instantiates either front or back camera as the captureDevice
        if frontCamera == false {
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        } else {
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
        
        if captureDevice == nil {
            print("Camera device could not be found.")
        } else {
            // Creates the camera view, adds all elements to this view
            do {
                captureSession = AVCaptureSession()
                
                let input = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession?.addInput(input)
                //videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                // Allows camera to recognize QR codes, courtesy of built in swift libraries
                let output = AVCaptureMetadataOutput()
                captureSession?.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.frame = view.layer.bounds
                videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill;
                previewView.layer.addSublayer(videoPreviewLayer!)
                previewView.bringSubviewToFront(toolbar)
                previewView.bringSubviewToFront(redSquare)
                previewView.bringSubviewToFront(greenSquare)
                greenSquare.isHidden = true
                redSquare.isHidden = true
                captureSession?.startRunning()
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    /**
     Runs when a qr code is found in camera view.
    **/
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 { // If there is a QR code found...
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                if object.type == AVMetadataObject.ObjectType.qr {
                    DispatchQueue.main.async {
                        self.captureSession?.stopRunning() // Pause camera to prevent back-to-back duplicate scans
                        
                        // Shows loading indicator while marking attendance
                        let wait = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
                        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 10, width: 50, height: 50))
                        loadingIndicator.hidesWhenStopped = true
                        loadingIndicator.style = UIActivityIndicatorView.Style.gray
                        loadingIndicator.startAnimating();
                        wait.view.addSubview(loadingIndicator)
                        self.present(wait, animated: true, completion: nil)
                    }
                    markAttended(contactID: object.stringValue ?? "error")
                }
            }
        }
    }
    
    /**
     Sends SOAP request to mark attendance.
     PARAM contactID: the contact ID pulled from QR code
    **/
    func markAttended(contactID: String) {
        
        // SOAP request body with contactID and eventGID parameters
        let body:String = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:web='http://connect2.askadmissions.net/webservices/'><soapenv:Header/><soapenv:Body><web:UpdateContactStatusForEventOrInterview><web:clientName>boisestate</web:clientName><web:passKey>\(passKey)</web:passKey><web:eventOrInterviewGid>\(eventGID)</web:eventOrInterviewGid><web:contactId>\(contactID)</web:contactId><web:attendanceStatus>Attended</web:attendanceStatus></web:UpdateContactStatusForEventOrInterview></soapenv:Body></soapenv:Envelope>";
        
        // Connect's endpoint URL
        let is_URL: String = "https://services01.askadmissions.net/ws/bridge.asmx?wsdl"
        
        // Creates framework for SOAP request
        var string = ""
        let lobj_Request = NSMutableURLRequest(url: NSURL(string: is_URL)! as URL)
        let session = URLSession.shared
        let _: NSError?
        lobj_Request.httpMethod = "POST" // Always POST, does not accept GET
        lobj_Request.httpBody = body.data(using: String.Encoding.utf8)
        lobj_Request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // Sends the SOAP request and parses response
        let task = session.dataTask(with: lobj_Request as URLRequest, completionHandler: {data, response, error -> Void in
            let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            string = String(describing: strData) // SOAP response in human-readable format
            if string.range(of:"successfully updated") != nil { // If successfully marked as attended...
                self.successAudioPlayer.play() // Plays "success" tone
                DispatchQueue.main.async { // Must run all view changes in main thread
                    self.dismiss(animated: false, completion: nil) // Removes loading indicator
                    self.greenSquare.isHidden = false // Shows visual for "success"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.greenSquare.isHidden = true
                    self.captureSession?.startRunning() // Resume video capture
                }
            } else { // There was a problem (invalid contactID, Connect issue, etc)...
                self.failedAudioPlayer.play() // Plays "failure" tone
                DispatchQueue.main.async { // Must run all view changes in main thread
                    self.dismiss(animated: false, completion: nil) // Removes loading indicator
                    self.redSquare.isHidden = false // Shows visual for "failure"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.redSquare.isHidden = true
                    self.captureSession?.startRunning() // Resume video capture
                }
            }
            if error != nil { // If the request does not work...
                print("Error: " + error.debugDescription)
            }
        })
        task.resume() // Starts the above SOAP request, which is built in a non-active state
    }
}
