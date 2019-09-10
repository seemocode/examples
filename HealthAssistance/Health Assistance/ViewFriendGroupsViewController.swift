//
//  ViewFriendGroupsViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-19.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class ViewFriendGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var groupTable: UITableView!
    var groupArray: NSArray = NSArray() //array for table on screen
    var currentGroupSelected: String = "" //used for passing group name to next page
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    override func viewDidAppear(_ animated: Bool) {
        //update group table
        self.updateTableWithGroups()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set delegates for tabel view
        self.groupTable.delegate = self
        self.groupTable.dataSource = self
        
        //update group table
       // self.updateTableWithGroups()
        
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        groupArray = items
        self.groupTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return groupArray.count
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
        let item: Groups = groupArray[indexPath.row] as! Groups
        
        //Access UIImage
        let medalImage:UIImageView = myCell.viewWithTag(3) as! UIImageView
        medalImage.image = UIImage(named: "defaultMedal") //default image

        //decide which medal image to show
        let streakInt = Int(item.streak)
        if (streakInt! > 10){
            medalImage.image = UIImage(named: "copperMedal")
        }
        
        if (streakInt! > 25){
            medalImage.image = UIImage(named: "silverMedal")
        }
        
        if (streakInt! > 40){
            medalImage.image = UIImage(named: "goldMedal")
        }
        
        //format info in table
        myCell.textLabel!.text = item.groupName
        
        return myCell
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let curCell: Groups = groupArray[indexPath.row] as! Groups
        self.currentGroupSelected = curCell.groupName
        
        self.performSegue(withIdentifier: "viewGroupDetail", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //before seque to details page, pass current group selected
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewGroupDetail" {
            if let vc2 = segue.destination as? GroupDetailsViewController {
                vc2.currentGroupSelected = self.currentGroupSelected
            }
        }
    }
    
    //gets groups from db that the user is in =
    func updateTableWithGroups() {
        
        let urlPHPPath: String = "http://cis4250.com/getGroups.php"
        
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
                print("Data downloaded from groups")
                print(data!) //shows number of bytes downloaded
                
                let tempGroupArray = self.dbHelper.parseGroupsJSON(data!)
                
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
    
    //dismisses keyboard
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //took from signUpPart2 inserUserTask php function call
    func updateStreaks(currDate: String) {
        
        let urlPHPPath: String = "http://cis4250.com/StreakUpdate.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "currDate=" + currDate
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("THIS IS THE DATA=", data!)
                print("STREAK UPDATE call successful")
                
                //print string returned from PHP
                print("BEFORE--")
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                print("--AFTER")
            }
        }
        
        task.resume()
    }

    //this function would run every 24 hours, but for now is added to a button
    @IBAction func runStreakUpdate(_ sender: Any) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        let dateValue = formatter.string(from: date)
        print("DATE =", dateValue)
        
        
        self.updateStreaks(currDate: dateValue)
        //result is what php receives
    }
    
}
