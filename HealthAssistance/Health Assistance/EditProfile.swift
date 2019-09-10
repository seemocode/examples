//
//  EditProfile.swift
//  Health Assistance
//
//  Created by Daniella Drew on 2018-10-27.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class EditProfile: UIViewController  {
    let keyData     = "66665678901234567890666656789012".data(using:String.Encoding.utf8)! //used in encryption, probably should be stored somewhere else
    
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var switchOutlet: UISwitch!
    
    //if button is selected then you can edit name
    @IBAction func editNameButton(_ sender: UIButton) {
        //textfield appears so now can enter new name
        nameField.isHidden = false
    }
    
    
    @IBOutlet weak var emailField: UITextField!
    
    
    //if button is selected then you can edit email
    @IBAction func editEmailButton(_ sender: UIButton) {
        //textfield appears so now can enter new email
        emailField.isHidden = false
    }
    
    //update DB for 12/24 hours
    @IBAction func toggleFor24(_ sender: UISwitch) {
       /* if switchOutlet.isOn {
            print("The Switch is On")
            //update preference to 0
            updateClockPref(clockPref: "0")
        } else {
            print("The Switch is Off")
            //update preference to 1
            updateClockPref(clockPref: "1")
        }*/
    }
    
    @IBOutlet weak var lockIcon01: UIImageView!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var line01: UIImageView!
    
    @IBOutlet weak var lockIcon02: UIImageView!
    @IBOutlet weak var retypeNewPassword: UITextField!
    @IBOutlet weak var line02: UIImageView!
    
    override func viewDidLoad() {
        //update clock pref on screen
        if (globalUserStruct.clockPref == "0"){
            switchOutlet.isOn = true
        } else {
            switchOutlet.isOn = false
        }

    }
    
    //if change password button is selected the fields should appear
    @IBAction func changePassword(_ sender: UIButton) {
        //first section of new password
        lockIcon01.isHidden = false
        newPassword.isHidden = false
        line01.isHidden = false
        
        //second section of new password
        lockIcon02.isHidden = false
        retypeNewPassword.isHidden = false
        line02.isHidden = false
    }
    
    
    @IBAction func saveEdits(_ sender: UIButton) {
        
        //update DB for 12/24 hours
        if switchOutlet.isOn {
            print("The Switch is On")
            //update preference to 0
            updateClockPref(clockPref: "0")
            let alert = UIAlertController(title: "Success", message: "Clock updated to 24 hour view", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            print("The Switch is Off")
            //update preference to 1
            updateClockPref(clockPref: "1")
            let alert = UIAlertController(title: "Success", message: "Clock updated to 12 hour view", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        //php for name change
        if (nameField.text != ""){
            //editName PHP
            let urlPHPPath: String = "http://cis4250.com/updateName.php"
            
            let url: URL = URL(string: urlPHPPath)!
            //format user data for post
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let userStr = "userid=" + globalUserStruct.userID
            let theName = "&name=" + nameField.text!
            
            let postString = userStr + theName
            print("Change Name Variables =", postString) //print post string for logging purposes
            
            let postData = postString.data(using: .utf8) //create post request
            request.httpBody = postData
            request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
            
            
            //dont get cached data
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            
            //start URL session
            let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
            let task = defaultSession.dataTask(with: request) { (data, response, error) in
                
                if error != nil {
                    print("Change Name ==> Failed to call API")
                    
                }else {
                    print("Change Name ==> API call successful")
                    
                    //print string returned from PHP
                    print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                }
            }
            task.resume()
            
            //reset field back to blank "" and hide filed once again
            nameField.text = ""
            nameField.isHidden = true
        }
        
        //php for 24hour clock
        
        //checks for blanks
        if (newPassword.text != "" && retypeNewPassword.text != "") {
            //php for password change
            //if passwords dont match pop up message
            if (newPassword.text == retypeNewPassword.text ){
                
                //add password logic
                let toEncrypt = newPassword.text!
                let passwordData = toEncrypt.data(using:String.Encoding.utf8)!
                
                //value, randomly generated
                let saltValue = String(arc4random_uniform(999999))
                let saltValueData = saltValue.data(using:String.Encoding.utf8)!
                
                let encryptedData = runCrypt(data:passwordData,keyData:self.keyData, ivData:saltValueData, operation:kCCEncrypt)
                
                //encryptedData as a string, to pass to db
                var strEncoded = encryptedData.base64EncodedString()
                print("STRING ENCODED", strEncoded)
                
                //fix '+' issue with php
                strEncoded = strEncoded.replacingOccurrences(of: "+", with: "%2B")
                
                //call php api to insert new user
                let url = URL(string: "http://cis4250.com/changePassword.php")!
                
                //format user data for post
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                let userid = "userid=" + globalUserStruct.userID
                let passwordStr = "&passwordHash=" + strEncoded
                let passwordSaltStr = "&passwordSalt=" + saltValue
                
                let postStr = userid + passwordStr + passwordSaltStr
                print("POST STRING is here -->", postStr)
                
                let postData = postStr.data(using: .utf8) //create post request
                request.httpBody = postData
                request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
                
                
                //dont get cached data
                let config = URLSessionConfiguration.default
                config.requestCachePolicy = .reloadIgnoringLocalCacheData
                config.urlCache = nil
                
                //start URL session
                let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
                let task = defaultSession.dataTask(with: request) { (data, response, error) in
                    
                    if error != nil {
                        print("Change Password ==> Failed to call API")
                        
                    }else {
                        print("Change Password ==> API call successful")
                        
                        //print string returned from PHP
                        print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                    }
                    
                }
                
                task.resume()
                
                //reset field back to blank "" once it has passed
                newPassword.text = ""
                retypeNewPassword.text = ""
                
                //first section of new password hidden
                lockIcon01.isHidden = true
                newPassword.isHidden = true
                line01.isHidden = true
                
                //second section of new password hidden
                lockIcon02.isHidden = true
                retypeNewPassword.isHidden = true
                line02.isHidden = true
                
                //pop up
                let alert = UIAlertController(title: "Profile Updated", message: "You have successfully updated your profile!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                
            } else {
                //error message
                print("passwords don't match")
                //add popup
                let alert = UIAlertController(title: "Error!", message: "The passwords do not match", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Try Again!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                newPassword.text = ""
                retypeNewPassword.text = ""
            }
        }
    }
    
    //deleting the account
    @IBAction func deleteAccount(_ sender: UIButton) {
        //alert
        let refreshAlert = UIAlertController(title: "Delete Your Account", message: "Are you sure you want to delete your account?", preferredStyle: UIAlertController.Style.alert)
        
        //Confirming the task is complete
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            
            //call function to run php code
            self.deleteMyAccount()
            
            //perform segue to homescreen
            //self.navigationController setNavigationBarHidden:TRUE
            //self.performSegue(withIdentifier: "deleteAcc", sender: nil)
            
        }))
        //cancelling completeing the task
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Did not delete account")
            
        }))
        present(refreshAlert, animated: true, completion: nil)
    }
    
    
    //function used for encryption and decryption
    func runCrypt(data:Data, keyData:Data, ivData:Data, operation:Int) -> Data {
        let cryptLength  = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count:cryptLength)
        
        let keyLength             = size_t(kCCKeySizeAES128)
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        
        var numBytesEncrypted :size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes {cryptBytes in
            data.withUnsafeBytes {dataBytes in
                ivData.withUnsafeBytes {ivBytes in
                    keyData.withUnsafeBytes {keyBytes in
                        CCCrypt(CCOperation(operation),
                                CCAlgorithm(kCCAlgorithmAES),
                                options,
                                keyBytes, keyLength,
                                ivBytes,
                                dataBytes, data.count,
                                cryptBytes, cryptLength,
                                &numBytesEncrypted)
                    }
                }
            }
        }
        
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
            
        } else {
            print("Error: \(cryptStatus)")
        }
        
        return cryptData;
    }

    func deleteMyAccount(){
        let urlPHPPath: String = "http://cis4250.com/deleteAccount.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userid=" + globalUserStruct.userID
        
        let postStr = userStr
        
        print(postStr)
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        
        //dont get cached data
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("deleteAccount ==> Failed to call API")
                
            }else {
                print("deleteAccount ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            //sign user out
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "initialvc") as! InitialViewController
            self.present(controller, animated: true, completion: { () -> Void in
            })
            
        })
        
        task.resume()
        
    }

    
    func updateClockPref(clockPref: String) {
        
        let urlPHPPath: String = "http://cis4250.com/updateClockPref.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let clockPrefStr = "&clockPref=" + clockPref
        
        let postStr = userStr + clockPrefStr
        print("updateClockPref Variables =", postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        
        //dont get cached data
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("updateClockPref ==> Failed to call API")
                
            }else {
                print("updateClockPref ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    //dismisses keyboard
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
