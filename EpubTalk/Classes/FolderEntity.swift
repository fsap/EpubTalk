//
//  FolderEntity.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/07.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import CoreData

class FolderEntity: NSManagedObject {

    @NSManaged var folder_id: String
    @NSManaged var name: String

}
