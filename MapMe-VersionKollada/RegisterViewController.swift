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

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    var ref : FIRDatabaseReference?
    var handle: FIRAuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var grayBackgroundLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        ref = FIRDatabase.database().reference(withPath: "user-profiles")
        // 1
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "RegistrationComplete", sender: nil)
            }
        }
        addBackground()
        grayBackgroundLabel.layer.masksToBounds = true
       grayBackgroundLabel.layer.cornerRadius = 10
        titleLabel.layer.masksToBounds = true
        titleLabel.layer.cornerRadius = 20
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
        
        let email = usernameTextField.text!
        let password = passwordTextField.text!
        let name = nameTextField.text!
        
        print(email, password, name)
        
        if email != "" && password.characters.count >= 6 {
            FriendSystem.system.createAccount(email, password: password, name: name) { (success) in
                if success {
                    self.performSegue(withIdentifier: "RegistrationComplete", sender: self)
                }
                else {
                    // Error
                    self.presentSignupAlertView()
                }
            }
        }
        else {
            // Fields not filled
            presentSignupAlertView()
        }
            
        
    }
    
    func presentSignupAlertView() {
        let alertController = UIAlertController(title: "Error", message: "Couldn't create account", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    func addBackground() {
        // screen width and height:
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0,y: 0,width: width,height: height))
        imageViewBackground.image = #imageLiteral(resourceName: "ncBackgroundMap")
        imageViewBackground.alpha = 0.75
        // you can change the content mode:
        imageViewBackground.contentMode = UIViewContentMode.scaleAspectFill
        
        self.view.addSubview(imageViewBackground)
        self.view.sendSubview(toBack: imageViewBackground)
    }

    
}

