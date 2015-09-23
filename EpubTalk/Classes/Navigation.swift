//
//  Navigation.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum MediaTypes: String {
    case XML = "application/x-dtbook+xml"
}

class Navigation: NSObject {
    
    var contentsPaths: [String]
    
    override init() {
        self.contentsPaths = []
    }
}