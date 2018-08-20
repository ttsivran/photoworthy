//
//  SignInVC.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 6/28/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInVC: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fixStyle()
        
        // GIDSignIn.sharedInstance().uiDelegate = self
        // GIDSignIn.sharedInstance().signIn()
        
        let googleBtn = GIDSignInButton()
        googleBtn.center = CGPoint(x: view.frame.width / 2, y: 6.9 * view.frame.height / 8)
        view.addSubview(googleBtn)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func fixStyle() {
        loginBtn.layer.cornerRadius = 5;
        loginBtn.clipsToBounds = true;
        
        email.setBottomBorder()
        password.setBottomBorder()
        
        email.addImageToSide(image: UIImage(named: "email.png")!)
        password.addImageToSide(image: UIImage(named: "password.png")!)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            self.presentLoggedInScreen()
        }
    }

    @IBAction func login(_ sender: Any) {
        if let email = email.text, let password = password.text {
            
            Auth.auth().signIn(withEmail: email, password: password, completion: { user, error in
                
                if let firebaseError = error {
                    let alert = UIAlertController(title: "Error Signing In", message: firebaseError.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                self.presentLoggedInScreen()
                // popup account created succesfully
            })
        }
    }
    
    func presentLoggedInScreen() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC: MapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        self.present(mapVC, animated: true, completion: nil)
    }
}

extension UITextField {
    
    func setBottomBorder() {
        self.borderStyle = .none
        // make bottom line this color
        //self.backgroundColor = UIColor(red:0.65, green:0.21, blue:0.30, alpha:1.0)
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor(red:0.65, green:0.21, blue:0.30, alpha:1.0).cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
    
    func addImageToSide(image: UIImage) {
        let leftView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 30))
        leftView.addSubview(UIImageView(image: image));
        self.leftView = leftView
        self.leftViewMode = UITextFieldViewMode.always
        self.leftViewMode = .always
    }
}
