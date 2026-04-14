//import SwiftData
//import Foundation
//
//@Model
//class UserModel {
//    var id = UUID()
//    
//    var xp: Int = 0
//    var level: Int = 0
//    
//    var breatheSessions: [Date: Int] // дата : колличество моделей за эту дату
//    var decisionsMade: [Date: Int] // дата : колличество моделей за эту дату
//    var actionsComplete: [Date: Int] // дата : колличество моделей за эту дату
//    
//    init(id: UUID = UUID(), xp: Int, level: Int, breatheSessions: [Date : Int], decisionsMade: [Date : Int], actionsComplete: [Date : Int]) {
//        self.id = id
//        self.xp = xp
//        self.level = level
//        self.breatheSessions = breatheSessions
//        self.decisionsMade = decisionsMade
//        self.actionsComplete = actionsComplete
//    }
//}

import SwiftData
import Foundation

@Model
class UserModel {
    var id = UUID()
    
    var xp: Int = 0
    var level: Int = 0
    
    var breatheSessions: [BreathingSession]
    var decisionsMade: [DecisionModel]
    var actionsComplete: [ActionModel]
    
    init(id: UUID = UUID(), xp: Int, level: Int, breatheSessions: [BreathingSession], decisionsMade: [DecisionModel], actionsComplete: [ActionModel]) {
        self.id = id
        self.xp = xp
        self.level = level
        self.breatheSessions = breatheSessions
        self.decisionsMade = decisionsMade
        self.actionsComplete = actionsComplete
    }
}

@Model
class BreathingSession {
    var id = UUID()
    
    var isSuccessful: Bool
    var date: Date
    
    init(id: UUID = UUID(), isSuccessful: Bool, date: Date) {
        self.id = id
        self.isSuccessful = isSuccessful
        self.date = date
    }
}

@Model
class DecisionModel {
    var id = UUID()
    
    var saysYes: Bool
    var date: Date
    
    init(id: UUID = UUID(), saysYes: Bool, date: Date) {
        self.id = id
        self.saysYes = saysYes
        self.date = date
    }
}

@Model
class ActionModel {
    var id = UUID()
    
    var isComplete: Bool
    var title: String
    var date: Date
    
    init(id: UUID = UUID(), isComplete: Bool, title: String, date: Date) {
        self.id = id
        self.isComplete = isComplete
        self.title = title
        self.date = date
    }
}
