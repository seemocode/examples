//
//  HealthFocusesViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-10-17.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class HealthFocusesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var healthTable: UITableView! //outlet for table on screen
    var tableItems: NSMutableArray = NSMutableArray() //used for table
    var currentTaskItemsSelected = NSMutableArray()
    
    let dbHelper = JSONHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates for tabel view
        self.healthTable.delegate = self
        self.healthTable.dataSource = self
        
        //know the current health focuses selected, so they can be shown as already selected
        //this will call update table after its done
        getCurrentUserTasks()
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSMutableArray) {
        tableItems = items
        //print("table for health focuses")
       // print(tableItems)
        self.healthTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return tableItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    //function to handle selection of table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                
                //get task id
                let item: TaskTypeModel = tableItems[indexPath.row] as! TaskTypeModel
                let curTaskID = getTaskIDFromtableItemsArray(selectedTaskName: item.taskName!)
                //delete task reminders in db
                deleteRemindersForTask(taskID: curTaskID)
                //delete user tasks in db
                deleteUserTask(taskID: curTaskID)
            }
            else {
                cell.accessoryType = .checkmark
                
                //get task id
                let item: TaskTypeModel = tableItems[indexPath.row] as! TaskTypeModel
                let curTaskID = getTaskIDFromtableItemsArray(selectedTaskName: item.taskName!)
                //add user task in db
                insertUserTask(taskID: curTaskID)
                
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Retrieve cell
        let cellIdentifier: String = "taskCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        //clear current checks
        myCell.accessoryType = .none
        
        // Get the tasks to be shown
        let item: TaskTypeModel = tableItems[indexPath.row] as! TaskTypeModel
        
        for i in 0 ..< self.currentTaskItemsSelected.count {
            let curTask = currentTaskItemsSelected[i] as! UserTasks
            if (curTask.taskName == item.taskName) {
               //show check mark, for already selected
               // print("checking",curTask.taskName )
                myCell.accessoryType = .checkmark
            }
        }
        
        // Get references to labels of cell
        myCell.textLabel!.text = item.taskName
        
        return myCell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //get task id
            let item: TaskTypeModel = tableItems[indexPath.row] as! TaskTypeModel
            let curTaskID = getTaskIDFromtableItemsArray(selectedTaskName: item.taskName!)
            let intTask = Int(curTaskID)
            
            if (intTask! <= 16) {
                let alert = UIAlertController(title: "Error", message: "Cannot delete default tasks", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }else {
                //delete task reminders in db
                deleteRemindersForTask(taskID: curTaskID)
                //delete user tasks in db
                deleteUserTask(taskID: curTaskID)
                sleep(1) //give time for data to delete
                //delete task type in db
                deleteTaskType(taskID: curTaskID)
                
                self.tableItems.remove(item)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func getTaskIDFromtableItemsArray(selectedTaskName: String) -> String {
        for i in 0 ..< self.tableItems.count {
            let curTask = tableItems[i] as! TaskTypeModel
            if (curTask.taskName == selectedTaskName) {
                return curTask.taskID!
            }
        }
        return "9999" //failed to find task
    }
    
    func updateTableWithTaskTypes() {
        
        let urlPHPPath: String = "http://cis4250.com/getAllUserTaskTypes.php"
        
        let url: URL = URL(string: urlPHPPath)!
        
        //don't get Cache Data
        var request = URLRequest(url: url)
        request.cachePolicy =  NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        //format user data for post
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        
        let postStr = userIDStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        let defaultSession = Foundation.URLSession(configuration: config)
        
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to download data")
            }else {
                print("Data downloaded")
                print(data!) //shows number of bytes downloaded
                
                let tempTaskArray = self.dbHelper.parseTaskJSON(data!)
                //print(tempTaskArray)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.updateTable(items: tempTaskArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    func insertUserTask(taskID: String) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/insertUserTasks.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let taskIDStr = "&taskID=" + taskID
        
        let postStr2 = "&completed=0"
        
        let postStr = userIDStr + taskIDStr + postStr2
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("USER TASK API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    func deleteUserTask(taskID: String) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/deleteUserTask.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let taskIDStr = "&taskID=" + taskID
        
        let postStr = userIDStr + taskIDStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("USER TASK API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    func getCurrentUserTasks() {
        
        let urlPHPPath: String = "http://cis4250.com/getUserTasks.php"
        
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
                print("user task Data downloaded")
                print(data!) //shows number of bytes downloaded
                
                let tempTaskArray = self.dbHelper.parseUserTaskJSON(data!)
                //print string returned from PHP
                //print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.currentTaskItemsSelected = tempTaskArray
                    
                    //does the api call to get data to display in table
                    self.updateTableWithTaskTypes()
                    
                })
            }
        }
        
        task.resume()
    }
    
    func deleteRemindersForTask(taskID: String) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/deleteTaskReminders.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let taskIDStr = "&taskID=" + taskID
        
        let postStr = userIDStr + taskIDStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("USER TASK API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    func deleteTaskType(taskID: String) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/deleteTaskType.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let taskIDStr = "taskID=" + taskID
        
        let postStr = taskIDStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("USER TASK API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }

}
