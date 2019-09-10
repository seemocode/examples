//
//  TaskTypeModel.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-22.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

//model for database table: TASK_TYPE
class TaskTypeModel: NSObject {
    
    //object properties
    var taskID: String?
    var taskName: String?
    var message1: String?
    var taskDesc: String?
    var tipsInfo: String?
    
    //empty constructor
     override init() {
     
     }
    
    //construct with @name, @address, @latitude, and @longitude parameters
    init(taskID: String, taskName: String, message1: String, taskDesc: String, tipsInfo: String) {
        
        self.taskID = taskID
        self.taskName = taskName
        self.message1 = message1
        self.taskDesc = taskDesc
        self.tipsInfo = tipsInfo
        
    }
    
    
    //prints object's current state
    override var description: String {
        return "Task ID: \(taskID ?? "defaulttaskID"), taskName: \(taskName ?? "DefaulttaskName"), message1: \(message1 ?? "Defaultmessage1"), taskDesc: \(taskDesc ?? "DefaulttaskDesc") , tipsInfo: \(tipsInfo ?? "DefaulttipsInfo")"
        
    }
}
