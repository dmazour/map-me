//
//  SettingViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/11/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuthUI

class SettingViewController: UIViewController {
    
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var stopDatePicker: UIDatePicker!
    @IBOutlet weak var usernameLabel: UILabel!
    
    let memory = UserDefaults()
    
    var settings: [String:Date] = [:]
    @IBOutlet var presentTime: UISwitch!
    
    var startDate:Date!
    var stopDate:Date!
    var user: FIRUser?
    var untilPresentTime = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startDate = Date(timeIntervalSince1970: 0)
        stopDate = Date(timeIntervalSinceNow: 0)
        startDatePicker.maximumDate = stopDatePicker.date
        stopDatePicker.minimumDate = startDatePicker.date
        user = (FIRAuth.auth()?.currentUser)!
        usernameLabel.text = user?.email
        
        settings = [
            "startDate":Date(timeIntervalSince1970: 0),
            "stopDate": Date()
        ]
    }
    

    @IBAction func startDatePicked(_ sender: Any) {
        startDate = startDatePicker.date
        stopDatePicker.minimumDate = startDate
        settings.updateValue(startDate, forKey: "startDate")
    }

    @IBAction func stopDatePicked(_ sender: Any) {
        startDate = startDatePicker.date
        stopDatePicker.minimumDate = startDate
        settings.updateValue(stopDate, forKey: "stopDate")
    }
    
    @IBAction func signOut(_ sender: Any) {
        do {
        try FIRAuth.auth()?.signOut()
            performSegue(withIdentifier: "Logout", sender: nil)
        }
        catch {
            print("Error while signing out")
        }
        
    }
    
    @IBAction func untilPresentTimeSelected(_ sender: UISwitch) {
        if sender.isOn {
            untilPresentTime = true
        }
        else{
            untilPresentTime = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        memory.setValue(settings, forKey: "settings")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


//mapView.mapType = MKMapType.satellite
//mapView.mapType = MKMapType.standard
