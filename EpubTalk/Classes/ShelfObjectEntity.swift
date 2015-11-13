//
//  ShelfEntity.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/07.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import CoreData

enum ShelfObjectTypes: String {
    case Folder = "folder"
    case Book = "book"
}

class ShelfObjectEntity: NSManagedObject {

    @NSManaged var type: String
    @NSManaged var target_id: String
    @NSManaged var name: String
    @NSManaged var sort_num: NSNumber
    @NSManaged var create_time: NSDate

    func getBook()->BookEntity? {
        let dataManager: DataManager = DataManager.sharedInstance
        let predicate = NSPredicate(format: "book_id = %@", self.target_id)
        let results: [BookEntity]? = dataManager.find(
            DataManager.Const.kBookEntityName,
            condition: predicate,
            sort: nil,
            limit: 1
        ) as! [BookEntity]?
        
        if results == nil {
            return nil
        }
        return results!.first
    }
}
