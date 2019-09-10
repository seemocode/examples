//
//  SignUpPart2ViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-15.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit
import UserNotifications

class SignUpPart2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UNUserNotificationCenterDelegate  {
    
    //Properties
    var userID: Int = 0 //to be passed from previous screen
    var email: String = "" //to be passed from previous screen
    var tableItems: NSArray = NSArray()
    var healthItemsSelected: NSMutableArray = NSMutableArray()
    @IBOutlet weak var listTableView: UITableView!
    
    //create struct to help pass time info in function
    struct defaultTimeStruct: Codable {
        var weekdayDef: String
        var timeDef: String
    }
    
    let dbHelper = JSONHandler()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates for tabel view
        self.listTableView.delegate = self
        self.listTableView.dataSource = self
        
        //print data sent from last screen
        print("sign up part 2 view started")
        print(self.userID)
        print(self.email)
        
        //does the api call to get data to display in table
        self.updateTableWithTaskTypes()
        
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        tableItems = items
        print(tableItems)
        self.listTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return tableItems.count
        
    }
    
    //function to handle selection of table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            if cell.accessoryType == .checkmark{
                cell.accessoryType = .none
                healthItemsSelected.remove(cell.textLabel!.text!)
            }
            else {
                cell.accessoryType = .checkmark
                healthItemsSelected.add(cell.textLabel!.text!)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Retrieve cell
        let cellIdentifier: String = "BasicCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // Get the tasks to be shown
        let item: TaskTypeModel = tableItems[indexPath.row] as! TaskTypeModel
        
        // Get references to labels of cell
         myCell.textLabel!.text = item.taskName
        
        if (healthItemsSelected.contains(myCell.textLabel!.text!)){
            //add checks
            myCell.accessoryType = .checkmark
        } else {
            //clear checks
            myCell.accessoryType = .none
        }
        
        return myCell
    }
    
    func updateTableWithTaskTypes() {
    
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
                print(tempTaskArray)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.updateTable(items: tempTaskArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    //used for inserts of user tasks and default reminders
    func getTaskIDFromtableItemsArray(selectedTaskName: String) -> String {
        for i in 0 ..< self.tableItems.count {
            let curTask = tableItems[i] as! TaskTypeModel
            if (curTask.taskName == selectedTaskName) {
                return curTask.taskID!
            }
        }
        return "9999" //failed to find task
    }
    
    //decide default times for tasks
    func getDefaultTimes(taskName: String) -> NSMutableArray {
        let listOfDefaults: NSMutableArray = NSMutableArray()
        
        if (taskName == "Lunch") {
            
            var tmpDefault: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Monday", timeDef:  "12:00:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Tuesday", timeDef:  "12:00:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Wednesday", timeDef:  "12:00:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Thursday", timeDef:  "12:00:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Friday", timeDef:  "12:00:00")
            listOfDefaults.add(tmpDefault)
            
        } else if (taskName == "Breakfast") {
            
            var tmpDefault: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Monday", timeDef:  "08:30:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Tuesday", timeDef:  "08:30:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Wednesday", timeDef:  "08:30:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Thursday", timeDef:  "08:30:00")
            listOfDefaults.add(tmpDefault)
            tmpDefault = defaultTimeStruct(weekdayDef: "Friday", timeDef:  "08:30:00")
            listOfDefaults.add(tmpDefault)
            
        }  else if (taskName == "Skincare") {
            
            let tmpDefault: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Sunday", timeDef:  "19:30:00")
            listOfDefaults.add(tmpDefault)
            let tmpDefault2: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Tuesday", timeDef:  "19:30:00")
            listOfDefaults.add(tmpDefault2)
            let tmpDefault3: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Thursday", timeDef:  "19:30:00")
            listOfDefaults.add(tmpDefault3)
            
        } else if (taskName == "Water Intake") {
            
            let tmpDefault: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Monday", timeDef:  "14:30:00")
            listOfDefaults.add(tmpDefault)
            let tmpDefault2: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Tuesday", timeDef:  "14:30:00")
            listOfDefaults.add(tmpDefault2)
            let tmpDefault3: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Wednesday", timeDef:  "14:30:00")
            listOfDefaults.add(tmpDefault3)
            let tmpDefault4: defaultTimeStruct = defaultTimeStruct(weekdayDef: "Thursday", timeDef:  "14:30:00")
            listOfDefaults.add(tmpDefault4)
        }
        
        return listOfDefaults
    }
    
    //create defaults reminders and set tasks based on selection, before going to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        if segue.identifier == "toHomepage" {
            if let vc2 = segue.destination as? ContainerViewController {
               
                print("setting vars in sign up part 2")
                vc2.email = self.email
                vc2.userID = self.userID
                
                for i in 0 ..< healthItemsSelected.count {
                    
                    let curTaskID = getTaskIDFromtableItemsArray(selectedTaskName: healthItemsSelected[i] as! String)
                    //check if equals 9999 later
                    
                    //create default reminders
                    let defaultReminders = getDefaultTimes(taskName: healthItemsSelected[i] as! String)
                    for j in 0 ..< defaultReminders.count {
                        //current remminder to create
                        let curReminder = defaultReminders[j] as! defaultTimeStruct
                    
                        //in DB
                        insertReminders(taskID: curTaskID,timeStruct: curReminder)
                        
                        //create notification
                        setUpNotification(weekday: curReminder.weekdayDef, time: curReminder.timeDef, taskID: curTaskID)
                    }
                   
                    //call function to insert user tasks
                    insertUserTasks(taskID: curTaskID)
                    
                } //end of for loop
                
                sleep(3) //give time for data to insert

            }
        }
    }
    
    //insert in REMINDERS table
    func insertReminders(taskID: String, timeStruct: defaultTimeStruct) {

        //call php api to insert new reminder for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/insertReminder.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        //create post variables
        let userStr = "user=" + String(self.userID)
        let timeStr = "&time=" + timeStruct.timeDef
        let weekdayStr = "&weekday=" + timeStruct.weekdayDef
        let taskIDStr = "&taskID=" + taskID
        
        let postStr = userStr + timeStr + weekdayStr + taskIDStr
        
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
            }
        }
        
        task.resume()
    }
    
    func insertUserTasks(taskID: String){
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/insertUserTasks.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + String(self.userID)
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
    
    func setUpNotification(weekday: String, time: String, taskID: String) {
        
        //creating the notification content
        let content = UNMutableNotificationContent()
        
        //get push notification message for the reminder
        let message1 = getTaskMessage(taskID: taskID)
        
        //adding title, body and badge
        content.title = "Hi friend"
        content.body = message1
        content.badge = 1
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE HH:mm:ss"
       // let someDateTime = formatter.date(from: "Saturday 16:37") //12:00:00
        let dateFormatted = weekday + " " + time
        let someDateTime = formatter.date(from: dateFormatted)
        
        //repeat trigger every week
        let triggerWeekly = Calendar.current.dateComponents([.weekday, .hour, .minute, .second], from: someDateTime!)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)
        
        //create unique notification ID
        let notificationID = taskID + weekday + time
        //getting the notification request
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        //set delegate
        UNUserNotificationCenter.current().delegate = self
        
        //adding the notification to notification center
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    //used to get message for push notification, based on task id
    func getTaskMessage(taskID: String) -> String {
        for i in 0 ..< self.tableItems.count {
            let curTask = tableItems[i] as! TaskTypeModel
            if (curTask.taskID == taskID) {
                return curTask.message1!
            }
        }
        return "No message found" //failed to find task
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //displaying the ios local notification when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }

}
