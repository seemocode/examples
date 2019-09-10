//
//  CreateReminder.swift
//  Health Assistance
//
//  Created by Daniella Drew on 2018-10-25.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit
import UserNotifications

class CreateReminder: UIViewController, UNUserNotificationCenterDelegate  {
    
    var theDates: Array<String> = Array()
    var taskID = 0
    
    var pickData: NSMutableArray = NSMutableArray()
    
    var selectedTask: String?
    var selectedTime: String?
    
    let dbHelper = JSONHandler() //parses JSON objects
    var allTasks: NSArray = NSArray() //to get task ID and messages
    
    //states of buttons selected
    var theBoolSun = false
    var theBoolMon = false
    var theBoolTue = false
    var theBoolWed = false
    var theBoolThur = false
    var theBoolFri = false
    var theBoolSat = false

    //buttons for days of week to remind
    @IBOutlet weak var sundayButton: UIButton!
    @IBAction func sunday(_ sender: UIButton) {
        if (theBoolSun == false){
            
            //change background colour
            sundayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Sunday")
            theBoolSun = true
            print(theDates)
        } else {
            //change background colour
            sundayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Sunday"}
            theBoolSun = false
            
            //print array
            print(theDates)
        }
    }
    
    @IBOutlet weak var mondayButton: UIButton!
    @IBAction func monday(_ sender: UIButton) {
        if (theBoolMon == false){
            //change background colour
            mondayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Monday")
            
            //set Boolean to true
            theBoolMon = true

            print(theDates)
        } else {
            //change background colour
            mondayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Monday"}
            
            //set boolean to false
            theBoolMon = false
            //print array
            print(theDates)
        }
    }
    
    
    @IBOutlet weak var tuesdayButton: UIButton!
    @IBAction func tuesday(_ sender: UIButton) {
        if (theBoolTue == false){
            //change background colour
            tuesdayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Tuesday")
            
            //set Boolean to true
            theBoolTue = true
            
            print(theDates)
        } else {
            //change background colour
            tuesdayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Tuesday"}
            
            //set boolean to false
            theBoolTue = false
            //print array
            print(theDates)
        }
    }
    
    @IBOutlet weak var wednesdayButton: UIButton!
    @IBAction func wednesday(_ sender: UIButton) {
        if (theBoolWed == false){
            //change background colour
            wednesdayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Wednesday")
            
            //set Boolean to true
            theBoolWed = true
            
            print(theDates)
        } else {
            //change background colour
            wednesdayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Wednesday"}
            
            //set boolean to false
            theBoolWed = false
            //print array
            print(theDates)
        }
    }
    
    @IBOutlet weak var thursdayButton: UIButton!
    @IBAction func thursday(_ sender: UIButton) {
        if (theBoolThur == false){
            //change background colour
            thursdayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Thursday")
            
            //set Boolean to true
            theBoolThur = true
            
            print(theDates)
        } else {
            //change background colour
            thursdayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Thursday"}
            
            //set boolean to false
            theBoolThur = false
            //print array
            print(theDates)
        }
    }
    
    
    
    @IBOutlet weak var fridayButton: UIButton!
    @IBAction func friday(_ sender: UIButton) {
        if (theBoolFri == false){
            //change background colour
            fridayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Friday")
            
            //set Boolean to true
            theBoolFri = true
            
            print(theDates)
        } else {
            //change background colour
            fridayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Friday"}
            
            //set boolean to false
            theBoolFri = false
            //print array
            print(theDates)
        }
    }
    
    
    @IBOutlet weak var saturdayButton: UIButton!
    @IBAction func saturday(_ sender: UIButton) {
        if (theBoolSat == false){
            //change background colour
            saturdayButton.backgroundColor = UIColor.green
            
            //add to array
            theDates.append("Saturday")
            
            //set Boolean to true
            theBoolSat = true
            
            print(theDates)
        } else {
            //change background colour
            saturdayButton.backgroundColor = UIColor.white
            
            //remove from array
            theDates = theDates.filter{$0 != "Saturday"}
            
            //set boolean to false
            theBoolSat = false
            //print array
            print(theDates)
        }
    }
    
    @IBOutlet weak var timeField: UITextField! //24 hours
    @IBOutlet weak var taskField: UITextField! //Tasks
    
    override func viewDidLoad(){
        super.viewDidLoad()
        createTaskPicker()
        createToolBar()
        
        self.getTaskTypes()
    }
    
