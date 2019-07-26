//
//  MainViewController.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 22/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import UIKit
import FirebaseUI
import FirebaseDatabase


class MainViewController: UIViewController {

    private var buttonIsLogin: Bool = true
    private var df: DateFormatter = DateFormatter()
    var currentPowerUp: PowerUp = CoreDataStack.shared.getPowerUp()
    
    @IBOutlet weak var loginRegisterButton: UIButton!
    @IBOutlet weak var defenceTextField: UITextField!
    @IBOutlet weak var attackTextField: UITextField!
    @IBOutlet weak var updatedTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        df.dateFormat = "dd-MMM-yy hh:mm:ss"
        updateAttackAndDefence()
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func login(_ sender: Any) {
        if buttonIsLogin{
            if let authUI = FUIAuth.defaultAuthUI() {
                print("ok... lets go")
                authUI.delegate = self
                let emailAuth = FUIEmailAuth()
                emailAuth.signIn(withPresenting: self, email: nil)
                authUI.providers = [emailAuth]
                let authVC = authUI.authViewController()
                present(authVC, animated: true, completion: {
                    print("completed")
                    self.buttonIsLogin = false
                    self.loginRegisterButton.titleLabel?.text = "Logout"
                })
            }else{
                print("why here?")
            }
        }else{
            do{
                try Auth.auth().signOut()
                self.buttonIsLogin = true
                self.loginRegisterButton.titleLabel?.text = "Login / Register"
            }catch{
                print("signout failed")
                print(error)
            }
        }
        print("Exiting login")
    }
    
    func checkForPowerUps(){
        if let user = Auth.auth().currentUser{
            let firebaseRef = Database.database().reference()
            firebaseRef.child("users").child(user.uid).child("attack").observe(.value) { (data) in
                print("Attack \(data)")
                
                print(type(of: data))
                if let attack = data.value as? Int16{
                    print(attack)
                    self.currentPowerUp.attack = attack
                    self.currentPowerUp.date = Date()
                    CoreDataStack.shared.save()
                    self.updateAttackAndDefence()
                }
            }
            firebaseRef.child("users").child(user.uid).child("defence").observe(.value) { (data) in
                print("Defence \(data)")
                if let defence = data.value as? Int16{
                    print(defence)
                    self.currentPowerUp.defence = defence
                    self.currentPowerUp.date = Date()
                    CoreDataStack.shared.save()
                    self.updateAttackAndDefence()
                }
            }
        }
    }
    
    private func updateAttackAndDefence(){
        defenceTextField.text = String(currentPowerUp.defence)
        attackTextField.text = String(currentPowerUp.attack)
        if let d = currentPowerUp.date{
            updatedTextField.text = df.string(from: d)
        }
    }
}


extension MainViewController: FUIAuthDelegate{
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, url: URL?, error: Error?) {

        if let error = error{
            print("Failure in FUIAuthDelegate with error:")
            print(error)
        }else{
            print("uid: \(authDataResult?.user.uid ?? "No uid")")
            loginRegisterButton.titleLabel?.text = "Logout"
            buttonIsLogin = false
            checkForPowerUps()
        }
    }
}
