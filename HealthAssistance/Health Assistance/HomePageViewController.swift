//
//  HomePageViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-15.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit
import UserNotifications

struct userSettings {
    var petNum: Int
    var score: Int
    var name: String
    var email: String
    var userID: String
    var clockPref: String
    var dayBonus: String
    var numPetsUnlocked: Int
    var TASKSDONE: String
    var TASKCOUNT: String
    //maybe add more here later
}

//create global struct so that we don't have to keep passing around info between screens
var globalUserStruct: userSettings = userSettings(petNum: 1,score: 0,name: "",email: "",userID: "",clockPref: "", dayBonus: "0",numPetsUnlocked: 1,TASKSDONE: "0",TASKCOUNT: "0")

class HomePageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UNUserNotificationCenterDelegate {
    
    var userID: Int = 0 //to be passed from signin/signup screens
    var email: String = "" //to be passed from signin/signup screens
    var taskItems: NSArray = NSArray() //table on screen
    var allTasks: NSArray = NSArray() //keep all tasks in array, for ref, to avoid multiple db calls
    var currentTaskIDSelected: String = "" //used for passing task id to tips page
    
    let dbHelper = JSONHandler() //database json parsing happen here
    
    @IBOutlet weak var taskTable: UITableView! //outlet for table on screen
    @IBOutlet weak var welcomeLabel: UILabel! //welcome name, to be modifed with users name
    
    //pet images
    @IBOutlet weak var pet1OpenEyes: UIImageView!
    @IBOutlet weak var pet1Body: UIImageView!
    @IBOutlet weak var pet1ClosedEyes: UIImageView!
    @IBOutlet weak var bookBody: UIImageView!
    @IBOutlet weak var bookEyesOpen: UIImageView!
    @IBOutlet weak var bookEyesClosed: UIImageView!
    @IBOutlet weak var owlEyesOpen: UIImageView!
    @IBOutlet weak var owlEyesClosed: UIImageView!
    @IBOutlet weak var coffeeCupEyesOpen: UIImageView!
    @IBOutlet weak var coffeeCupEyesClosed: UIImageView!
    @IBOutlet weak var nofaceNoArms: UIImageView!
    @IBOutlet weak var nofaceThumb: UIImageView!
    @IBOutlet weak var sootEyesOpen: UIImageView!
    @IBOutlet weak var sootEyesClosed: UIImageView!
    
    //pet message box and label
    @IBOutlet weak var petMessageLabel: UILabel!
    @IBOutlet weak var petMessageBox: UIImageView!
    
    //create timer for when the pet will 'blink'
    var blinkTimer: Timer!
    
    //create the animations for the images on screen
    var messageAnimation: CAKeyframeAnimation!
    var petAnimation: CAKeyframeAnimation!
    
    //create tap recognizers for the pet images
    let tapRecPetBody = UITapGestureRecognizer()
    let tapRecPetEyesOpen = UITapGestureRecognizer()
    let tapRecPetEyesClosed = UITapGestureRecognizer()
    let tapRecBookBody = UITapGestureRecognizer()
    let tapRecBookEyesOpen = UITapGestureRecognizer()
    let tapRecBookEyesClosed = UITapGestureRecognizer()
    let tapRecOwlEyesOpen = UITapGestureRecognizer()
    let tapRecOwlEyesClosed = UITapGestureRecognizer()
    let tapRecCoffeeCupEyesOpen = UITapGestureRecognizer()
    let tapRecCoffeeCupEyesClosed = UITapGestureRecognizer()
    let tapRecNofaceNoArms = UITapGestureRecognizer()
    let tapRecNofaceThumb = UITapGestureRecognizer()
    let tapRecSootEyesOpen = UITapGestureRecognizer()
    let tapRecSootEyesClosed = UITapGestureRecognizer()
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //create freeform path for message box
        let miniRecPath = UIBezierPath()
        miniRecPath.move(to: CGPoint(x: 210, y: 180))
        miniRecPath.addLine(to: CGPoint(x: 250, y: 180))
        miniRecPath.addLine(to: CGPoint(x: 250, y: 190))
        miniRecPath.addLine(to: CGPoint(x: 210, y: 190))
        miniRecPath.addLine(to: CGPoint(x: 210, y: 180))
        
