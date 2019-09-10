//
//  AccountViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-12.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {

    let dbHelper = JSONHandler() //database json parsing happen here
    var saveUserID = 9999 //to save userid, so it can be passed to next screen
    var email: String! //passing Values variable
    let keyData     = "66665678901234567890666656789012".data(using:String.Encoding.utf8)! //used in encryption, probably should be stored somewhere else


    @IBOutlet weak var theEmail: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("sign in controller")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func processSignIn(_ sender: Any) {
        let urlPHPPath: String = "http://cis4250.com/signIn.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "email=" + theEmail.text!
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        
        //dont get cached data
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let defaultSession = Foundation.URLSession(configuration: config)
        
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to download data")
            }else {
                print("Data downloaded")
                print("sign in data: ",data!) //shows number of bytes downloaded
            
                //parse data returned from api call
                let signInInfoArray = self.dbHelper.parseSignInData(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to complete sign in process
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //check if user id was found
                    if (signInInfoArray.count == 0) {
                        
                        let alert = UIAlertController(title: "Error!", message: "There is no account registered with this email", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                    } else  { //add isEmpty after
                        
                        //use functions within sign up class
                        let signInHelper = SignUpViewController()
                        
                        //get info returned from api
                        let userTempModel = signInInfoArray[0] as! signInInfo
                       // let encryptedData2 = Data(base64Encoded: userTempModel.passwordHash)!
                        let saltValueData = userTempModel.passwordSalt.data(using:String.Encoding.utf8)!
                        
                        //update userid to pass to next screen
                        self.saveUserID = Int(userTempModel.USERID)!
                        
                        //Decrypt password from db
                       /* let decryptedData = signInHelper.runCrypt(data:encryptedData2, keyData:self.keyData, ivData:saltValueData, operation:kCCDecrypt)
                        let decrypted = String(bytes:decryptedData, encoding:String.Encoding.utf8)!
                         
                         print("password from db: ", decrypted)*/
                        
                        //encrypt password
                        let passwordData = self.passwordField.text!.data(using:String.Encoding.utf8)!
                        let encryptedData = signInHelper.runCrypt(data:passwordData,keyData:self.keyData, ivData:saltValueData, operation:kCCEncrypt)
                        //encryptedData as a string, to pass to db
                        let passwordStrEncoded = encryptedData.base64EncodedString()
                        
                        print("from screen",passwordStrEncoded)
                        
                        //see if password on screen matches password in db
                        if (userTempModel.passwordHash == passwordStrEncoded){
                            print("passwords match")
                            
                            self.performSegue(withIdentifier: "signInCheck", sender: nil)
                            print("success sign in")
                            
                            //proceed
                        } else {
                            print("passwords don't match")
                            //add popup
			    let alert = UIAlertController(title: "Error!", message: "The email or password is incorrect!", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Try Again!", style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }       
                 
                    }
                    
                    print("saved user ID from sign in:",self.saveUserID )
                })
            }
        }

        task.resume()
    }
    //PASSING DATA
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "signInCheck" {
            let nextViewController = segue.destination as! ContainerViewController
            nextViewController.email = theEmail.text!
            nextViewController.userID = self.saveUserID
        }
    }
    
    //dismisses keyboard
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    

}

