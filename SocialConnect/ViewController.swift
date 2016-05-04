//
//  ViewController.swift
//  SocialConnect
//
//  Created by Eric Ho on 15/4/2016.
//  Copyright © 2016 Eric Ho. All rights reserved.
//

import UIKit
import FBSDKLoginKit

import Alamofire
import SwiftyJSON

struct UserCredential {
    var userID:String?
    var userPassword:String?

    init(userID:String,userPassword:String){
        self.userID = userID
        self.userPassword = userPassword
    }
}

struct HBConstants {
    static let host = "https://hypebeast.com"
    
    struct LoginPath{
        static let checkFacebook = "/login/check-facebook"
        static let checkGoogle = "/login/check-google"
        static let checkEmail = "/login_check"
        static let checkSignUp = "/register"
    }
}

class ViewController: UIViewController /*, GIDSignInUIDelegate, GIDSignInDelegate*/ {
    
    enum LoginType {
        
        typealias TokenString = String
        case Facebook(TokenString)
        case Google(TokenString)
        case HB(UserCredential)
    }
    
    
    
    var currentLoginType:LoginType?

    
    @IBOutlet weak var loginButtonFacebook: UIButton!
    @IBOutlet weak var loginButtonGoogle: UIButton!
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var logoutButton: UIButton!
    
    
    
    @IBOutlet weak var display: UITextView!
    @IBOutlet weak var accessTokenDisplay: UITextField!
    @IBOutlet weak var sessionIdDisplay: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //FB: integeration reference ******** please read 
        //http://www.brianjcoleman.com/tutorial-how-to-use-login-in-facebook-sdk-4-0-for-swift/
        //http://stackoverflow.com/questions/31986475/fbauth2-is-missing-from-your-info-plist-under-lsapplicationqueriesschemes-and-is
        //https://developers.facebook.com/docs/ios/ios9 (IMPORTANT)
        //http://stackoverflow.com/questions/32635644/default-fbsdkloginbehavior-native-not-working-on-ios-9 (Default FBSDKLoginBehavior.Native not working on iOS 9)
        
        
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
    
    //MARK: - Common helper
    
    func isLogin() -> Bool {
        if FBSDKAccessToken.currentAccessToken() != nil {
            
            let tokenString = FBSDKAccessToken.currentAccessToken().tokenString
            //---------------------------------
            self.currentLoginType = LoginType.Facebook(tokenString)
            //---------------------------------
            
            return true
        }
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            
            if let tokenString = GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken {
                //---------------------------------
                self.currentLoginType = LoginType.Google(tokenString)
                //---------------------------------
                return true
            } else {
                GIDSignIn.sharedInstance().signInSilently()
            }
        }
            
        return false
        //return FBSDKAccessToken.currentAccessToken() != nil || GIDSignIn.sharedInstance().hasAuthInKeychain()
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
                
                //---------------------------------
                //self.currentLoginType = LoginType.Facebook(loginManagerLoginResult.token.tokenString)
                self.currentLoginType = LoginType.Facebook(FBSDKAccessToken.currentAccessToken().tokenString)
                //---------------------------------
                
                dispatch_async(dispatch_get_main_queue(), { 
                    self.accessTokenDisplay.text = loginManagerLoginResult.token.tokenString
                })
                
