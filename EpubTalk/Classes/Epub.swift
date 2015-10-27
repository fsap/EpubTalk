//
//  Epub.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

class Epub: NSObject {
    
    // Epubバージョン
    var version: CGFloat
    // メタデータ
    var dcMetadadta: DCMetadata
    var metadata: Metadata
    // 目次情報
    var navigation: Navigation
    

    override init() {
        self.version = 3
        self.dcMetadadta = DCMetadata()
        self.metadata = Metadata()
        self.navigation = Navigation()
    }
}