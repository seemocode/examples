//
//  ViewFriendsViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-11.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class ViewFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var friendsTable: UITableView! //outlet for table on screen
    @IBOutlet weak var scoreLabel: UILabel! //shows current user's score
    var friendsArray: NSArray = NSArray() //array for table on screen
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set delegates for tabel view
        self.friendsTable.delegate = self
        self.friendsTable.dataSource = self
        
        //update friend table
        self.updateTableWithFriends()
        
        //update score on screen
        scoreLabel.text = "Your score: " + String(globalUserStruct.score)
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        friendsArray = items
        self.friendsTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return friendsArray.count
    }
    
    //remove heading space from table
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let tableItem: Friends = friendsArray[indexPath.row] as! Friends
        
        // Create the alert controller
        let alertController = UIAlertController(title: "Actions for " + tableItem.name, message: "What would you like to do?", preferredStyle: .alert)
        
        // Create the actions
        let deleteAction = UIAlertAction(title: "Delete Friend", style: UIAlertAction.Style.default) {
            UIAlertAction in
            print("Delete Pressed for ",tableItem.userid,tableItem.name )
            
            //delete friend in db
            self.deleteFriend(friendIDToDelete: tableItem.userid)
            
        }
        
        let sendMessageAction = UIAlertAction(title: "Send Message to Friend", style: UIAlertAction.Style.default) {
            UIAlertAction in
            print("Message Pressed")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            print ("Cancel Pressed")
        }
        
        // Add the actions
        alertController.addAction(cancelAction)
        alertController.addAction(sendMessageAction)
        alertController.addAction(deleteAction)
        
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Retrieve cell
        let cellIdentifier: String = "friendCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // Get the reminders to be shown
        let item: Friends = friendsArray[indexPath.row] as! Friends
        
        //format info in table
        myCell.textLabel!.text = item.name
        
        //Access UILabel on table cell
        let scoreLabel:UILabel = myCell.viewWithTag(3) as! UILabel
        scoreLabel.text = item.score
        
        return myCell
    }
    
    //gets accepted friend requests from db
    func updateTableWithFriends() {
        
        let urlPHPPath: String = "http://cis4250.com/getFriends.php"
        
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
                
                let tempFriendsArray = self.dbHelper.parseAddedFriendsJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in

                    //update table on screen
                    self.updateTable(items: tempFriendsArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    func deleteFriend(friendIDToDelete: String) {
        //call php api to insert new pending friend for user
        let url = URL(string: "http://cis4250.com/deleteFriend.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let friendIDStr = "&friendID=" + friendIDToDelete
        
        let postStr = userIDStr + friendIDStr
        
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
                print("Delete Friend db call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to show success popup
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //update friend table
                    self.updateTableWithFriends()
                    
                    let alert = UIAlertController(title: "Success", message: "Friend has been deleted", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    
                })
            }
        }
        
        task.resume()
    }


}
