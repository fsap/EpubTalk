//
//  ManifestItem.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum ManifestTag: String {
    case Manifest = "manifest"
    case Item = "item"
}

enum ManifestItemAttr: String {
    case Id = "id"
    case Href = "href"
    case MediaType = "media-type"
}



class ManifestItem: NSObject {
    
    var id: String
    var href: String
    var mediaType: String
    
    override init() {
        id = ""
        href = ""
        mediaType = ""
    }
}