                if loginManagerLoginResult.declinedPermissions.count > 0 {
                    print("FBLogin: declinedPermissions")
                } else {
                    print("FBLogin: Login")
                }
            }
        }
    }
    
    //HB login
    @IBAction func loginHBPress(sender: AnyObject) {
        if let userId = self.userIdTextField.text,
            let userPassword = self.passwordTextField.text {
            
            let credential = UserCredential.init(userID: userId, userPassword: userPassword)
            
            //---------------------------------
            self.currentLoginType = LoginType.HB(credential)
            //---------------------------------
            
            self.sendAccessTokenToServer(sender)
        }

        
    }
    
    //Google
    @IBAction func loginGooglePress(sender: AnyObject) {
        //GIDSignIn.sharedInstance().serverClientID = "438709611408-udbkh9caekatjl8if55n27figj35esq0.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().signIn()
    }
    
    //FB
    @IBAction func getFBAccessToken(sender: AnyObject) {
        if let tokenString = FBSDKAccessToken.currentAccessToken()?.tokenString {
            
            
            dispatch_async(dispatch_get_main_queue(), {
                self.accessTokenDisplay.text = tokenString
            })
            
            print("FB Access Token: \(tokenString)")
            self.updateDisplayText("accessToken: \(tokenString)")
        } else {
            
            dispatch_async(dispatch_get_main_queue(), {
                self.accessTokenDisplay.text = ""
            })
            self.updateDisplayText("Please login")
        }
    }
    
    //Google
    @IBAction func getGGAccessToken(sender: AnyObject) {
        
        if let authentication = GIDSignIn.sharedInstance().currentUser?.authentication {
            let idToken = authentication.idToken
            let accessToken = authentication.accessToken
            
            dispatch_async(dispatch_get_main_queue(), {
                self.accessTokenDisplay.text = accessToken
            })
            
            print("\n\nidToken: \(idToken)")
            print("\n\nGoogle assessToken: \(accessToken)")
            
            self.updateDisplayText("accessToken: \(accessToken) \n\nidToken: \(idToken)")
            
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.accessTokenDisplay.text = ""
            })
            self.updateDisplayText("Please login")
        }
        
        /*
        GIDSignIn.sharedInstance().currentUser?.authentication?.getTokensWithHandler { (authentication, error) in
            if error != nil {
                self.updateDisplayText(error.localizedDescription)
            } else {
                let idToken = authentication.idToken
                let accessToken = authentication.accessToken
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.accessTokenDisplay.text = accessToken
                })
                
                print("\n\nidToken: \(idToken)")
                print("\n\nGoogle assessToken: \(accessToken)")
                
                self.updateDisplayText("accessToken: \(accessToken) \n\nidToken: \(idToken)")
                
            }
        } */
    }
    
    
    //Google
    @IBAction func ggDisconnectPress(sender: AnyObject) {
        GIDSignIn.sharedInstance().disconnect()
        
        self.showLoginButton(true)
    }
    
    //Common
    @IBAction func logoutPress(sender: AnyObject) {
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        
        //reset the curretLoginType to nil
        self.currentLoginType = nil
        
        self.showLoginButton(true)
    }
    
    //Google
    @IBAction func getGoogleUserData(sender: AnyObject) {
        self.returnGoogleUserData()
    }
    
    //FB
    @IBAction func getFBUserData(sender: AnyObject) {
        self.returnFBUserData()
    }
    
    //FB
    @IBAction func getFBIdsForBusiness(sender: AnyObject) {
        self.returnFBBusinessUserId()
    }
    
    //Common
    @IBAction func sendAccessTokenToServer(sender: AnyObject) {
        let header:[String:String] = ["Content-Type":"application/json","Accept":"application/json"]
        self.updateDisplayText("")
        let host = HBConstants.host
        if let loginType = self.currentLoginType {
            switch loginType {
            case LoginType.Facebook(let tokenString):
                let urlString = "\(host)\(HBConstants.LoginPath.checkFacebook)?access_token=\(tokenString)"
                print("Facebook: \(urlString)")
                Alamofire.request(.GET, urlString, parameters: nil, encoding: .URL , headers:header).responseJSON { response in
                    switch response.result {
                    case .Failure(let error):
                        print("Failure")
                        self.updateDisplayText(error.localizedDescription)
                    case .Success(let returnJson):
                        print("Success")
                        let jsonObj = JSON(returnJson)
                        self.updateDisplayText(jsonObj.description)
                    }
                }
                
            case LoginType.Google(let tokenString):
                let urlString = "\(host)\(HBConstants.LoginPath.checkGoogle)?access_token=\(tokenString)"
                print("Google: \(urlString)")
                Alamofire.request(.GET, urlString, parameters: nil, encoding: .URL , headers:header).responseJSON { response in
                    switch response.result {
                    case .Failure(let error):
                        print("Failure")
                        self.updateDisplayText(error.localizedDescription)
                    case .Success(let returnJson):
                        print("Success")
                        let jsonObj = JSON(returnJson)
                        self.updateDisplayText(jsonObj.description)
                    }
                }
            case LoginType.HB(let userCredential):
                if let userId = userCredential.userID,
                    userPassword = userCredential.userPassword {
                    let urlString = "\(host)\(HBConstants.LoginPath.checkEmail)"
                    let parameters = ["_username":userId, "_password":userPassword]
                    
                    Alamofire.request(.POST, urlString, parameters: parameters, encoding: .JSON, headers:header).responseJSON { response in
                        switch response.result {
                        case .Failure(let error):
                            print("Failure")
                            self.updateDisplayText(error.localizedDescription)
                        case .Success(let returnJson):
                            print("Success")
                            let jsonObj = JSON(returnJson)
                            self.updateDisplayText(jsonObj.description)
                        }
                    }
                    
                    
                }
            } //end switch
        }
    }
    
    
    //MARK: UI update
    func showLoginButton(loginButtonEnable:Bool) {
        //self.updateLoginButtonStatus()
        
        dispatch_async(dispatch_get_main_queue()) {
            self.loginButtonFacebook.hidden = !loginButtonEnable
            self.loginButtonGoogle.hidden = !loginButtonEnable
            self.logoutButton.hidden = loginButtonEnable
            
            if loginButtonEnable {
                self.display.text = ""
                self.accessTokenDisplay.text = ""
                self.sessionIdDisplay.text = ""
            }
        }
        
    }
    
    func updateDisplayText(withText:String?) {
        if let _ = withText {
            dispatch_async(dispatch_get_main_queue()) {
                self.display.text = withText!
            }
        }
    }
    
