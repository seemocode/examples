//
//  DatabaseAPI.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-22.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit
import Foundation


//structs to decode JSON objects
struct TaskType: Codable {
    let taskID: String
    let taskName: String
    let message1: String
    let taskDesc: String
    let tipsInfo: String
}

struct singleUSERID: Codable {
    let USERID: String
}

struct signInInfo: Codable {
    let USERID: String
    let passwordHash: String
    let passwordSalt: String
}

struct UserTasks: Codable {
    let taskID: String
    let taskName: String
    let message1: String
    let taskDesc: String
    let completed: String
}

struct UserInfo: Codable {
    let name: String
    let email: String
    let score: String
    let petNum: String
    let clockPref: String
    let dayBonus: String
    let numPetsUnlocked: String
    let TASKCOUNT: String
    let TASKSDONE: String
}

struct SingleUserInfo: Codable {
    let userid: String
    let email: String
    let name: String
}

struct UserReminders: Codable {
    let rowID: String
    let time: String
    let weekday: String
    let taskID: String
    let taskName: String
}

struct Friends: Codable {
    let userid: String
    let name: String
    let score: String
    let email: String
}

struct AllFriends: Codable {
    let userID: String
    let friendID: String
    let accept: String
}

struct Groups: Codable {
    let groupName: String
    let streak: String
    let userID: String
    let taskID: String
    let dayComplete: String
}

struct GroupDetails: Codable {
    let rowID: String
    let groupName: String
    let streak: String
    let userID: String
    let taskID: String
    let dayComplete: String
    let name: String
    let taskName: String
}

//MODIFIED
struct SentRequests: Codable {
    let email : String
}

struct ReceivedRequests: Codable {
    let email : String
    let userID : String
    let friendID : String
    let accept : String
}

class JSONHandler: NSObject , URLSessionDataDelegate {
    
    //used when only the userid is return from PHP, has to be returned in JSON as USERID
    func parseSingleUserID(_ data:Data) -> Int {
        var userID = 9999
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([singleUSERID].self, from: data) //Decode JSON data based on struct
            print(model)
            
            if (model.count > 0){
                userID = Int(model[0].USERID)! //because php will return array, as a string
            }
            
        } catch let parsingError {
            print("Error", parsingError)
            userID = 9999 //to know to ignore it
        }
        
