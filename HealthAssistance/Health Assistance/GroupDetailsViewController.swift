//
//  GroupDetailsViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-19.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class GroupDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var currentGroupSelected: String = "" //used for passing group name from previous page
    @IBOutlet weak var groupNameTitle: UILabel!
    @IBOutlet weak var friendTable: UITableView!
    var friendArray: NSMutableArray = NSMutableArray() //array for table on screen
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var streakNumber: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    
    //create the animations for the badge image on screen
    var animation: CAKeyframeAnimation!
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates for tabel view
        self.friendTable.delegate = self
        self.friendTable.dataSource = self
        
        print("group selected",currentGroupSelected)
        
        //update friend table
        self.updateTableWithFriends()
        
        //update group name on screen
        self.groupNameTitle.text = currentGroupSelected
        
        //create circle path for the badge image
        let circlePath = UIBezierPath(arcCenter: badgeImageView.center, radius: 12, startAngle: 0, endAngle: .pi*2, clockwise: true)
        
        //set the circle path to the badge animation
        animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        animation.duration = 4
        animation.repeatCount = MAXFLOAT
        animation.path = circlePath.cgPath
        
        //set the animations for the image layers
        badgeImageView.layer.add(animation, forKey: nil)
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSMutableArray) {
        friendArray = items
        self.friendTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return friendArray.count
    }
    
    //remove heading space from table
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Retrieve cell
        let cellIdentifier: String = "groupCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // Get the reminders to be shown
        let item: GroupDetails = friendArray[indexPath.row] as! GroupDetails
        
        //change badge depending on streak number
        badgeImageView.image = UIImage(named: "defaultMedal") //default image
        streakNumber.text = item.streak
        taskLabel.text = "Task: " + item.taskName
        
        //decide which medal image to show
        let streakInt = Int(item.streak)
        if (streakInt! > 10){
            badgeImageView.image = UIImage(named: "copperMedal")
        }
        
        if (streakInt! > 25){
            badgeImageView.image = UIImage(named: "silverMedal")
        }
        
        if (streakInt! > 40){
            badgeImageView.image = UIImage(named: "goldMedal")
        }
        
        //format info in table
        myCell.textLabel!.text = item.name
        
        return myCell
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //gets accepted friend requests from db
    func updateTableWithFriends() {
        
        let urlPHPPath: String = "http://cis4250.com/getGroupDetail.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "groupName=" + currentGroupSelected
        
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
                print("Data downloaded from groups")
                print(data!) //shows number of bytes downloaded
                
                let tempGroupArray = self.dbHelper.parseGroupDetailsJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //update table on screen
                    self.updateTable(items: tempGroupArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //get task id
            let item: GroupDetails = friendArray[indexPath.row] as! GroupDetails
            let curRowID = item.rowID
            
            if (item.userID == globalUserStruct.userID) {
                //make sure user knows they about to delete themseleves from group
                // Create the alert controller
                let alertController = UIAlertController(title: "Actions for " + item.name, message: "Do you want to remove yourself from the group?", preferredStyle: .alert)
                
                // Create the actions
                let deleteAction = UIAlertAction(title: "Yes, remove me", style: UIAlertAction.Style.default) {
                    UIAlertAction in

                    //delete user from db
                    self.deleteRowIDinFriendGroup(rowID: curRowID)
                    
                    //self.friendArray.remove(item)
                    self.friendArray.removeObject(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    sleep(UInt32(0.5))
                    //go back to all group page after delete
                    self.navigationController?.popViewController(animated: true)
                    
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                    UIAlertAction in
                }
                
                // Add the actions
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
                
                // Present the controller
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                deleteRowIDinFriendGroup(rowID: curRowID)
                print(item)
                //self.friendArray.remove(item)
                friendArray.removeObject(at: indexPath.row)
                print(friendArray)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func deleteRowIDinFriendGroup(rowID: String) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/deleteFriendInGroup.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let rowIDStr = "rowID=" + rowID
        
        let postStr = rowIDStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("delete friendin group call successful")
                
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
