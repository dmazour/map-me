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

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var handle:FIRAuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var grayBackground: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var alertLabel: UILabel!
    
    @IBOutlet weak var registerButton: UIButton!
    var friendSystem = FriendSystem()
    
    override func viewDidLoad() {
//        alertLabel.isHidden = true
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "LoginComplete", sender: nil)
            }
        }
//        FIRApp.configure()
        grayBackground.layer.masksToBounds = true
        grayBackground.layer.cornerRadius = 50
        titleLabel.layer.masksToBounds = true
        titleLabel.layer.cornerRadius = 20
        let attributeString = NSMutableAttributedString(string: "Register",
                                                        attributes: yourAttributes)
        registerButton.setAttributedTitle(attributeString, for: .normal)
        addBackground()

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
    let yourAttributes : [String: Any] = [
        NSFontAttributeName : UIFont.systemFont(ofSize: 14),
        NSForegroundColorAttributeName : UIColor.white,
        NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue]
    //.styleDouble.rawValue, .styleThick.rawValue, .styleNone.rawValue
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
