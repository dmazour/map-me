//
//  SecondViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/10/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI

class SecondViewController: UIViewController {
    
    var handle: FIRAuthStateDidChangeListenerHandle?
    var user: FIRUser?
    var rootRef: FIRDatabaseReference?
    var locations: FIRDatabaseReference?
    var name: FIRDatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        rootRef = FIRDatabase.database().reference()
        locations = rootRef?.child("locations")
        name = locations?.child((user?.uid)!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

