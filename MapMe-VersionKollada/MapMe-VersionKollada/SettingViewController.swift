//
//  SettingViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/11/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import UIKit

class SettingViewController: UIViewController {
    
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var stopDatePicker: UIDatePicker!
    
    var startDate:Date!
    var stopDate:Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startDate = Date(timeIntervalSince1970: 0)
        stopDate = Date(timeIntervalSinceNow: 0)
        startDatePicker.maximumDate = stopDatePicker.date
        stopDatePicker.minimumDate = startDatePicker.date
        
    }
    

    @IBAction func startDatePicked(_ sender: Any) {
        startDate = startDatePicker.date
        stopDatePicker.minimumDate = startDate
    }

    @IBAction func stopDatePicked(_ sender: Any) {
        startDate = startDatePicker.date
        stopDatePicker.minimumDate = startDate
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

//mapView.mapType = MKMapType.satellite
//mapView.mapType = MKMapType.standard
