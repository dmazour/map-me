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
    
    var friendSystem = FriendSystem()
    
    override func viewDidLoad() {
        alertLabel.isHidden = true
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "LoginComplete", sender: nil)
            }
        }
//        FIRApp.configure()
        
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
        
        let email = usernameTextField.text!
        let password = passwordTextField.text!
        
        if email != "" && password.characters.count >= 6 {
            FriendSystem.system.loginAccount(email, password: password) { (success) in
                if success {
                    self.performSegue(withIdentifier: "LoginComplete", sender: self)
                } else {
                    // Error
                    self.presentLoginAlertView()
                }
            }
        } else {
            // Fields not filled
            presentLoginAlertView()
        }
    }
    
    func presentLoginAlertView() {
        let alertController = UIAlertController(title: "Error", message: "Email/password is incorrect", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
}
