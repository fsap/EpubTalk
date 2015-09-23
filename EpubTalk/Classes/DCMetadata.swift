//
//  DCMetadata.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum DCMetadataTag: String {
    case DC_Metadata = "dc-metadata"
    case DC_Identifier = "dc:Identifier"
    case DC_Title = "dc:Title"
    case DC_Rights = "dc:Rights"
    case DC_Publisher = "dc:Publisher"
    case DC_Subject = "dc:Subject"
    case DC_Date = "dc:Date"
    case DC_Description = "dc:Description"
    case DC_Creator = "dc:Creator"
    case DC_Language = "dc:Language"
    case DC_Format = "dc:Format"
}


class DCMetadata: Metadata {
    
    var rights: String
    var subject: String
    
    override init() {
        rights = ""
        subject = ""
    }
}
