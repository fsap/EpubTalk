//
//  ShelfEntity.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/07.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import CoreData

class ShelfEntity: NSManagedObject {

    @NSManaged var shelf_id: NSNumber
    @NSManaged var name: String
    @NSManaged var sort_num: NSNumber

}
