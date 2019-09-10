//
//  CreateGroupViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-19.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class CreateGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    @IBOutlet weak var friendTable: UITableView! //outlet for table on screen
    var friendsArray: NSArray = NSArray() //array for table on screen
    var friendsForAddition: NSMutableArray = NSMutableArray() //friends to include in group
    @IBOutlet weak var viewPicker: UIPickerView!
    @IBOutlet weak var groupName: UITextField!
    var pickData: NSMutableArray = NSMutableArray()
    var allTasks: NSArray = NSArray() //to get task ID
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates for tabel view
        self.friendTable.delegate = self
        self.friendTable.dataSource = self

        //update friend table
        self.updateTableWithFriends()
        
        //set delegates for view picker
        viewPicker.delegate = self
        viewPicker.dataSource = self
        
        //update view picker
        self.getTaskTypes()
        print(pickData)
       
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        friendsArray = items
        self.friendTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return friendsArray.count
    }
    
    //remove heading space from table
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Retrieve cell
        let cellIdentifier: String = "friendCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // Get the reminders to be shown
        let item: Friends = friendsArray[indexPath.row] as! Friends
        
        //format info in table
        myCell.textLabel!.text = item.name
        
        if (friendsForAddition.contains(item.userid)){
            //add checks
            myCell.accessoryType = .checkmark
        } else {
            //clear checks
            myCell.accessoryType = .none
        }
        
        return myCell
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                
                //remove user id of friend
                let item: Friends = friendsArray[indexPath.row] as! Friends
                friendsForAddition.remove(item.userid)
                
            } else {
                cell.accessoryType = .checkmark
                
                //add userid of friend to addition array
                let item: Friends = friendsArray[indexPath.row] as! Friends
                
                friendsForAddition.add(item.userid)
                
            }
        }
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pickData[row] as? String
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
    
    func getTaskTypes() {
        
        let urlPHPPath: String = "http://cis4250.com/getDefaultTasks.php"
        
        let url: URL = URL(string: urlPHPPath)!
        
        //don't get Cache Data
        var request = URLRequest(url: url)
        request.cachePolicy =  NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
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
                
                let tempTaskArray = self.dbHelper.parseTaskJSON(data!)
                
                //when task is complete, call method to save all task types in an array
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.allTasks = tempTaskArray //save tasks
                    
                    //add tasks for picker on screen
                    for i in 0 ..< tempTaskArray.count {
                        let curTask = tempTaskArray[i] as! TaskTypeModel
                        self.pickData.add(curTask.taskName!)
                    }
                    
                    //update view picker on screen
                    self.viewPicker.reloadAllComponents()
                    
                })
            }
        }
        
        task.resume()
    }
    
    //dismiss keyboard
    @objc func dissmissKeyboard(){
        view.endEditing(true)
    }
    
    @IBAction func createGroupButton(_ sender: Any) {
        
        //some error checking for empty field
        if (groupName.text == ""){
            let alert = UIAlertController(title: "Error", message: "Group Name should not be blank", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        } else if (friendsForAddition.count == 0) {
            let alert = UIAlertController(title: "Error", message: "Please select some friends", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //get selected task id
        let selectedTask = pickData[viewPicker.selectedRow(inComponent: 0)]
        let item: TaskTypeModel = allTasks[viewPicker.selectedRow(inComponent: 0)] as! TaskTypeModel
        let taskID = item.taskID
        
        print("selected: ",groupName.text!,friendsForAddition,selectedTask,taskID!)
        
        //insert user in group first
        insertFriendInGroup(groupName: groupName.text!, friendID: globalUserStruct.userID, taskID: taskID!)
        
        //loop through friends, add them to group
        for i in 0 ..< self.friendsForAddition.count {
            let curFriendID = friendsForAddition[i] as! String
            insertFriendInGroup(groupName: groupName.text!, friendID: curFriendID, taskID: taskID!)
        }
        
    }
    
    func insertFriendInGroup(groupName: String, friendID: String, taskID: String){
        //call php api to insert new pending friend for user
        let url = URL(string: "http://cis4250.com/insertFriendGroup.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        //get current date for streak date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let currentDateTime = Date()
        let streakDate = formatter.string(from: currentDateTime)
        
        let userIDStr = "userID=" + friendID
        let groupNameStr = "&groupName=" + groupName
        let taskIDStr = "&taskID=" + taskID
        let streakDateStr = "&streakDate=" + streakDate
        
        
        let postStr = userIDStr + groupNameStr + taskIDStr + streakDateStr
        
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
                print("insertFriendInGroup db call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to show success popup
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //clear screen and update table
                    self.groupName.text = ""
                    self.friendsForAddition.removeAllObjects()
                    self.friendTable.reloadData()
                    
                    //update view picker on screen
                    self.viewPicker.reloadAllComponents()
                    
                    let alert = UIAlertController(title: "Success", message: "Friend Group Created", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    
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
