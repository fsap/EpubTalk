//
//  BookEntity.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/07.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import CoreData

class BookEntity: NSManagedObject {

    @NSManaged var book_id: NSNumber
    @NSManaged var creator: String
    @NSManaged var date: NSDate
    @NSManaged var filename: String
    @NSManaged var filesize: NSNumber
    @NSManaged var format: String
    @NSManaged var identifier: String
    @NSManaged var language: String
    @NSManaged var publisher: String
    @NSManaged var sort_num: NSNumber
    @NSManaged var title: String

}
