//
//  TipsPageViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-11-10.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class TipsPageViewController: UIViewController {
    
    var taskID: String = "" //passed from homepage controller
    let dbHelper = JSONHandler() //parses JSON objects
    var selectedTaskInfo: NSArray = NSArray() //store task info
    
    @IBOutlet weak var tipsText: UITextView! //info text on screen
    @IBOutlet weak var forTaskLabel: UILabel! //'For task..' label on screen
    @IBOutlet weak var lightbulb: UIImageView!
    @IBOutlet weak var eyesClosed: UIImageView!
    @IBOutlet weak var eyesOpen: UIImageView!
    
    //create timer for when the pet will 'blink'
    var blinkTimer: Timer!
    //create the animation for the image on screen
    var petAnimation: CAKeyframeAnimation!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("selected taskid selected: ",self.taskID)
        
        //gets task info to view on screen
        getTaskInfo()
        
        //set blink timer, default blinker
        blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(switchPetImage), userInfo: nil, repeats: true)
        
        //create line path for pet
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 150, y: 280))
        linePath.addLine(to: CGPoint(x: 250, y: 280))
        linePath.addLine(to: CGPoint(x: 150, y: 280))
        
        //set line path to the pet animation
        petAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        petAnimation.duration = 7.5
        petAnimation.repeatCount = MAXFLOAT
        petAnimation.path = linePath.cgPath
        
        //set the animations for the image layers
        lightbulb.layer.add(petAnimation, forKey: nil)
        eyesOpen.layer.add(petAnimation, forKey: nil)
        eyesClosed.layer.add(petAnimation, forKey: nil)
    }
    
    //function to call to make pet blink
    @objc func switchPetImage() {
        
        if (eyesClosed.isHidden){
            eyesClosed.isHidden = false
            eyesOpen.isHidden = true
        } else {
            eyesClosed.isHidden = true
            eyesOpen.isHidden = false
        }
    }
    
    func getTaskInfo() {
        
        let urlPHPPath: String = "http://cis4250.com/getSingleTask.php"
        
        let url: URL = URL(string: urlPHPPath)!
        
        //format data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postStr = "taskID=" + self.taskID
        print(postStr) //print post string for logging purposes
        
        //create post request
        let postData = postStr.data(using: .utf8)
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
                
                let tempTaskArray = self.dbHelper.parseTaskJSON(data!)
                print(tempTaskArray)
                
                //when task is complete, call method to save task type in an array
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //store task info
                    self.selectedTaskInfo = tempTaskArray
                    
                    //update screen info with data from db
                    let curTask = self.selectedTaskInfo[0] as! TaskTypeModel
                    
                    //fix new lines on screen
                    curTask.tipsInfo = curTask.tipsInfo!.replacingOccurrences(of: "\\n", with: "\n")

                    //update if data found
                    if (curTask.tipsInfo != ""){
                        self.tipsText.text = curTask.tipsInfo
                    }

                    self.forTaskLabel.text = "For " + curTask.taskName!
                })
            }
        }
        
        task.resume()
    }
    
    //disable rotate for view controller
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        blinkTimer.invalidate() //end timer when switching to another view controller
    }


}
