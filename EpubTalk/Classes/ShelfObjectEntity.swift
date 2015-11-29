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
    @NSManaged var folder_id: String
    @NSManaged var object_id: String
    @NSManaged var name: String
    @NSManaged var sort_num: NSNumber
    @NSManaged var create_time: NSDate

    
    func trace() {
        Log(NSString(format: "***** shelf object.\n  type:%@\n  folder_id:%@\n  object_id:%@\n  name:%@\n  sort:%@\n  create_time:%@",
            self.type,
            self.folder_id,
            self.object_id,
            self.name,
            self.sort_num,
            self.create_time
        ))
    }
}
