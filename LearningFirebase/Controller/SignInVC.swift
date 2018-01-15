//
//  SignInVC.swift
//  LearningFirebase
//
//  Created by Kioja Kudumu on 1/12/18.
//  Copyright © 2018 Kioja Kudumu. All rights reserved.
//

import UIKit
import Firebase

class SignInVC: UIViewController {
    
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    @IBAction func onSignInTapped(_ sender: Any) {
        
        guard let email = emailTF.text,
        email != "",
        let password = passwordTF.text,
        password != ""
            else {
                AlertController.showAlert(self, title: "Missing info", message: "Please fill out all required fields")
                return
                
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            DatabaseService.shared.REF_ADMINS.observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? NSDictionary {
                    if let adminEmail = dictionary["email"] as? String {
                        if email == adminEmail {
                            self.performSegue(withIdentifier: "SignInToSignalsSegue", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "ToUserVC", sender: self)
                        }
                    }
                }
            })
            guard error == nil else {
                AlertController.showAlert(self, title: "Error", message: error!.localizedDescription)
                return
            }
            guard let user = user else { return }
            print(user.email ?? "MISSING EMAIL")
            print(user.displayName ?? "MISSING DISPLAY NAME")
            print(user.uid)
            
        }
    }
    
    
    
    @IBAction func onSignUpTapped(_ sender: Any) {
        
        self.performSegue(withIdentifier: "SignInToSignUpSegue", sender: nil)
        
    }
    
    
    
}
    


