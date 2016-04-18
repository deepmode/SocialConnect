//
//  ViewController.swift
//  SocialConnect
//
//  Created by Eric Ho on 15/4/2016.
//  Copyright © 2016 Eric Ho. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import SwiftyJSON

class ViewController: UIViewController /*, GIDSignInUIDelegate, GIDSignInDelegate*/ {
    
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
        
        
        //FB
        if self.isLogin() {
            // User is already logged in, do work such as go to next view controller.
            self.showLoginButton(false)
        } else {
            self.showLoginButton(true)
            
//            let loginView : FBSDKLoginButton = FBSDKLoginButton()
//            self.view.addSubview(loginView)
//            loginView.center = self.view.center
//            loginView.readPermissions = ["public_profile", "email", "user_friends"]
//            loginView.delegate = self
        }
        
        
        //Google 
        //Google Sign-in
        //https://developers.google.com/identity/sign-in/ios/sign-in?configured=true&ver=swift#enable_sign-in
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isLogin() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil || GIDSignIn.sharedInstance().hasAuthInKeychain()
    }
    
    //MARK: - IBAction
    //FB
    @IBAction func loginFacebookPress(sender: AnyObject) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logInWithReadPermissions(["public_profile","email"], fromViewController: self) { (loginManagerLoginResult, loginError) in
            if loginError != nil {
                print("FBLogin: \(loginError.localizedDescription)")
            } else if loginManagerLoginResult.isCancelled {
                print("FBLogin: Cancelled")
                fbLoginManager.logOut()
            } else {
                self.showLoginButton(false)
                self.returnFBUserData()
                
                if loginManagerLoginResult.declinedPermissions.count > 0 {
                    print("FBLogin: declinedPermissions")
                } else {
                    print("FBLogin: Login")
                }
            }
        }
    }
    
    //Google
    @IBAction func loginGooglePress(sender: AnyObject) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    //FB
    @IBAction func logoutPress(sender: AnyObject) {
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        self.showLoginButton(true)
    }
    
    //FB
    @IBAction func getFBUserData(sender: AnyObject) {
        self.returnFBUserData()
    }
    
    //FB
    @IBAction func getFBIdsForBusiness(sender: AnyObject) {
        self.returnFBBusinessUserId()
    }
    
    //MARK: - button actions
    func showLoginButton(loginButtonEnable:Bool) {
        self.updateLoginButtonStatus()
        /*
        dispatch_async(dispatch_get_main_queue()) { 
            self.loginButtonFacebook.hidden = !loginButtonEnable
            self.loginButtonGoogle.hidden = !loginButtonEnable
            self.logoutButton.hidden = loginButtonEnable
            
            if loginButtonEnable {
                self.display.text = ""
            }
        } 
        */
    }
    
    func updateLoginButtonStatus() {
        let isLogin = self.isLogin()
        dispatch_async(dispatch_get_main_queue()) {
            self.loginButtonFacebook.hidden = isLogin
            self.loginButtonGoogle.hidden = isLogin
            self.logoutButton.hidden = !isLogin
            
            if !isLogin {
                self.display.text = ""
            }
        }
    }
    
    //FB
    func returnFBUserData() {
        let graphParameters = ["fields":"name,email"]
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: graphParameters)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.display.text = error.localizedDescription
                })
            } else {
                
                let jsonObj = JSON(result)
                
                /*
                let email = jsonObj["email"].string ?? ""
                let name = jsonObj["name"].string ?? ""
                let id  = jsonObj["id"].string ?? ""
                */
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.display.text = result.description
                    let tokenString = FBSDKAccessToken.currentAccessToken().tokenString
                    print("FBToken: \(tokenString)")
                })
            }
        })
    }
    
    //FB
    func returnFBBusinessUserId() {
        let graphRequest = FBSDKGraphRequest.init(graphPath: "me/ids_for_business", parameters: nil)
        graphRequest.startWithCompletionHandler { (graphRequestConnection, result, error) in
            if error != nil {
                // Process error
                print("Error: \(error)")
                dispatch_async(dispatch_get_main_queue(), { 
                    self.display.text = error.localizedDescription
                })
            } else {
                let jsonObj = JSON(result)
                
                for eachElement in jsonObj["data"].arrayValue {
                    let id = eachElement["id"].string ?? ""
                    let link = eachElement["app"]["link"].string ?? ""
                    let category = eachElement["app"]["category"].string ?? ""
                    let appId = jsonObj["data"][0]["app"]["id"].string ?? ""
                    let name = jsonObj["data"][0]["app"]["name"].string ?? ""
                    let namespace = jsonObj["data"][0]["app"]["namespace"].string ?? ""
                    
                    print("--->>>")
                    print("id: \(id)")
                    print("link: \(link)")
                    print("category: \(category)")
                    print("appId: \(appId)")
                    print("name: \(name)")
                    print("namespace: \(namespace)")
                    print("---end")
                }
                
//                let id = jsonObj["data"][0]["id"].string ?? ""
//                let link = jsonObj["data"][0]["app"]["link"].string ?? ""
//                let category = jsonObj["data"][0]["app"]["category"].string ?? ""
//                let appId = jsonObj["data"][0]["app"]["id"].string ?? ""
//                let name = jsonObj["data"][0]["app"]["name"].string ?? ""
//                let namespace = jsonObj["data"][0]["app"]["namespace"].string ?? ""
                
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.display.text = result.description
                })
            }
        }
    }
 
}

extension ViewController: GIDSignInUIDelegate {
    
    //MARK: - GIDSignInUIDelegate
}

extension ViewController: GIDSignInDelegate {
    
    //MARK: - GIDSignInDelegate
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,  withError error: NSError!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            // ...
            
            self.showLoginButton(false)
            print(user.description)
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}



extension ViewController:FBSDKLoginButtonDelegate {
    
    //MARK: - FBSDKLoginButtonDelegate
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil) {
            // Process error
        } else if result.isCancelled {
            // Handle cancellations
        } else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email") {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
}

