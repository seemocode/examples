//
//  AchievementsViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-10-17.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class AchievementsViewController: UIViewController {

    //pet images, appear hidden on screen at first
    @IBOutlet weak var nofaceImage: UIImageView!
    @IBOutlet weak var owlImage: UIImageView!
    @IBOutlet weak var coffeecup: UIImageView!
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var bookEyes: UIImageView!
    @IBOutlet weak var sootBody: UIImageView!
    @IBOutlet weak var sootEyes: UIImageView!
    @IBOutlet weak var cloudEyes: UIImageView!
    @IBOutlet weak var cloudBody: UIImageView!
    
    //score label to update score on screen
    @IBOutlet weak var scoreLabel: UILabel!
    
    //question marks on screen, become hidden depending pn score
    @IBOutlet weak var QuestionMark2nd: UIImageView!
    @IBOutlet weak var questionMark3rd: UIImageView!
    @IBOutlet weak var questionMark4th: UIImageView!
    @IBOutlet weak var questionMark5th: UIImageView!
    @IBOutlet weak var questionMark6th: UIImageView!
    
    //box to show user pet selection on screen
    @IBOutlet weak var box1: UIImageView!
    @IBOutlet weak var box2: UIImageView!
    @IBOutlet weak var box3: UIImageView!
    @IBOutlet weak var box4: UIImageView!
    @IBOutlet weak var box5: UIImageView!
    @IBOutlet weak var box6: UIImageView!
    
    //create tap recognizers for the pet images
    let cloudPet1bodyTapGest = UITapGestureRecognizer()
    let cloudPet1EyesTapGest = UITapGestureRecognizer()
    let bookPet2BodyTapGest = UITapGestureRecognizer()
    let bookPet2EyesTapGest = UITapGestureRecognizer()
    let coffeeCupPet3TapGest = UITapGestureRecognizer()
    let owlPet4TapGest = UITapGestureRecognizer()
    let nofacePet5TapGest = UITapGestureRecognizer()
    let sootEyesPet6TapGest = UITapGestureRecognizer()
    let sootBodyPet6TapGest = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //if statments to decide which pets to show
        if (globalUserStruct.score > 9) {
            bookEyes.isHidden = false
            bookImage.isHidden = false
            QuestionMark2nd.isHidden = true
        }
        
        if (globalUserStruct.score > 29) {
            coffeecup.isHidden = false
            questionMark3rd.isHidden = true
        }
        
        if (globalUserStruct.score > 49) {
            owlImage.isHidden = false
            questionMark4th.isHidden = true
        }
        
        if (globalUserStruct.score > 69) {
            nofaceImage.isHidden = false
            questionMark5th.isHidden = true
        }
        
        if (globalUserStruct.score > 89) {
            sootBody.isHidden = false
            sootEyes.isHidden = false
            questionMark6th.isHidden = true
        }
        
        //set the function for the tap gestures to call
        cloudPet1bodyTapGest.addTarget(self, action:  #selector(self.pet1Selector))
        cloudPet1EyesTapGest.addTarget(self, action: #selector(self.pet1Selector))
        bookPet2BodyTapGest.addTarget(self, action: #selector(self.pet2Selector))
        bookPet2EyesTapGest.addTarget(self, action: #selector(self.pet2Selector))
        coffeeCupPet3TapGest.addTarget(self, action: #selector(self.pet3Selector))
        owlPet4TapGest.addTarget(self, action: #selector(self.pet4Selector))
        nofacePet5TapGest.addTarget(self, action: #selector(self.pet5Selector))
        sootEyesPet6TapGest.addTarget(self, action: #selector(self.pet6Selector))
        sootBodyPet6TapGest.addTarget(self, action: #selector(self.pet6Selector))
        
        //give each pet image a tap gesture
        cloudBody.addGestureRecognizer(cloudPet1bodyTapGest)
        cloudEyes.addGestureRecognizer(cloudPet1EyesTapGest)
        bookImage.addGestureRecognizer(bookPet2BodyTapGest)
        bookEyes.addGestureRecognizer(bookPet2EyesTapGest)
        coffeecup.addGestureRecognizer(coffeeCupPet3TapGest)
        owlImage.addGestureRecognizer(owlPet4TapGest)
        nofaceImage.addGestureRecognizer(nofacePet5TapGest)
        sootBody.addGestureRecognizer(sootBodyPet6TapGest)
        sootEyes.addGestureRecognizer(sootEyesPet6TapGest)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //update user score on screen
        scoreLabel.text = "Current Score: " + String(globalUserStruct.score)
        
        //show current pet selection on screen
        updateSelection(petNum: globalUserStruct.petNum)
    }
    
    //functions to handle user pet selection from tap gesture
    @objc func pet1Selector() {
        let petNum = 1
        self.updateSelection(petNum: petNum)
    }
    
    @objc func pet2Selector() {
        let petNum = 2
        self.updateSelection(petNum: petNum)
    }
    
    @objc func pet3Selector() {
        let petNum = 3
        self.updateSelection(petNum: petNum)
    }
    
    @objc func pet4Selector() {
        let petNum = 4
        self.updateSelection(petNum: petNum)
    }
    
    @objc func pet5Selector() {
        let petNum = 5
        self.updateSelection(petNum: petNum)
    }
    
    @objc func pet6Selector() {
        let petNum = 6
        self.updateSelection(petNum: petNum)
    }
    
    //update pet selection in db and global struct
    func updateSelection(petNum: Int) {
        
        //call function to hide all other boxes
        hideAllOtherSelections(petNum: petNum)
        
        //call db to update pet
        updateUserPet(petNum: petNum)
        
        //update pet in global struct
        globalUserStruct.petNum = petNum
        
        //show pet selection on screen
        /*if (petNum == 1) {
            box1.isHidden = false
        } else if (petNum == 2) {
            box2.isHidden = false
        } else if (petNum == 3) {
            box3.isHidden = false
        } else if (petNum == 4) {
            box4.isHidden = false
        } */
        
        switch petNum {
        case 1:
            box1.isHidden = false
        case 2:
            box2.isHidden = false
        case 3:
            box3.isHidden = false
        case 4:
            box4.isHidden = false
        case 5:
            box5.isHidden = false
        case 6:
            box6.isHidden = false
        default:
            return
        }
    }
    
    func hideAllOtherSelections(petNum: Int) {
        if (petNum != 1) {
            self.box1.isHidden = true
        }
        if (petNum != 2) {
            self.box2.isHidden = true
        }
        if (petNum != 3) {
            self.box3.isHidden = true
        }
        if (petNum != 4) {
            self.box4.isHidden = true
        }
        if (petNum != 5) {
            self.box5.isHidden = true
        }
        if (petNum != 6) {
            self.box6.isHidden = true
        }
    }
    
    func updateUserPet(petNum: Int) {
        //call php api to insert new task for user,based on selected focuses
        let url = URL(string: "http://cis4250.com/updateUserPet.php")!
        
        //format user data for post
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let userIDStr = "userID=" + globalUserStruct.userID
        let petNumStr = "&petNum=" + String(petNum)
        
        let postStr = userIDStr + petNumStr
        
        print(postStr) //print post string for logging purposes
        
        let postData = postStr.data(using: .utf8) //create post request
        request.httpBody = postData
        
        //start URL session
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        let task = defaultSession.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Failed to call API")
                
            }else {
                print("update USER petNum call successful")
                
                //print string returned from PHP
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
            }
        }
        
        task.resume()
    }
    


}
