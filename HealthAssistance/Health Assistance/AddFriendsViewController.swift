//
//  AddFriendsViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-11.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class AddFriendsViewController: UIViewController {

    //fields on screen
    @IBOutlet weak var emailBox: UITextField!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var friendEmailLabel: UILabel!
    @IBOutlet weak var foundLabel: UILabel!
    @IBOutlet weak var addFriendsButton: UIButton!
    var allFriendsArray: NSArray = NSArray() //array to keep track of all current friends
    
    let dbHelper = JSONHandler() //database json parsing happen here
    var friendID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //load all current friends, pending and not pending
        getAllFriends()
    }

    @IBAction func searchButton(_ sender: Any) {
        
        if (emailBox.text == ""){
            //alter user email box is empty
            
            //hide labels and add button on screen
            self.friendNameLabel.isHidden = true
            self.friendEmailLabel.isHidden = true
            self.addFriendsButton.isHidden = true
            self.foundLabel.isHidden = true
            
            let alert = UIAlertController(title: "Please Try Again", message: "The email box is blank.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        getUserByEmail(email: emailBox.text!)
        
    }
    
    @IBAction func addFriendsButton(_ sender: Any) {
        
        if (self.friendID != "") {
            
            //check if friend already exists
            for i in 0 ..< self.allFriendsArray.count {
                let tmpFriend = allFriendsArray[i] as! AllFriends
                
                //friend already added or pending request exists
                if ((tmpFriend.userID == globalUserStruct.userID && tmpFriend.friendID == friendID) || (tmpFriend.userID == friendID && tmpFriend.friendID == globalUserStruct.userID)) {
                    let alert = UIAlertController(title: "Please Try Again", message: "Friend Already Exists", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
            }
            
            // Create the alert controller
            let alertController = UIAlertController(title: "Confirm Friend", message: "Would you like to add " + friendNameLabel.text! + " as a friend?", preferredStyle: .alert)
            
            // Create the actions
            let okAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) {
                UIAlertAction in
                print("Yes Pressed")
                
                //insert new friend in db
                self.insertPendingFriend()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                print ("Cancel Pressed")
            }
            
            // Add the actions
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            // Present the controller
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            let alert = UIAlertController(title: "Please Try Again", message: "No user found with that email.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func getUserByEmail(email: String) {
        let urlPHPPath: String = "http://cis4250.com/getUserByEmail.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "email=" + email
        
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
            } else {
                print("User Data downloaded")
                print(data!) //shows number of bytes downloaded
                
                let tempUserInfoArray = self.dbHelper.parseSingleUserJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to check if friend was found
                DispatchQueue.main.async(execute: { () -> Void in

                    if (tempUserInfoArray.count > 0) {
                        let parseUserInfo: SingleUserInfo = tempUserInfoArray[0] as! SingleUserInfo
                        self.friendID = parseUserInfo.userid
                        
                        //update friend info on screen
                        self.friendNameLabel.text = parseUserInfo.name
                        self.friendEmailLabel.text = parseUserInfo.email
                        
                        //unhide labels and add button on screen
                        self.friendNameLabel.isHidden = false
                        self.friendEmailLabel.isHidden = false
                        self.addFriendsButton.isHidden = false
                        self.foundLabel.isHidden = false
                        
                    } else {
                        self.friendID = ""
                        
                        //hide labels and add button on screen
                        self.friendNameLabel.isHidden = true
                        self.friendEmailLabel.isHidden = true
                        self.addFriendsButton.isHidden = true
                        self.foundLabel.isHidden = true
                        
                        let alert = UIAlertController(title: "Please Try Again", message: "No user found with that email.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                })
            }
        }
        
        task.resume()
    }
    
    func insertPendingFriend() {
        //call php api to insert new pending friend for user
        let url = URL(string: "http://cis4250.com/insertFriend.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let friendIDStr = "&friendID=" + self.friendID
        
        let postStr2 = "&accept=0"
        
        let postStr = userIDStr + friendIDStr + postStr2
        
        print(postStr) //print post string for logging purposes
        
        //create post request
        let postData = postStr.data(using: .utf8)
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("Pending Friend db call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to show success popup
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //hide labels and add button on screen
                    self.friendNameLabel.isHidden = true
                    self.friendEmailLabel.isHidden = true
                    self.addFriendsButton.isHidden = true
                    self.foundLabel.isHidden = true
                    self.emailBox.text = ""
                    
                    let alert = UIAlertController(title: "Success", message: "Pending friend request sent", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    
                })
            }
        }
        
        task.resume()
    }
    
    func getAllFriends() {
        
        let urlPHPPath: String = "http://cis4250.com/getAllFriends.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "userID=" + globalUserStruct.userID
        
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
                print(data!) //shows number of bytes downloaded
                
                let tempFriendsArray = self.dbHelper.parseAllFriendsJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //update table on screen
                    self.allFriendsArray = tempFriendsArray
                    
                })
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
