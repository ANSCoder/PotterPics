//
//  HomeViewController.swift
//  PotterPics
//
//  Created by Suraya Shivji on 11/16/16.
//  Copyright © 2016 Suraya Shivji. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit

class HomeViewController: UIViewController {
    
    var cloudsVideo: BackgroundVideo?
    let facebookPermissions = ["public_profile", "email", "user_friends"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up background video
        self.cloudsVideo = BackgroundVideo(on: self, withVideoURL: "IntroMusic.mp4")
        self.cloudsVideo?.setUpBackground()
        
//        for family in UIFont.familyNames {
//            print("\(family)")
//            
//            for name in UIFont.fontNames(forFamilyName: family) {
//                print("   \(name)")
//            }
//        }
    }
    
//    func getProfilePicture(fbID: NSString) -> UIImage? {
//        // use userID to get facebook profile picture
//        let imgURLString = "http://graph.facebook.com/" + (fbID as String) + "/picture?type=large" //type=normal
//        if let imgURL = URL(string: imgURLString) {
//            do {
//                let imageData = try Data(contentsOf: imgURL)
//                var image = UIImage(data: imageData)
//            }
//        }
//    }
    
    // login user via Facebook
    @IBAction func loginTapped(_ sender: HomeButton) {
        let loginManager: FBSDKLoginManager = FBSDKLoginManager()
        // check that the user isn't already logged in
        if FBSDKAccessToken.current() != nil {
            // user logged in, segue to navigation controller
            
            let firebaseAuth = FIRAuth.auth()
            do {
                print("signing out")
                try firebaseAuth?.signOut()
                FBSDKLoginManager().logOut()
                
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            print("User already logged in")
            self.performSegue(withIdentifier: "mainNavSegue", sender: nil)

        } else {
            loginManager.logIn(withReadPermissions: self.facebookPermissions, from: self, handler: { (result, error) in
                if (error != nil) {
                    loginManager.logOut()
                    let message: String = "An error has occured. \(error)"
                    let alertView = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alertView.addAction(UIAlertAction(title: "Ok ", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertView, animated: true, completion: nil)
                } else if (result?.isCancelled)! {
                    // user cancelled login
                    loginManager.logOut()
                } else {
                    let accessToken = FBSDKAccessToken.current()
                    guard let accessTokenString = accessToken?.tokenString else { return }
                    let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
                    
                    FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                        if (error != nil) {
                            // handle error
                            print(error ?? "Error")
                        } else {
                            print("Successful Login with Firebase")
                            let ref = FIRDatabase.database().reference(fromURL: "https://potterpics-2bcbc.firebaseio.com")

                            // guard for user id
                            guard let uid = user?.uid else {
                                return
                            }
                            let usersReference = ref.child("users").child(uid)
                            
                            // performing the Facebook graph request to get the user data that just logged in so we can assign this stuff to our Firebase database:
                            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"])
                            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                                
                                if ((error) != nil) {
                                    // Process error
                                    print("Error: \(error)")
                                } else {
                            
                                    let data:[String:AnyObject] = result as! [String : AnyObject]
                                    
                                    let userName:NSString = data["name"] as! NSString
                                    let userEmail:NSString = data["email"] as! NSString
                                    let userID:NSString = data["id"] as! NSString
                                    let imgURLString = "http://graph.facebook.com/\(userID)/picture?type=large" as NSString

                                    
//                                    if let profPic: UIImage = self.getProfilePicture(fbID: userID) {
//                                        var data = UIImageJPEGRepresentation(profPic, 1.0)
//                                        let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\("userPhoto")"
//                                        let metaData = FIRStorageMetadata()
//                                        metaData.contentType = "image/jpg"
//                                    }
                                    
                                    print("Users Facebook ID is: \(userID)")
                                    
                                    print("URLLLL \(imgURLString)")
                                    
                                    let values = ["name": userName, "email": userEmail, "facebookID": userID, "profPicString": imgURLString]
                                    
                                
                                    // update our databse by using the child database reference above called usersReference
                                    usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                                        // if there's an error in saving to our firebase database
                                        if err != nil {
                                            print(err ?? "Error saving user to database")
                                            return
                                        }
                                        // no error, so it means we've saved the user into our firebase database successfully
                                        print("Save the user successfully into Firebase database")
                                    })
                                }
                            })
                        self.dismiss(animated: false, completion: nil)
                        self.performSegue(withIdentifier: "mainNavSegue", sender: nil)
                        }
                    }
                }
            })
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
