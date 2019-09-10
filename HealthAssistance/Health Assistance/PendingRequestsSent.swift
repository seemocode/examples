//
//  PendingRequestsSent.swift
//  Health Assistance
//
//  Created by Daniella Drew on 2018-11-20.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit


class PendingRequestsSent: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    var acceptButton = false
    var rejectButton = false
    var check = 0
    
    //Things for Sent
    @IBOutlet weak var sentTable: UITableView!
    var sentFriendsArray: NSArray = NSArray() //array for table on top
    
    
    //Things for Received
    @IBOutlet weak var receivedTable: UITableView!
    // @IBOutlet weak var receivedTable: UITableView!
    var requestFriendsArray: NSArray = NSArray() //array for table on top
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates for tabel view
        self.sentTable.delegate = self
        self.sentTable.dataSource = self
        
        //set delegates for tabel view
        self.receivedTable.delegate = self
        self.receivedTable.dataSource = self
        
        //update friend table
        self.updateTableWithFriends()
        self.updateTableWithRequests()
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        sentFriendsArray = items
        self.sentTable.reloadData()
    }
    
    func updateRequestsTable(items: NSArray){
        requestFriendsArray = items
        self.receivedTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        var count : Int?
        
        if tableView == self.sentTable{
            count = sentFriendsArray.count
        }
        if tableView == self.receivedTable{
            count = requestFriendsArray.count
            print("COUNT =", count!)
        }
        
        return count!
    }
    
    //remove heading space from table
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.sentTable{
            tableView.deselectRow(at: indexPath, animated: true)
        }
        if tableView == self.receivedTable{
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var myCell: UITableViewCell?
        
        if tableView == self.sentTable{

            myCell = tableView.dequeueReusableCell(withIdentifier: "sentCell", for: indexPath)
            let item : SentRequests = sentFriendsArray[indexPath.row] as! SentRequests
            myCell!.textLabel!.text = item.email
        }
        if tableView == self.receivedTable{
            
            myCell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath)
            let item : ReceivedRequests = requestFriendsArray[indexPath.row] as! ReceivedRequests //ReceivedRequests
            myCell!.textLabel!.text = item.email
        }

        return myCell!
    }
    
    //gets sent friend requests from db
    func updateTableWithFriends() {
        
        let urlPHPPath: String = "http://cis4250.com/PendingSent.php"
        
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
                
                let tempFriendsArray = self.dbHelper.parseSentRequestsJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                print("Friend =", self.sentFriendsArray)
                    //update table on screen
                    self.updateTable(items: tempFriendsArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    //gets sent friend requests from db
    func updateTableWithRequests() {
        
        let urlPHPPath: String = "http://cis4250.com/PendingReceived.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "userID=" + globalUserStruct.userID
        
        //let postStr = email + user + friendID + accept
        
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
                
                let tempFriendsArray = self.dbHelper.parseReceivedRequestsJSON(data!)
                
                //print string returned from PHP
                print("REQUEST RECEVIED", String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    print("REQUEST =", self.requestFriendsArray)
                    //update table on screen
                    self.updateRequestsTable(items: tempFriendsArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    func acceptedFriend(friendID: String){
        let urlPHPPath: String = "http://cis4250.com/acceptRequest.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let friendID = "&friendID=" + friendID //friendID somehow
        
        let postStr = userStr + friendID
        print("accept Friend Request =", postStr) //print post string for logging purposes
        
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
                print("updateScore ==> Failed to call API")
                
            }else {
                print("updateScore ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
            }
        }
        
        task.resume()
    }
    
    
    func addingFriend(friendID: String) {
        //call php api to insert new pending friend for user
        let url = URL(string: "http://cis4250.com/insertFriend.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let friendIDStr = "&friendID=" + friendID
        
        let postStr2 = "&accept=1"
        
        let postStr = userIDStr + friendIDStr + postStr2
        
        print("FRIEND ADDED ~~ ", postStr) //print post string for logging purposes
        
        //create post request
        let postData = postStr.data(using: .utf8)
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("updateScore ==> Failed to call API")
                
            }else {
                print("updateScore ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
            }
        }
        
        task.resume()
    }
    
    func rejectFriend(friendID: String) {
        //call php api to insert new pending friend for user
        let url = URL(string: "http://cis4250.com/rejectRequest.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let friendIDStr = "&friendID=" + friendID
        
        //let postStr2 = "&accept=1"
        
        let postStr = userIDStr + friendIDStr //+ postStr2
        
        print("FRIEND DELETED!!! ", postStr) //print post string for logging purposes
        
        //create post request
        let postData = postStr.data(using: .utf8)
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("deletion Complete ==> Failed to call API")
                
            }else {
                print("deletion Complete ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
            }
        }
        
        task.resume()
    }

    //ACCEPT Request
    @IBAction func acceptRequest(_ sender: UIButton) {
       // let friendID = ""
        let refreshAlert = UIAlertController(title: "Accept The Request", message: "Are you sure you want to accept this friend request?", preferredStyle: UIAlertController.Style.alert)
        
        //Confirming the task is complete
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            
            //get current cell
            guard let myCell = sender.superview?.superview as? UITableViewCell else {
                return
            }
            
            let indexPath = self.receivedTable.indexPath(for: myCell)
            
            let acceptFriend: ReceivedRequests = self.requestFriendsArray[indexPath!.row] as! ReceivedRequests
                
                //This is actually yourID since you are the one being added as a friend
                //changing the accept = 1, userid is friendid and friendid is your current user
                self.acceptedFriend(friendID: acceptFriend.userID)
                //adding new row to db where userID/friendID are swapped and accept = 1, userid is current user
                self.addingFriend(friendID: acceptFriend.userID)
                
                self.check = 1
                if (self.check == 1){
                    self.acceptButton = true
                    sender.isEnabled = false //only stops A from being clicked
                    sender.backgroundColor = .gray
                    self.rejectButton = true
                    
                    //disable button after accepting
                    guard let myCell = sender.superview?.superview as? UITableViewCell else {
                        return
                    }
                    
                    //Access UIButton
                    let rejectButton:UIButton = myCell.viewWithTag(11) as! UIButton
                    rejectButton.isEnabled = false
                    rejectButton.backgroundColor = .gray
                }
            //this is what i want for the next function to take
            self.check = 1
            
        }))
        
        //cancelling completeing the task
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("This Friend will not be added")
        }))
        present(refreshAlert, animated: true, completion: nil)
        
    }
    
    
    
    @IBAction func rejectRequest(_ sender: UIButton) {
        
        let refreshAlert = UIAlertController(title: "Reject The Request", message: "Are you sure you want to reject this friend request?", preferredStyle: UIAlertController.Style.alert)
        
        //Confirming the task is complete
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in

            //get current cell
            guard let myCell = sender.superview?.superview as? UITableViewCell else {
                return
            }
            
            let indexPath = self.receivedTable.indexPath(for: myCell)
            let friends: ReceivedRequests = self.requestFriendsArray[indexPath!.row] as! ReceivedRequests
                
                //remove from pending and db, userid to delete is friendid
                self.rejectFriend(friendID: friends.userID)
                
                self.check = 1
                if (self.check == 1){
                    self.rejectButton = true
                    sender.isEnabled = false //only stops A from being clicked
                    sender.backgroundColor = .gray
                    self.acceptButton = true
                    
                    //disable button after accepting
                    guard let myCell = sender.superview?.superview as? UITableViewCell else {
                        return
                    }
                    
                    //Access UIButton
                    let acceptButton:UIButton = myCell.viewWithTag(10) as! UIButton
                    acceptButton.isEnabled = false
                    acceptButton.backgroundColor = .gray
                }
                self.check = 1
            
        }))
        //cancelling completeing the task
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("This Friend will not be rejected")

        }))
        present(refreshAlert, animated: true, completion: nil)
    }
    

}
