//
//  CurrentRemindersViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-10-23.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit
import UserNotifications

class CurrentRemindersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UNUserNotificationCenterDelegate  {
    
    @IBOutlet weak var reminderTable: UITableView! //outlet for table on screen
    var reminderItems: NSArray = NSArray() //array for table on screen
    var itemsForDeletion: NSMutableArray = NSMutableArray()
    var deleteStarted = false
    
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var cancelButton: UIBarButtonItem! //cancel button on screen
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    //create struct to help pass reminder info in function
    struct reminderStruct: Codable {
        var weekday: String
        var time: String
        var taskID: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set delegates for tabel view
        self.reminderTable.delegate = self
        self.reminderTable.dataSource = self
        
        
        //update task table
        self.updateTableWithReminders()
 
    }

    //process delete action for reminders
    @IBAction func deleteButton(_ sender: Any) {
        if (deleteStarted == false) {
            //allow selection
            deleteStarted = true
            
            //unhide cancel button
            cancelButton.isEnabled = true
            
            //show label instrcution
            deleteLabel.isHidden = false
            
        } else {
            
            //check if array is empty
            if (itemsForDeletion.count == 0) {
                print("delete array empty")
            } else {
                //process deletion of reminders
                for i in 0 ..< self.itemsForDeletion.count {
                    
                    //delete reminder in db
                    deleteReminderInDB(rowID: itemsForDeletion[i] as! String)
                    
                    //get info needed to delete notification
                    let tmpReminderInfo = getReminderInfo(rowID: itemsForDeletion[i] as! String)
                    
                    //delete notification
                    removeNotification(weekday: tmpReminderInfo.weekday, time: tmpReminderInfo.time, taskID: tmpReminderInfo.taskID)
                }
            }
            
            //disable cancel button again
            cancelButton.isEnabled = false
            deleteStarted = false
            
            //clear array
            itemsForDeletion.removeAllObjects()
            
            //hide label instrcution
            deleteLabel.isHidden = true
            
        }
    }

    @IBAction func cancelButtonFunc(_ sender: Any) {
        cancelButton.isEnabled = false
        deleteStarted = false
        
        //clear table
        self.updateTableWithReminders()
        //clear array
        itemsForDeletion.removeAllObjects()
        
        //hide label instrcution
        deleteLabel.isHidden = true
    }
    
     //called after thread from api call is complete
    func updateTable(items: NSArray) {
        reminderItems = items
        print(reminderItems)
        self.reminderTable.reloadData()
     }
     
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return reminderItems.count
     }
     
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
     
     //selection function for table on screen
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        if (deleteStarted) {
            if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    
                    //remove row id of reminder
                    let item: UserReminders = reminderItems[indexPath.row] as! UserReminders
                    itemsForDeletion.remove(item.rowID)
                    
                } else {
                    cell.accessoryType = .checkmark
                    
                    //add rowid to deletion array
                    let item: UserReminders = reminderItems[indexPath.row] as! UserReminders
                    
                    itemsForDeletion.add(item.rowID)
                    
                }
            }

        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }

     }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        // Retrieve cell
        let cellIdentifier: String = "reminderCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
     
        // Get the reminders to be shown
        let item: UserReminders = reminderItems[indexPath.row] as! UserReminders
        
        //format info in table with spacing
        var tmpTaskName = item.taskName
        
        while (tmpTaskName.count < 25) {
            tmpTaskName = tmpTaskName + " "
        }
        
        if (globalUserStruct.clockPref == "0"){
            myCell.textLabel!.text = tmpTaskName + item.weekday + " " + item.time
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let date24 = dateFormatter.date(from: item.time)!
            
            dateFormatter.dateFormat = "h:mm a"
            let date12 = dateFormatter.string(from: date24)
            
            myCell.textLabel!.text = tmpTaskName + item.weekday + " " + date12
        }
        
        if (itemsForDeletion.contains(item.rowID)){
            //add checks
            myCell.accessoryType = .checkmark
        } else {
            //clear checks
            myCell.accessoryType = .none
        }
     
        return myCell
     }
    
    
    func updateTableWithReminders() {
        
        let urlPHPPath: String = "http://cis4250.com/getReminders.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "user=" + globalUserStruct.userID
        
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
                
                var tempRemindersArray = self.dbHelper.parseRemindersJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //sort reminders on sort if more than 1
                    if (tempRemindersArray.count > 1) {
                        
                        let temp2RemindersArray =
                            tempRemindersArray.sorted(by: {
                                if ($0 as! UserReminders).taskID != ($1 as! UserReminders).taskID  { // first, compare by last names
                                    return ($0 as! UserReminders).taskID > ($1 as! UserReminders).taskID
                                } else { // All other fields are tied, break ties by last name
                                    return self.getWeekDayNum(weekday: ($0 as! UserReminders).weekday) < self.getWeekDayNum(weekday: ($1 as! UserReminders).weekday)
                                }
                            })
                        
                        tempRemindersArray = NSMutableArray(array: temp2RemindersArray)
                        
                    }
                    
                    self.updateTable(items: tempRemindersArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    //helps to sort reminders on screen
    func getWeekDayNum(weekday: String) -> Int {
        var returnOrder = 0
        
        switch weekday {
            case "Sunday": returnOrder = 0
            case "Monday": returnOrder = 1
            case "Tuesday": returnOrder = 2
            case "Wednesday": returnOrder = 3
            case "Thursday": returnOrder = 4
            case "Friday": returnOrder = 5
            case "Saturday": returnOrder = 6
            default: returnOrder = 7
        }
        
        return returnOrder
    }
    
    //api call to delete reminders
    func deleteReminderInDB(rowID: String) {
        
        let urlPHPPath: String = "http://cis4250.com/deleteAllReminders.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "user=" + globalUserStruct.userID
        let rowIDStr = "&rowID=" + rowID
        
        let postStr = userStr + rowIDStr
        
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
                print("deleteReminderInDBData successful")
                print(data!) //shows number of bytes downloaded
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //update table
                    self.updateTableWithReminders()
                    
                })
            }
        }
        
        task.resume()
    }
    
    func removeNotification(weekday: String, time: String, taskID: String) {
        
        //set delegate
        UNUserNotificationCenter.current().delegate = self
        
        //get unique notification ID
        let formatNotificationID = taskID + weekday + time
        
         //remove notification
         UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [formatNotificationID])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //displaying the ios local notification when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    //used to get reminder info for delete
    func getReminderInfo(rowID: String) -> reminderStruct {
        
        var tmpReminder: reminderStruct = reminderStruct(weekday: "", time: " ", taskID: " ")
        
        for i in 0 ..< self.reminderItems.count {
            
            let curTask = reminderItems[i] as! UserReminders
            
            if (curTask.rowID == rowID) {
                tmpReminder.taskID = curTask.taskID
                tmpReminder.weekday = curTask.weekday
                tmpReminder.time = curTask.time
            }
            
        }
        
        return tmpReminder //return struct with info found
    }
    

}
