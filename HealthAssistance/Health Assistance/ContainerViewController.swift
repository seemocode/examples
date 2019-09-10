//
//  ContainerViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-10-10.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    @IBOutlet weak var sideConstraint: NSLayoutConstraint!
    var sideMenuOpen = false
    var userID: Int = 0 //to be passed from previous screen
    var email: String = "" //to be passed from previous screen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //print data sent from last screen
        print("Container view started")
        print(self.userID)
        print(self.email)
        
        //add observer to call toggle menu function
        NotificationCenter.default.addObserver(self, selector: #selector(toggleSideMenu), name: NSNotification.Name("ToggleSideMenu"), object: nil)
    }
    
   
    //change view constraint to show/hide side menu view
    @objc func toggleSideMenu(){
            if sideMenuOpen {
                sideMenuOpen = false
                sideConstraint.constant = -196
                
            } else {
                sideMenuOpen = true
                sideConstraint.constant = 0
            }
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
    }
    
    //pass user id and email to next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mainNavHomePage"  {
            
            if let navController = segue.destination as? UINavigationController {
                
                if let chidVC = navController.topViewController as? HomePageViewController {
                    print("in con prepare segue")
                    chidVC.email = self.email
                    chidVC.userID = self.userID
                }
            }
        }
    }

}