//    func updateLoginButtonStatus() {
//        let isLogin = self.isLogin()
//        dispatch_async(dispatch_get_main_queue()) {
//            self.loginButtonFacebook.hidden = isLogin
//            self.loginButtonGoogle.hidden = isLogin
//            self.logoutButton.hidden = !isLogin
//            
//            if !isLogin {
//                self.display.text = ""
//                self.accessTokenDisplay.text = ""
//                self.sessionIdDisplay.text = ""
//            }
//        }
//    }
    
    
    
    //MARK: Google help function 
    func returnGoogleUserData() {
        if let googleUser = GIDSignIn.sharedInstance().currentUser {
            let userID = googleUser.userID
            let userProfile = googleUser.profile
            let userName = userProfile.name
            let userEmail = userProfile.email
            self.updateDisplayText("userID: \(userID), userName: \(userName), userEmail: \(userEmail)")
        } else {
            self.updateDisplayText("Please login")
        }
    }
    
    //MARK: Facebook helper function
    func returnFBUserData() {
        let graphParameters = ["fields":"name,email"]
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: graphParameters)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
                self.updateDisplayText(error.localizedDescription)
            } else {
                
                let jsonObj = JSON(result)
                
                /*
                let email = jsonObj["email"].string ?? ""
                let name = jsonObj["name"].string ?? ""
                let id  = jsonObj["id"].string ?? ""
                */
                
                self.updateDisplayText(jsonObj.description)
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
                
                self.updateDisplayText(error.localizedDescription)
                
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
                
                
                self.updateDisplayText(jsonObj.description)
            }
        }
    }
 
}

//MARK: - GIDSignInUIDelegate
extension ViewController: GIDSignInUIDelegate {
    
}

//MARK: - GIDSignInDelegate
extension ViewController: GIDSignInDelegate {
    
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,  withError error: NSError!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            let accessToken = user.authentication.accessToken
            // ...
            
            //---------------------------------
            self.currentLoginType = LoginType.Google(accessToken)
            //---------------------------------
            
            dispatch_async(dispatch_get_main_queue(), {
                self.accessTokenDisplay.text = accessToken
            })
            
            self.showLoginButton(false)
            
            let userID = user.userID
            let userProfile = user.profile
            let userName = userProfile.name
            let userEmail = userProfile.email
            
            self.updateDisplayText("userID: \(userID), userName: \(userName), userEmail: \(userEmail)")
            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


//MARK: - FBSDKLoginButtonDelegate (For Facebook login button, can be remove)
extension ViewController:FBSDKLoginButtonDelegate {
    
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

