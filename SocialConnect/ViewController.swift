//
//  ViewController.swift
//  SocialConnect
//
//  Created by Eric Ho on 15/4/2016.
//  Copyright © 2016 Eric Ho. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var loginButtonFacebook: UIButton!

    @IBOutlet weak var loginButtonGoogle: UIButton!
    
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var display: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //FB: integeration reference ******** please read 
        //http://www.brianjcoleman.com/tutorial-how-to-use-login-in-facebook-sdk-4-0-for-swift/
        //http://stackoverflow.com/questions/31986475/fbauth2-is-missing-from-your-info-plist-under-lsapplicationqueriesschemes-and-is
        //https://developers.facebook.com/docs/ios/ios9 (IMPORTANT)
        
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
            self.loginButtonFacebook.hidden = true
            self.loginButtonGoogle.hidden = true
            self.logoutButton.hidden = false
        }
        else
        {
            self.loginButtonFacebook.hidden = false
            self.loginButtonGoogle.hidden = false
            self.logoutButton.hidden = true
            
//            let loginView : FBSDKLoginButton = FBSDKLoginButton()
//            self.view.addSubview(loginView)
//            loginView.center = self.view.center
//            loginView.readPermissions = ["public_profile", "email", "user_friends"]
//            loginView.delegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBAction
    
    @IBAction func loginFacebookPress(sender: AnyObject) {
        let login = FBSDKLoginManager()
        login.logInWithReadPermissions(["public_profile","email"], fromViewController: self) { (loginManagerLoginResult, loginError) in
            if loginError != nil {
                print("FBLogin: \(loginError.localizedDescription)")
            } else if loginManagerLoginResult.isCancelled {
                print("FBLogin: Cancelled")
            } else {
                self.loginButtonFacebook.hidden = true
                self.loginButtonGoogle.hidden = true
                self.logoutButton.hidden = false
                self.returnUserData()
                
                if loginManagerLoginResult.declinedPermissions.count > 0 {
                    print("FBLogin: declinedPermissions")
                } else {
                    print("FBLogin: Login")
                }
            }
        }
    }
    
    @IBAction func loginGooglePress(sender: AnyObject) {
        
    }
    
    @IBAction func logoutPress(sender: AnyObject) {
        FBSDKLoginManager().logOut()
        self.display.text = ""
        self.loginButtonFacebook.hidden = false
        self.loginButtonGoogle.hidden = false
        self.logoutButton.hidden = true
    }
}

extension ViewController:FBSDKLoginButtonDelegate {
    // Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    func returnUserData()
    {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), { 
                    self.display.text = result.description
                })
//                print("fetched user: \(result)")
//                let userName : NSString = result.valueForKey("name") as! NSString
//                print("User Name is: \(userName)")
//                let userEmail : NSString = result.valueForKey("email") as! NSString
//                print("User Email is: \(userEmail)")
            }
        })
    }
    
    
}

