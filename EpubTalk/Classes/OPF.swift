//
//  OPF.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class OPF: NSObject {
    
    var dcMetadata: DCMetadata
    var manifestItem: ManifestItem
    
    override init() {
        self.dcMetadata = DCMetadata()
        self.manifestItem = ManifestItem()
    }
}