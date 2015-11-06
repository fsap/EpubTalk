//
//  Navigation.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum MediaTypes: String {
    case NOC = "application/x-dtbncx+xml"
    case XML = "application/xhtml+xml"
}

enum ContentTag: String {
    case Content = "content"
}

enum ContentAttr: String {
    case Src = "src"
}

enum ContentExt: String {
    case HTML = "html"
    case XHTML = "xhtml"
    case XML = "xml"
}


class Navigation: NSObject {
    
    var contentsPaths: [String]
    
    override init() {
        self.contentsPaths = []
    }
}