        //returns array of location model classes
        return userID
    }
    
    //parses task JSON, returns array of all tasks
    func parseTaskJSON(_ data:Data) -> NSMutableArray {
        
        let tasks = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([TaskType].self, from: data) //Decode JSON Response Data based on struct
            //print(model)
            
            //loop through structs to create model classes
            for i in 0 ..< model.count {
                
                let singleTask = TaskTypeModel(taskID: model[i].taskID,taskName: model[i].taskName,message1: model[i].message1,taskDesc: model[i].taskDesc, tipsInfo: model[i].tipsInfo)
                
                tasks.add(singleTask)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of task model classes
        return tasks
    }
    
    //parses user task JSON, returns array of all tasks assigned to the user
    func parseUserTaskJSON(_ data:Data) -> NSMutableArray {
        
        let tasks = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([UserTasks].self, from: data) //Decode JSON Response Data based on struct
            //print(model)
            
            //loop through structs to create model classes
            for i in 0 ..< model.count {
                
                let singleTask = UserTasks(taskID: model[i].taskID,taskName: model[i].taskName,message1: model[i].message1,taskDesc: model[i].taskDesc,completed: model[i].completed)
                
                tasks.add(singleTask)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user task model classes
        return tasks
    }
    
    //parses user info JSON, returns user info for user global struct, in form of array
    func parseUserInfoJSON(_ data:Data) -> NSMutableArray {
        
        let userData = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([UserInfo].self, from: data) //Decode JSON Response Data based on struct
            print(model)
            
            //loop through structs to create model classes
            for i in 0 ..< model.count {
                
                let singleUserInfo = UserInfo(name: model[i].name,email: model[i].email,score: model[i].score,petNum: model[i].petNum, clockPref: model[i].clockPref, dayBonus: model[i].dayBonus,numPetsUnlocked: model[i].numPetsUnlocked, TASKCOUNT: model[i].TASKCOUNT,TASKSDONE: model[i].TASKSDONE)
                
                userData.add(singleUserInfo)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user task model classes
        return userData
    }
    
    //used when only the userid is return from PHP, has to be returned in JSON as USERID
    func parseSignInData(_ data:Data) -> NSMutableArray {

        let userData = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([signInInfo].self, from: data) //Decode JSON data based on struct
            print(model)
            
            if (model.count > 0){
                userData.add(model[0])
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of location model classes
        return userData
    }
    
    //parses the JSON that holds the reminders for the user, returns array of all reminders for the user
    func parseRemindersJSON(_ data:Data) -> NSMutableArray {
        
        let reminders = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([UserReminders].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let singleReminder = UserReminders(rowID: model[i].rowID,time: model[i].time,weekday: model[i].weekday,taskID:  model[i].taskID, taskName: model[i].taskName)
                
                reminders.add(singleReminder)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user reminder models
        return reminders
    }
    
    //parses JSON for add friend page
    func parseSingleUserJSON(_ data:Data) -> NSMutableArray {
        
        let user = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([SingleUserInfo].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create model classes
            for i in 0 ..< model.count {
                
                let singleTask = SingleUserInfo(userid: model[i].userid,email: model[i].email,name: model[i].name)
                
                user.add(singleTask)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of task model classes
        return user
    }
    
    //parses the JSON that holds the friends for the user, returns array of all friends for the user
    func parseAddedFriendsJSON(_ data:Data) -> NSMutableArray {
        
        let friends = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([Friends].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let singleFriend = Friends(userid: model[i].userid,name: model[i].name,score: model[i].score,email: model[i].email)
                
                friends.add(singleFriend)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user reminder models
        return friends
    }
    
    //parses the JSON that holds the friends for the user, returns array of all friends for the user
    func parseAllFriendsJSON(_ data:Data) -> NSMutableArray {
        
        let friends = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([AllFriends].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let singleFriend = AllFriends(userID: model[i].userID,friendID: model[i].friendID,accept: model[i].accept)
                
                friends.add(singleFriend)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user reminder models
        return friends
    }
    
    //parses the JSON that holds the groups for the user, returns array of all groups for the user
    func parseGroupsJSON(_ data:Data) -> NSMutableArray {
        
        let groups = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([Groups].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let singleGroup = Groups(groupName: model[i].groupName,streak: model[i].streak,userID: model[i].userID, taskID: model[i].taskID, dayComplete: model[i].dayComplete)
                
                groups.add(singleGroup)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user reminder models
        return groups
    }
    
    //parses the JSON that holds the groups for the user, returns array of all groups for the user
    func parseGroupDetailsJSON(_ data:Data) -> NSMutableArray {
        
        let groups = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([GroupDetails].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let singleGroup = GroupDetails(rowID: model[i].rowID, groupName: model[i].groupName,streak: model[i].streak,userID: model[i].userID, taskID: model[i].taskID, dayComplete: model[i].dayComplete, name: model[i].name, taskName: model[i].taskName)
                
                groups.add(singleGroup)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of user reminder models
        return groups
    }

    func parseSentRequestsJSON(_ data:Data) -> NSMutableArray {
        
        let requests = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([SentRequests].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let sentReq = SentRequests(email: model[i].email)
                
                requests.add(sentReq)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of requests
        return requests
    }
    
    func parseReceivedRequestsJSON(_ data:Data) -> NSMutableArray {
        
        let requests = NSMutableArray()
        
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode([ReceivedRequests].self, from: data) //Decode JSON Response Data based on struct
            
            //loop through structs to create models in an array
            for i in 0 ..< model.count {
                
                let recReq = ReceivedRequests(email: model[i].email,userID: model[i].userID,friendID: model[i].friendID,accept: model[i].accept)
                
                requests.add(recReq)
                
            }
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        //returns array of requests
        return requests
    }
    

}
