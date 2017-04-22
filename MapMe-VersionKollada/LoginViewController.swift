//
//  LoginViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/13/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuthUI

class LoginViewController: UIViewController {
    
    var handle:FIRAuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var alertLabel: UILabel!
    
    override func viewDidLoad() {
        alertLabel.isHidden = true
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "LoginComplete", sender: nil)
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
    
    
    @IBAction func signInAttempted(_ sender: Any) {
        
        if usernameTextField.text == nil {
            alertLabel.isHidden = false
            alertLabel.text = "You must enter a username"
            
        }
        else if usernameTextField.text == nil {
            alertLabel.isHidden = false
            alertLabel.text = "You must enter a password"
        }
        else {
            FIRAuth.auth()?.signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!) { (user, error) in
            // ...
                if user != nil {
//                    self.performSegue(withIdentifier: "LoginComplete", sender: nil)
                }
                else {
                    self.alertLabel.text = "Wrong username or password"
                }
            }
            self.alertLabel.isHidden = false
            self.alertLabel.text = "Wrong username or password"
            
        }
    }
}
