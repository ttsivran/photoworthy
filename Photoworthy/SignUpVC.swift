//
//  SignUpVC.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 7/5/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import Firebase

class SignUpVC: UIViewController {

    @IBOutlet weak var nametf: UITextField!
    @IBOutlet weak var emailtf: UITextField!
    @IBOutlet weak var passwordtf: UITextField!
    @IBOutlet weak var confirmpasswordtf: UITextField!
    
    @IBOutlet weak var signUpBtn: UIButton!
    
    @IBOutlet weak var profileImageView: UIButton!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        let imageTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImageView.addGestureRecognizer(imageTap)
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self

        fixStyle()
    }
    
    @objc func openImagePicker() {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func fixStyle() {
        signUpBtn.layer.cornerRadius = 5;
        signUpBtn.clipsToBounds = true;
        
        nametf.setBottomBorder()
        emailtf.setBottomBorder()
        passwordtf.setBottomBorder()
        confirmpasswordtf.setBottomBorder()
        
        nametf.addImageToSide(image: UIImage(named: "duck-face.png")!)
        emailtf.addImageToSide(image: UIImage(named: "email.png")!)
        passwordtf.addImageToSide(image: UIImage(named: "password.png")!)
        confirmpasswordtf.addImageToSide(image: UIImage(named: "password.png")!)
        
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
    }
    
    func presentLoggedInScreen() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC: MapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        self.present(mapVC, animated: true, completion: nil)
    }
    
    @IBAction func signUp(_ sender: Any) {
        
        guard let image = profileImageView.currentImage else { return }
        
        if nametf.text?.isEmpty ?? true {
            let alert = UIAlertController(title: "Error Signing Up", message: "Name field must be filled.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if passwordtf.text != confirmpasswordtf.text {
            let alert = UIAlertController(title: "Error Signing Up", message: "Passwords must match.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if let email = emailtf.text, let password = passwordtf.text {
            Auth.auth().createUser(withEmail: email, password: password, completion: { user, error in
                if let firebaseError = error {
                    let alert = UIAlertController(title: "Error Signing Up", message: firebaseError.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                // upload image to firebase storage
                self.uploadProfileImage(image) { url in
                    
                    if url != nil {
                        print("hello!!!")
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = self.nametf.text
                        changeRequest?.photoURL = url
                        
                        changeRequest?.commitChanges { error in
                            if error == nil {
                                let ref: DatabaseReference = Database.database().reference()
                                let user: User = Auth.auth().currentUser!
                                
                                let userObject = [
                                    "username": self.nametf.text ?? "noname",
                                    //"photoURL": url ?? "noimage",
                                    "numpoi" : 0,
                                    "numpoints" : 0
                                    ] as [String:Any]
                                ref.child("users").child(user.uid).setValue(userObject)
                                
                            } else {
                                print("error setting properties of user during signup")
                            }
                        }
                        
                    } else {
                        // error unable to upload profile
                    }
                    
                    self.presentLoggedInScreen()
                }

            })
        }
    }
    
    func uploadProfileImage(_ image:UIImage, completion: @escaping ((_ url:URL?)->())) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("user/\(uid)")
        
        guard let imageData = UIImageJPEGRepresentation(image, 0.75) else { return }
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.putData(imageData, metadata: metaData) { metaData, error in
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                completion(downloadURL)
            }
        }
    }
}

extension SignUpVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.setImage(pickedImage, for: .normal)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}
