//
//  Metadata.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum MetadataTag: String {
    case Metadata = "meta"
    case DC_Identifier = "dc:identifier"
    case DC_Title = "dc:title"
    case DC_Publisher = "dc:publisher"
    case DC_Date = "dc:date"
    case DC_Creator = "dc:creator"
    case DC_Language = "dc:language"
    case DC_Format = "dc:format"
}

enum MetadataAttr: String {
    case Name = "name"
    case Content = "content"
}

enum Languages: UInt8 {
    case ja = 34
    case en_us = 1
    
    func langString()->String {
        switch self {
        case .ja: return "ja"
        case .en_us: return "en_us"
        default: return ""
        }
    }
}


class Metadata: NSObject {
    
    var identifier: String
    var title: String
    var publisher: String
    var date: String
    var creator: String
    var language: String
    var format: String
    
    override init() {
        identifier = ""
        title = ""
        publisher = ""
        date = ""
        creator = ""
        language = ""
        format = ""
    }
}
