//
//  ProfileVC.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 6/28/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import Firebase

class ProfileVC: UIViewController {

    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var numPlaces: UILabel!
    @IBOutlet weak var numPoints: UILabel!
    
    @IBOutlet weak var profImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoutBtn.layer.cornerRadius = 5;
        logoutBtn.clipsToBounds = true;
        
        let photoUrl = Auth.auth().currentUser?.photoURL
        if photoUrl != nil {
            profImage.load(url: photoUrl!)
        }
        profImage.layer.cornerRadius = profImage.bounds.height / 2
        profImage.clipsToBounds = true
        
        welcomeLabel.text = Auth.auth().currentUser?.displayName
        
        let ref = Database.database().reference()
        let user: User = Auth.auth().currentUser!
        
        ref.child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
        
            let numPoi: Int = value?["numpoi"] as! Int
            print("numpoi " + String(value?["numpoi"] as! Int))
        
            let points: Int = value?["numpoints"] as! Int
            print("numpoints " + String(value?["numpoints"] as! Int))
        
            self.numPlaces.text? = String(numPoi)
            self.numPoints.text? = String(points)
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    @IBAction func logout(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let signInVC: SignInVC = storyboard.instantiateViewController(withIdentifier: "SignInVC") as! SignInVC
            self.present(signInVC, animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