        //set the freefrom path to the message animation
        messageAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        messageAnimation.duration = 5
        messageAnimation.repeatCount = MAXFLOAT
        messageAnimation.path = miniRecPath.cgPath
        
        //create line path for pet
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 160, y: 280))
        linePath.addLine(to: CGPoint(x: 250, y: 280))
        linePath.addLine(to: CGPoint(x: 160, y: 280))
        
        //set line path to the pet animation
        petAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        petAnimation.duration = 7
        petAnimation.repeatCount = MAXFLOAT
        petAnimation.path = linePath.cgPath
        
        //set the animations for the image layers
        pet1ClosedEyes.layer.add(petAnimation, forKey: nil)
        pet1OpenEyes.layer.add(petAnimation, forKey: nil)
        pet1Body.layer.add(petAnimation, forKey: nil)
        bookBody.layer.add(petAnimation, forKey: nil)
        bookEyesOpen.layer.add(petAnimation, forKey: nil)
        bookEyesClosed.layer.add(petAnimation, forKey: nil)
        owlEyesOpen.layer.add(petAnimation, forKey: nil)
        owlEyesClosed.layer.add(petAnimation, forKey: nil)
        coffeeCupEyesOpen.layer.add(petAnimation, forKey: nil)
        coffeeCupEyesClosed.layer.add(petAnimation, forKey: nil)
        nofaceNoArms.layer.add(petAnimation, forKey: nil)
        nofaceThumb.layer.add(petAnimation, forKey: nil)
        sootEyesClosed.layer.add(petAnimation, forKey: nil)
        sootEyesOpen.layer.add(petAnimation, forKey: nil)
        
        //animation path for message
        petMessageLabel.layer.add(messageAnimation, forKey: nil)
        petMessageBox.layer.add(messageAnimation, forKey: nil)
        
        //update task table
        self.updateTableWithUserTasks()
        
        //update global struct
        //will also update pet on screen
        self.updateGlobalUserStruct()
        
        //get all task types in a class var, for ref
        getAllTaskTypes()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //displaying the ios local notification when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide the message box at first
        self.petMessageLabel.isHidden = true
        self.petMessageBox.isHidden = true
        
        print("home view started")
        print("userid: ", self.userID) //prints vars passed from previous screen
        print("email: ", self.email)
        
        //set global vars
        globalUserStruct.email = self.email
        globalUserStruct.userID = String(self.userID)
        
        //set delegates for tabel view
        self.taskTable.delegate = self
        self.taskTable.dataSource = self
        
        //set blink timer, default blinker
        blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(switchPet1Image), userInfo: nil, repeats: true)
        
        //set the function for the tap gestures to call
        tapRecPetBody.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecPetEyesOpen.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecPetEyesClosed.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecBookBody.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecBookEyesOpen.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecBookEyesClosed.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecOwlEyesOpen.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecOwlEyesClosed.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecCoffeeCupEyesOpen.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecCoffeeCupEyesClosed.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecNofaceNoArms.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecNofaceThumb.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecSootEyesClosed.addTarget(self, action: #selector(HomePageViewController.tapImage))
        tapRecSootEyesOpen.addTarget(self, action: #selector(HomePageViewController.tapImage))
        
        //give each pet image a tap gesture
        pet1OpenEyes.addGestureRecognizer(tapRecPetEyesOpen)
        pet1ClosedEyes.addGestureRecognizer(tapRecPetEyesClosed)
        pet1Body.addGestureRecognizer(tapRecPetBody)
        bookBody.addGestureRecognizer(tapRecBookBody)
        bookEyesOpen.addGestureRecognizer(tapRecBookEyesOpen)
        bookEyesClosed.addGestureRecognizer(tapRecBookEyesClosed)
        owlEyesClosed.addGestureRecognizer(tapRecOwlEyesClosed)
        owlEyesOpen.addGestureRecognizer(tapRecOwlEyesOpen)
        coffeeCupEyesOpen.addGestureRecognizer(tapRecCoffeeCupEyesOpen)
        coffeeCupEyesClosed.addGestureRecognizer(tapRecCoffeeCupEyesClosed)
        nofaceNoArms.addGestureRecognizer(tapRecNofaceNoArms)
        nofaceThumb.addGestureRecognizer(tapRecNofaceThumb)
        sootEyesOpen.addGestureRecognizer(tapRecSootEyesOpen)
        sootEyesClosed.addGestureRecognizer(tapRecSootEyesClosed)
        
        //moves the pet on screen, side to side, only shows on phone
        self.addParallaxToView(vw: pet1Body)
        self.addParallaxToView(vw: pet1OpenEyes)
        self.addParallaxToView(vw: pet1ClosedEyes)
        self.addParallaxToView(vw: bookBody)
        self.addParallaxToView(vw: bookEyesOpen)
        self.addParallaxToView(vw: bookEyesClosed)
        self.addParallaxToView(vw: owlEyesClosed)
        self.addParallaxToView(vw: owlEyesOpen)
        self.addParallaxToView(vw: coffeeCupEyesOpen)
        self.addParallaxToView(vw: coffeeCupEyesClosed)
        self.addParallaxToView(vw: nofaceNoArms)
        self.addParallaxToView(vw: nofaceThumb)
        self.addParallaxToView(vw: sootEyesOpen)
        self.addParallaxToView(vw: sootEyesClosed)
        
        //create observers for side menus
        NotificationCenter.default.addObserver(self,selector: #selector(showCreateReminders), name: NSNotification.Name("createReminder"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showViewEditReminders), name: NSNotification.Name("viewEditReminders"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showViewEditTasks), name: NSNotification.Name("viewEditTasks"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewAchievements), name: NSNotification.Name("viewAchievements"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(editProfile), name: NSNotification.Name("editProfile"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(customTasks), name: NSNotification.Name("customTasks"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pendingFriends), name: NSNotification.Name("pendingFriends"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addFriends), name: NSNotification.Name("addFriends"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewFriends), name: NSNotification.Name("viewFriends"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(createGroup), name: NSNotification.Name("createGroup"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewGroup), name: NSNotification.Name("viewGroup"), object: nil)
        
    }
    
    //functions for side menu segue
    @objc func showCreateReminders() {
        performSegue(withIdentifier: "createReminder", sender: nil)
    }
    
    @objc func showViewEditReminders() {
        performSegue(withIdentifier: "viewEditReminders", sender: nil)
    }
    
    @objc func showViewEditTasks() {
        performSegue(withIdentifier: "viewEditTasks", sender: nil)
    }
    
    @objc func viewAchievements() {
        performSegue(withIdentifier: "viewAchievements", sender: nil)
    }
    
    @objc func editProfile() {
        performSegue(withIdentifier: "editProfile", sender: nil)
    }
    
    @objc func customTasks() {
        performSegue(withIdentifier: "customTasks", sender: nil)
    }
    
    @objc func pendingFriends() {
        performSegue(withIdentifier: "pendingFriends", sender: nil)
    }
    
    @objc func addFriends() {
        performSegue(withIdentifier: "addFriends", sender: nil)
    }
    
    @objc func viewFriends() {
        performSegue(withIdentifier: "viewFriends", sender: nil)
    }
    
    @objc func createGroup() {
        performSegue(withIdentifier: "createGroup", sender: nil)
    }
    
    @objc func viewGroup() {
        performSegue(withIdentifier: "viewGroup", sender: nil)
    }

    //call observer to show side menu
    @IBAction func menuClicked(_ sender: Any) {
        print("SIDE MENU CLICKED")
        NotificationCenter.default.post(name: NSNotification.Name("ToggleSideMenu"), object: nil)
    }
    
    //called after thread from api call is complete
    func updateTable(items: NSArray) {
        taskItems = items
        //print(taskItems)
        self.taskTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of table items
        return taskItems.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    //selection function for table on screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
       // let cell = tableView.cellForRow(at: indexPath as IndexPath)
        
        let curCell: UserTasks = taskItems[indexPath.row] as! UserTasks
        self.currentTaskIDSelected = curCell.taskID
        
        self.performSegue(withIdentifier: "tipsSegue", sender: self)
        
    }
    
    //before seque to tips page, pass current task selected
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tipsSegue" {
            if let vc2 = segue.destination as? TipsPageViewController {
                vc2.taskID = self.currentTaskIDSelected
                print("setting vars")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Retrieve cell
        let cellIdentifier: String = "taskCell"
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        //Access UIButton
        let button1:UIButton = myCell.viewWithTag(10) as! UIButton
        //uncomplete button look
        button1.backgroundColor = .clear
        button1.layer.cornerRadius = 5
        button1.layer.borderWidth = 1
        button1.layer.borderColor = UIColor.black.cgColor
        
        // Get the tasks to be shown
        let item: UserTasks = taskItems[indexPath.row] as! UserTasks
        
        //make button look complete
        if (item.completed == "1") {
            button1.setBackgroundImage(#imageLiteral(resourceName: "checkmarkIcon"), for: .normal)
        } else {
            button1.setBackgroundImage(nil, for: .normal)
            button1.backgroundColor = .clear
            button1.layer.cornerRadius = 5
            button1.layer.borderWidth = 1
            button1.layer.borderColor = UIColor.black.cgColor
        }
        
        //view task desc from db in table on screen
        myCell.textLabel!.text = item.taskDesc
        
        return myCell
    }
    
    func updateTableWithUserTasks() {
        
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
                print("Data downloaded")
                print(data!) //shows number of bytes downloaded
                
                let tempTaskArray = self.dbHelper.parseUserTaskJSON(data!)
                //print string returned from PHP
                //print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.updateTable(items: tempTaskArray)
                    
                })
            }
        }
        
        task.resume()
    }
    
    //functions to call to make pets blink
    @objc func switchPet1Image() {
        
        if (pet1ClosedEyes.isHidden){
            pet1ClosedEyes.isHidden = false
            pet1OpenEyes.isHidden = true
        } else {
            pet1ClosedEyes.isHidden = true
            pet1OpenEyes.isHidden = false
        }
    }
    
    @objc func switchPet2Image() {
        
        if (bookEyesOpen.isHidden){
            bookEyesOpen.isHidden = false
            bookEyesClosed.isHidden = true
        } else {
            bookEyesClosed.isHidden = false
            bookEyesOpen.isHidden = true
        }
    }
    
    @objc func switchPet3Image() {
        
        if (coffeeCupEyesOpen.isHidden){
            coffeeCupEyesOpen.isHidden = false
            coffeeCupEyesClosed.isHidden = true
        } else {
            coffeeCupEyesClosed.isHidden = false
            coffeeCupEyesOpen.isHidden = true
        }
    }
    
    @objc func switchPet4Image() {
        
        if (owlEyesOpen.isHidden){
            owlEyesOpen.isHidden = false
            owlEyesClosed.isHidden = true
        } else {
            owlEyesClosed.isHidden = false
            owlEyesOpen.isHidden = true
        }
    }
    
    @objc func switchPet5Image() {
        
        if (nofaceNoArms.isHidden){
            nofaceNoArms.isHidden = false
            nofaceThumb.isHidden = true
        } else {
            nofaceThumb.isHidden = false
            nofaceNoArms.isHidden = true
        }
    }
    
    @objc func switchPet6Image() {
        
        if (sootEyesOpen.isHidden) {
            sootEyesOpen.isHidden = false
            sootEyesClosed.isHidden = true
        } else {
            sootEyesClosed.isHidden = false
            sootEyesOpen.isHidden = true
        }
    }
    
    //creates the movement of the images when the phone is tilted
    func addParallaxToView(vw: UIView) {
        let amount = 100
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
    }
    
    //called when images are tapped
    @objc func tapImage() {
        
        print("image tapped")
        
        //chose label message randomly
        let welcomeMessages: NSMutableArray = NSMutableArray()
        welcomeMessages.add("Welcome Friend")
        welcomeMessages.add("Hello Friend")
        welcomeMessages.add("Happy to see you here")
        welcomeMessages.add("Hello :)")
        welcomeMessages.add("Take care of yourself")
        welcomeMessages.add("You are important")
        let ranNum = Int(arc4random_uniform(UInt32(welcomeMessages.count)))
        
        self.petMessageLabel.text = welcomeMessages[ranNum] as? String
        
        //set message bubble to visible
        self.petMessageLabel.isHidden = false
        self.petMessageBox.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            //set message bubble to invisible after 5 secs
            self.petMessageLabel.isHidden = true
            self.petMessageBox.isHidden = true
        }
        
    }
    
    @objc func showSpecificPetMessage(message: String) {
        
        //set label message
        self.petMessageLabel.text = message
        
        //set message bubble to visible
        self.petMessageLabel.isHidden = false
        self.petMessageBox.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            //set message bubble to invisible after 5 secs
            self.petMessageLabel.isHidden = true
            self.petMessageBox.isHidden = true
        }
        
    }
    
    func updateGlobalUserStruct() {
        let urlPHPPath: String = "http://cis4250.com/getUserInfo.php"
        
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
            } else {
                print("Data downloaded")
                print(data!) //shows number of bytes downloaded
                
                let tempUserInfoArray = self.dbHelper.parseUserInfoJSON(data!)
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    let parseUserInfo: UserInfo = tempUserInfoArray[0] as! UserInfo
                    
                    globalUserStruct.name = parseUserInfo.name
                    globalUserStruct.score = Int(parseUserInfo.score)!
                    globalUserStruct.petNum = Int(parseUserInfo.petNum)!
                    globalUserStruct.clockPref = parseUserInfo.clockPref
                    globalUserStruct.dayBonus = parseUserInfo.dayBonus
                    globalUserStruct.numPetsUnlocked = Int(parseUserInfo.numPetsUnlocked)!
                    globalUserStruct.TASKCOUNT = parseUserInfo.TASKCOUNT
                    globalUserStruct.TASKSDONE = parseUserInfo.TASKSDONE
                    
                    print("global struct updated")
                    print(globalUserStruct)
                    
                    self.welcomeLabel.text = "Welcome, " + globalUserStruct.name
                    
                    //check which pet should appear on screen
                    self.updateScreenPet()
                    
                })
            }
        }
        
        task.resume()
    }
    
    func updateScreenPet() {
        //hide other pets first 
        hideOtherPets()
        
        //decide which pet to show on screen
        if (globalUserStruct.petNum == 1) {
            pet1OpenEyes.isHidden = false
            pet1Body.isHidden = false
            
            //set timer for pet blinking
             blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(switchPet1Image), userInfo: nil, repeats: true)
        } else if (globalUserStruct.petNum == 2) {
            bookBody.isHidden = false
            bookEyesOpen.isHidden = false
            
            //set new timer for pet blinking
            blinkTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(switchPet2Image), userInfo: nil, repeats: true)
        } else if (globalUserStruct.petNum == 3) {
            coffeeCupEyesOpen.isHidden = false
            
            //set new timer for pet blinking
            blinkTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(switchPet3Image), userInfo: nil, repeats: true)
        }else if (globalUserStruct.petNum == 4) {
            owlEyesOpen.isHidden = false
            
            //set new timer for pet blinking
            blinkTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(switchPet4Image), userInfo: nil, repeats: true)
        } else if (globalUserStruct.petNum == 5) {
            nofaceNoArms.isHidden = false
            
            //set new timer for pet blinking
            blinkTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(switchPet5Image), userInfo: nil, repeats: true)
        } else if (globalUserStruct.petNum == 6) {
            sootEyesOpen.isHidden = false
            
            //set new timer for pet blinking
            blinkTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(switchPet6Image), userInfo: nil, repeats: true)
        }
    }
    
    func hideOtherPets() {
        //stop timer
        blinkTimer.invalidate()
        
        //pet 1, cloud
        pet1OpenEyes.isHidden = true
        pet1ClosedEyes.isHidden = true
        pet1Body.isHidden = true

        //pet 2, book
        bookBody.isHidden = true
        bookEyesOpen.isHidden = true
        bookEyesClosed.isHidden = true
        
        //pet 3, coffee cup
        coffeeCupEyesClosed.isHidden = true
        coffeeCupEyesOpen.isHidden = true
        
        //pet 4, owl
        owlEyesClosed.isHidden = true
        owlEyesOpen.isHidden = true
        
        //pet 5, no face
        nofaceNoArms.isHidden = true
        nofaceThumb.isHidden = true
        
        //pet 6, soot
        sootEyesClosed.isHidden = true
        sootEyesOpen.isHidden = true
    
    }
    
    //called when clicking complete butto on table
    @IBAction func completeTask(_ sender: UIButton) {
        //creating alert pop up
        var theTaskValue = "String"
        var theTaskID = "9999"
        
        //get current cell
        guard let myCell = sender.superview?.superview as? UITableViewCell else {
            return
        }
        let indexPath = taskTable.indexPath(for: myCell)
        let item: UserTasks = taskItems[indexPath!.row] as! UserTasks
        
        //check if already complete
        if (item.completed == "1"){
            let alert = UIAlertController(title: "Sorry", message: "This task has already been completed", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let refreshAlert = UIAlertController(title: "Complete the Task", message: "Are you sure you want to complete this task?", preferredStyle: UIAlertController.Style.alert)
        
        //Confirming the task is complete
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            //Changing layout of button (text/background)
            sender.setTitle("",for: .normal)
            sender.setBackgroundImage(#imageLiteral(resourceName: "checkmarkIcon"), for: .normal)
            
            //getting the text value of cell "Task"
            var superView = sender.superview
            while !(superView is UITableViewCell) {
                superView = superView?.superview
            }
            let cell = superView as! UITableViewCell
            print ("HERE-->",cell.textLabel!.text as Any)
            
            //get task id for the task selected
            theTaskValue = cell.textLabel!.text!
            theTaskID = self.getTaskIDForTaskDesc(selectedTaskDesc: theTaskValue)
            
            //call api to set task to complete and update score
            self.setToComplete(theTask: theTaskID)
            self.updateScore(score: "1")
            
            //update score in global struct to determine if new pet unlocked
            globalUserStruct.score = globalUserStruct.score + 1
            
            //update number of tasks done
            var tmpTaskDoneCount = Int(globalUserStruct.TASKSDONE)!
            tmpTaskDoneCount = tmpTaskDoneCount + 1
            globalUserStruct.TASKSDONE = String(tmpTaskDoneCount)
            
            //only print process bonus once for the day, even if new task added
            if (globalUserStruct.TASKSDONE == globalUserStruct.TASKCOUNT && globalUserStruct.dayBonus != "1") {
                //give user a bonus for completing all tasks for the day
                self.updateScore(score: globalUserStruct.TASKCOUNT)
                
                //mark bonus as recieved for the day
                self.updateBonus(status: "1")
                print("adding bonus")
                
                //update score in global struct to determine if new pet unlocked
                globalUserStruct.score = globalUserStruct.score + Int(globalUserStruct.TASKCOUNT)!
                
                self.showSpecificPetMessage(message: "Congrats :) You have completed all your tasks for today")
            } else {
                self.showSpecificPetMessage(message: "Good job completing that task ")
            }
            
            //determine if new pet unlocked, if so, update db and inform user
            self.checkForNewlyUnlockedPets()
            
        }))
        //cancelling completeing the task
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Task will not be complete")
            
        }))
        present(refreshAlert, animated: true, completion: nil)
    }
    
    func setToComplete(theTask: String) {
        
        let urlPHPPath: String = "http://cis4250.com/setToComplete.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let taskStr = "&taskID=" + theTask
        
        let postString = userStr + taskStr
        print("setToComplete Variables =", postString) //print post string for logging purposes
        
        let postData = postString.data(using: .utf8) //create post request
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
                print("SetToComplete ==> Failed to call API")
                
            }else {
                print("SetToComplete ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    
    func updateScore(score: String) {
        
        let urlPHPPath: String = "http://cis4250.com/updateScore.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let addScore = "&addScore=" + score
        
        let postStr = userStr + addScore
        print("updateScore Variables =", postStr) //print post string for logging purposes
        
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
    
    func updateBonus(status: String) {
        
        let urlPHPPath: String = "http://cis4250.com/updateBonus.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let addScore = "&dayBonus=" + status
        
        let postStr = userStr + addScore
        print("updateBonus Variables =", postStr) //print post string for logging purposes
        
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
                print("updateBonus ==> Failed to call API")
                
            }else {
                print("updateBonus ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    func getTaskIDForTaskDesc(selectedTaskDesc: String) -> String {
        for i in 0 ..< self.allTasks.count {
            let curTask = allTasks[i] as! TaskTypeModel
            if (curTask.taskDesc == selectedTaskDesc) {
                return curTask.taskID!
            }
        }
        return "9999" //failed to find task
    }
    
    func getAllTaskTypes() {
        
        let urlPHPPath: String = "http://cis4250.com/getTasks.php"
        
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
                //print(tempTaskArray)
                
                //when task is complete, call method to update table
                DispatchQueue.main.async(execute: { () -> Void in
                    //update array with all tasks, to be used as reference
                    self.allTasks = tempTaskArray
                    
                })
            }
        }
        
        task.resume()
    }
    
    func updateNumOfPetsUnlocked(numUnlocked: Int) {
        
        let urlPHPPath: String = "http://cis4250.com/updateUnlockedPets.php"
        
        let url: URL = URL(string: urlPHPPath)!
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userStr = "userID=" + globalUserStruct.userID
        let addScore = "&numPetsUnlocked=" + String(numUnlocked)
        
        let postStr = userStr + addScore
        print("updateNumOfPetsUnlocked Variables =", postStr) //print post string for logging purposes
        
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
                print("updateNumOfPetsUnlocked ==> Failed to call API")
                
            }else {
                print("updateNumOfPetsUnlocked ==> API call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    
    func checkForNewlyUnlockedPets() {

        //avoid duplicate messaging by checking the number of pets unlocked
        if (globalUserStruct.score > 9 && globalUserStruct.numPetsUnlocked < 2) {
            let alert = UIAlertController(title: "Congrats!", message: "You have unlocked pet #2", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            //update num of pets unlocked, so that i don't display this message again
            updateNumOfPetsUnlocked(numUnlocked: 1)
            
            //to update current data on global struct
            globalUserStruct.numPetsUnlocked = globalUserStruct.numPetsUnlocked + 1
            print("num of pets is now: ",globalUserStruct.numPetsUnlocked)
        }
        
        if (globalUserStruct.score > 29 && globalUserStruct.numPetsUnlocked < 3) {
            let alert = UIAlertController(title: "Congrats!", message: "You have unlocked pet #3", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            //update num of pets unlocked, so that i don't display this message again
            updateNumOfPetsUnlocked(numUnlocked: 1)
            
            //to update current data on global struct
            globalUserStruct.numPetsUnlocked = globalUserStruct.numPetsUnlocked + 1
        }
        
        if (globalUserStruct.score > 49 && globalUserStruct.numPetsUnlocked < 4) {
            let alert = UIAlertController(title: "Congrats!", message: "You have unlocked pet #4", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            //update num of pets unlocked, so that i don't display this message again
            updateNumOfPetsUnlocked(numUnlocked: 1)
            
            //to update current data on global struct
            globalUserStruct.numPetsUnlocked = globalUserStruct.numPetsUnlocked + 1
        }
        
        if (globalUserStruct.score > 69 && globalUserStruct.numPetsUnlocked < 5) {
            let alert = UIAlertController(title: "Congrats!", message: "You have unlocked pet #5", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            //update num of pets unlocked, so that i don't display this message again
            updateNumOfPetsUnlocked(numUnlocked: 1)
            
            //to update current data on global struct
            globalUserStruct.numPetsUnlocked = globalUserStruct.numPetsUnlocked + 1
        }
        
        if (globalUserStruct.score > 89 && globalUserStruct.numPetsUnlocked < 6) {
            let alert = UIAlertController(title: "Congrats!", message: "You have unlocked pet #6", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            //update num of pets unlocked, so that i don't display this message again
            updateNumOfPetsUnlocked(numUnlocked: 1)
            
            //to update current data on global struct
            globalUserStruct.numPetsUnlocked = globalUserStruct.numPetsUnlocked + 1
        }
    }
    

}
