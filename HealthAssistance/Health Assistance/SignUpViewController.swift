//
//  SignUpViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-14.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController,URLSessionDataDelegate {

    //fields on screens
    @IBOutlet weak var nameTextBox: UITextField!
    @IBOutlet weak var emailTextBox: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var retypePasswordField: UITextField!
    
    let dbHelper = JSONHandler() //class that deals with JSON parsing
    var saveUserID = 9999 //save username to pass to next screen
    let keyData     = "66665678901234567890666656789012".data(using:String.Encoding.utf8)! //used in encryption, probably should be stored somewhere else
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }

    @IBAction func nextButton(_ sender: Any) {
        
        //verify all textfields on screen are not empty
        if (nameTextBox.text! == ""){
            let alert = UIAlertController(title: "Blank Field", message: "Please enter your name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        } else if (emailTextBox.text! == ""){
            let alert = UIAlertController(title: "Blank Field", message: "Please enter an email", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
      
        //print textboxes for logging purposes
        print("name ", nameTextBox.text!)
        print("email ", emailTextBox.text!)
        
        
        //verify email does not already exist
        
        
        //verify two password fields match
        if (passwordField.text != retypePasswordField.text && passwordField.text != "" && retypePasswordField.text != ""){
            
            passwordField.text = ""
            retypePasswordField.text = ""
            
            let alert = UIAlertController(title: "Error!", message: "The passwords do not match!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Try Again!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        
            
        } else {
        
            //add password logic
            let toEncrypt = passwordField.text!
            let passwordData = toEncrypt.data(using:String.Encoding.utf8)!
            
            //iv value, randomly generated
            let saltValue = String(arc4random_uniform(999999))
            let saltValueData = saltValue.data(using:String.Encoding.utf8)!
            
            let encryptedData = runCrypt(data:passwordData,keyData:self.keyData, ivData:saltValueData, operation:kCCEncrypt)
            
            //encryptedData as a string, to pass to db
            var strEncoded = encryptedData.base64EncodedString()
            print("how its encoded",strEncoded)
            
            //fix '+' issue with php 
            strEncoded = strEncoded.replacingOccurrences(of: "+", with: "%2B")
            
            //call php api to insert new user
            let url = URL(string: "http://cis4250.com/insertNewUser.php")!
            
            //format user data for post
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let emailStr = "email=" + emailTextBox.text!
            let nameStr = "&name=" + nameTextBox.text!
            let passwordStr = "&passwordHash=" + strEncoded
            let passwordSaltStr = "&passwordSalt=" + saltValue
            
            let postStr2 = "&score=0&petNum=1&clockPref=0"
            
            let postStr = emailStr + nameStr + passwordStr + passwordSaltStr + postStr2
            
            print(postStr) //print post string for logging purposes
            
            let postData = postStr.data(using: .utf8) //create post request
            request.httpBody = postData
            
            //start URL session
            let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
            let task = defaultSession.dataTask(with: request) { (data, response, error) in
                
                if error != nil {
                    print("Failed to call API")
                    
                }else {
                    print("API call successful")
                    
                    //print string returned from PHP
                    print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                    
                    self.saveUserID = self.dbHelper.parseSingleUserID(data!)
                    
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        //confirm user created successfully
                        //maybe checking if saveUserID is not 9999 is enough
                        
                        //go to next screen when user has been created
                        self.performSegue(withIdentifier: "nextSignUp", sender: nil)
                        
                    })
                }
            }
            
            task.resume()
        }
        
    }
    
    //dismisses keyboard
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //pass email and userid to next view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "nextSignUp" {
            if let vc2 = segue.destination as? SignUpPart2ViewController {
                vc2.email = emailTextBox.text!
                vc2.userID = saveUserID
                print("setting vars")
            }
        }
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

}

//used for encryption
extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
