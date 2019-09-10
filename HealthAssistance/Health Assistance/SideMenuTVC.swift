//
//  SideMenuTVC.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-10-10.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class SideMenuTVC: UITableViewController {
    
    //function for log out button on table
    @IBAction func loggingOut(_ sender: UIButton) {
        performSegue(withIdentifier: "logOut", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        NotificationCenter.default.post(name: NSNotification.Name("ToggleSideMenu"), object: nil)
        
        //call observers based on table index selected
        switch indexPath.row {
            case 0: NotificationCenter.default.post(name: NSNotification.Name("createReminder"), object: nil)
            case 1: NotificationCenter.default.post(name: NSNotification.Name("viewEditReminders"), object: nil)
            case 2: NotificationCenter.default.post(name: NSNotification.Name("viewEditTasks"), object: nil)
            case 3: NotificationCenter.default.post(name: NSNotification.Name("viewAchievements"), object: nil)
            case 4: NotificationCenter.default.post(name: NSNotification.Name("customTasks"), object: nil)
            case 5: NotificationCenter.default.post(name: NSNotification.Name("editProfile"), object: nil)
            case 6: NotificationCenter.default.post(name: NSNotification.Name("pendingFriends"), object: nil)
            case 7: NotificationCenter.default.post(name: NSNotification.Name("addFriends"), object: nil)
            case 8: NotificationCenter.default.post(name: NSNotification.Name("viewFriends"), object: nil)
            case 9: NotificationCenter.default.post(name: NSNotification.Name("createGroup"), object: nil)
            case 10: NotificationCenter.default.post(name: NSNotification.Name("viewGroup"), object: nil)
            default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

}
