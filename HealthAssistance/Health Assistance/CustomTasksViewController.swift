//
//  CustomTasksViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-19.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class CustomTasksViewController: UIViewController {

    @IBOutlet weak var taskName: UITextField!
    @IBOutlet weak var taskDesc: UITextField!
    @IBOutlet weak var taskReminder: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func createTaskButton(_ sender: Any) {
        
        //check if any fields are empty
        if (taskName.text == "" || taskDesc.text == "" || taskReminder.text == "") {
            let alert = UIAlertController(title: "Please Try Again", message: "No fields can be be blank", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        //call php api to insert new task for user
        let url = URL(string: "http://cis4250.com/insertCustomTask.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let taskNameStr = "&taskName=" + taskName.text!
        let message1Str = "&message1=" + taskReminder.text!
        let taskDescStr = "&taskDesc=" + taskDesc.text!
        let tipsInfoStr = "&tipsInfo=" + "No Tips Available for Custom Tasks"
        
        
        let postStr = userIDStr + taskNameStr + message1Str + taskDescStr + tipsInfoStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("Custom Task API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update screen
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    let alert = UIAlertController(title: "Success", message: "Custom Task Created", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    //reset fields
                    self.taskName.text = ""
                    self.taskReminder.text = ""
                    self.taskDesc.text = ""
                    
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
