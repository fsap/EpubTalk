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

    @NSManaged var book_id: String
//    @NSManaged var folder_id: String    // 親フォルダID
    @NSManaged var title: String
    @NSManaged var sort_num: NSNumber   // フォルダ内での並び順
    // Epub Meta Data
    @NSManaged var creator: String
    @NSManaged var date: NSDate
    @NSManaged var filename: String
    @NSManaged var filesize: NSNumber
    @NSManaged var format: String
    @NSManaged var identifier: String
    @NSManaged var language: String
    @NSManaged var publisher: String

    
    func trace() {
        Log(NSString(format: "***** book.\n  book_id:%@\n  title:%@\n  laguage:%@\n  filename:%@\n  sort:%@",
            self.book_id,
//            self.folder_id,
            self.title,
            self.language,
            self.filename,
            self.sort_num
        ))
    }
}