    //creating new object
    func createTaskPicker(){
        let theTask = UIPickerView()
        //below is connecting to our extension
        theTask.delegate = self
        taskField.inputView = theTask
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        
        //show time in 12 hour format depending on user preference
        if (globalUserStruct.clockPref == "1") {
            datePicker.locale = Locale.init(identifier: "en_US")
        } else {
            datePicker.locale = Locale.init(identifier: "CA")
        }
        
        timeField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(CreateReminder.datePickerChanged(sender:)), for: .valueChanged)
    }
    
    //Allows to be printed in 24 hour format
    @objc func datePickerChanged(sender: UIDatePicker){
        
        let formatter = DateFormatter()
        
        formatter.timeStyle = .short
        
        if (globalUserStruct.clockPref == "1") {
            formatter.locale = Locale.init(identifier: "en_US")
        } else {
            formatter.locale = Locale.init(identifier: "CA")
        }
        
        timeField.text = formatter.string(for: sender.date)
        
    }
    
    //creates tool bar with Done button once selected closes the keyboard
    func createToolBar(){
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let selected = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(CreateReminder.dissmissKeyboard))
        
        toolBar.setItems([selected], animated: true)
        toolBar.isUserInteractionEnabled = true //setting to false does nothing
        
        taskField.inputAccessoryView = toolBar
        timeField.inputAccessoryView = toolBar
    }
    
    //removes keyboard
    @objc func dissmissKeyboard(){
        view.endEditing(true)
    }
    
    @IBAction func saveReminder(_ sender: UIButton) {
        
        //do a check when seeing if DB already has an existing reminder for existing task/time
        
        //get task id of the task selected
        let tmpTaskID = getTaskID(taskName: taskField.text!)
        let taskID = String(tmpTaskID)
        
        //add this so that can make post
        for theReminder in theDates {
            
            //set time to constant 24 hour format
            var tmpTime = timeField.text!
            print(tmpTime)
           
            if (globalUserStruct.clockPref == "1"){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm a"
                
                let date12 = dateFormatter.date(from: tmpTime)!
                
                //set time in 24 hour clock
                dateFormatter.dateFormat = "HH:mm:ss"
                tmpTime = dateFormatter.string(from: date12)
            } else {
                tmpTime = tmpTime + ":00"
            }
            
            //create notification
            setUpNotification(weekday: theReminder, time: tmpTime, taskID: String(taskID))
            
            let url = URL(string: "http://cis4250.com/insertReminder.php")!
        
            //format user data for post
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
        
            //create post variables
            let userStr = "user=" + globalUserStruct.userID
            //let timeStr = "&time=" + timeField.text!
            let timeStr = "&time=" + tmpTime
            //fix this so that it takes on element of array at a time
            let weekdayStr = "&weekday=" + theReminder
            let taskIDStr = "&taskID=" + String(taskID)
        
            let postStr = userStr + timeStr + weekdayStr + taskIDStr
        
            print("THIS IS CREATE REMINDER POST ==>", postStr) //print post string for logging purposes
        
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
        
        //reset all values back to original
        theBoolMon = false
        theBoolTue = false
        theBoolWed = false
        theBoolThur = false
        theBoolFri = false
        theBoolSat = false
        theBoolSun = false
        
        mondayButton.backgroundColor = UIColor.white
        tuesdayButton.backgroundColor = UIColor.white
        wednesdayButton.backgroundColor = UIColor.white
        thursdayButton.backgroundColor = UIColor.white
        fridayButton.backgroundColor = UIColor.white
        saturdayButton.backgroundColor = UIColor.white
        sundayButton.backgroundColor = UIColor.white
        
        theDates.removeAll()
        
        timeField.text = ""
        taskField.text = ""
        
        //pop up
        let alert = UIAlertController(title: "Reminder Created", message: "You have successfully created a reminder!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        }
    }

extension CreateReminder: UIPickerViewDelegate, UIPickerViewDataSource {
    
    //want to have 1 list 1 value (if you want to do date change it)
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    //number of rows we want (number of tasks in the array)
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickData.count
    }
    
    //what title of row to be? 0 --> 9
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pickData[row] as? String
    }
    
    //this is what happens when select happens
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //stores the value you chose
        selectedTask = pickData[row] as? String
        taskField.text = selectedTask
        print("%@ %@",pickData[row])
    }
    
    func setUpNotification(weekday: String, time: String, taskID: String) {
        
        //creating the notification content
        let content = UNMutableNotificationContent()
        
        //get push notification message for the reminder
        let message1 = getTaskMessage1(taskID: taskID)
        
        //adding title, body and badge
        content.title = "Hi friend"
        content.body = message1
        content.badge = 1
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE HH:mm:ss"
        
        //create and format date for notification
        let dateFormatted = weekday + " " + time
        let someDateTime = formatter.date(from: dateFormatted)
        
        print("date formatter",dateFormatted)
        
        //repeat trigger every week
        let triggerWeekly = Calendar.current.dateComponents([.weekday, .hour, .minute, .second], from: someDateTime!)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)
        
        //create unique notification ID
        let notificationID = taskID + weekday + time
        
        print("the ID",notificationID)
        //getting the notification request
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        //set delegate
        UNUserNotificationCenter.current().delegate = self
        
        //adding the notification to notification center
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    //used to get message for push notification, based on task id
    func getTaskMessage1(taskID: String) -> String {
        for i in 0 ..< self.allTasks.count {
            let curTask = allTasks[i] as! TaskTypeModel
            if (curTask.taskID == taskID) {
                return curTask.message1!
            }
        }
        return "No message found" //failed to find task
    }
    
    func getTaskID(taskName: String) -> String {
        for i in 0 ..< self.allTasks.count {
            let curTask = allTasks[i] as! TaskTypeModel
            if (curTask.taskName == taskName) {
                return curTask.taskID!
            }
        }
        return "No message found" //failed to find task
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //displaying the ios local notification when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func getTaskTypes() {
        
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
                print(tempTaskArray)
                
                //when task is complete, call method to save all task types in an array
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.allTasks = tempTaskArray
                    
                    //add tasks for picker on screen
                    for i in 0 ..< self.allTasks.count {
                        let curTask = self.allTasks[i] as! TaskTypeModel
                        self.pickData.add(curTask.taskName!)
                    }
                    
                })
            }
        }
        
        task.resume()
    }
    

}


