//
//  RegisterViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/13/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuthUI
import UIKit

class RegisterViewController: UIViewController {
    
    var ref : FIRDatabaseReference?
    var profile: UserProfile?
    var handle: FIRAuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var alertLabel: UILabel!
    
    override func viewDidLoad() {
        alertLabel.isHidden = true
        profile = UserProfile()
        ref = FIRDatabase.database().reference(withPath: "user-profiles")
        // 1
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "RegistrationComplete", sender: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = FIRAuth.auth()?.addStateDidChangeListener() { (auth, user) in
            // ...
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        FIRAuth.auth()?.removeStateDidChangeListener(handle!)
    }
    
    @IBAction func userRegistered(_ sender: Any) {
        if (nameTextField.text == nil) {
            alertLabel.text = "You must enter a name"
            alertLabel.isHidden = false
        }
        else if usernameTextField.text == nil {
            alertLabel.text = "You must enter a username"
            alertLabel.isHidden = false
        }
        else if passwordTextField.text == nil {
            alertLabel.text = "You must enter a password"
            alertLabel.isHidden = false
        }
        else {
            alertLabel.isHidden = true
            profile?.name = nameTextField.text!
            profile?.username = usernameTextField.text!
            profile?.password = passwordTextField.text!
            print("user name: " + (profile?.username)!)
            print("password: " + (profile?.password)!)
            
            FIRAuth.auth()?.createUser(withEmail: (profile?.username)!, password: (profile?.password)!) { (user, error) in
                // ...
                print("should be created")
                if error == nil {
                    FIRAuth.auth()?.signIn(withEmail: (self.profile?.username)!, password: (self.profile?.password)!)
                }
//                self.performSegue(withIdentifier: "Registration Complete", sender: nil)
                
            }
            
//            let profileRef = self.ref?.child((profile?.name)!)
//            
//            profileRef?.setValue(profile?.toAnyObject()
            
            
            
        }
    }
}
