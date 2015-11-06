//
//  ContainerManager.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum ContainerTag: String {
    case RootFile = "rootfile"
}

enum ContainerAttr: String {
    case FullPath = "full-path"
}


class ContainerManager: NSObject, NSXMLParserDelegate {
    
    private var didParseSuccess: ((opfUrl: NSURL?)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var opfUrl: NSURL?
    private var isInRoot: Bool
    private var currentDir: NSURL?
    
    
    class var sharedInstance : ContainerManager {
        struct Static {
            static let instance : ContainerManager = ContainerManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.opfUrl = nil
        self.isInRoot = false
        self.currentDir = nil
        
        super.init()
    }
    
    func startParseContainerFile(
        targetUrl: NSURL,
        containerUrl: NSURL,
        didParseSuccess: ((opfUrl: NSURL?)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: containerUrl)
        
        if parser == nil {
            LogE(NSString(format: "[%d] container not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
            didParseFailure(errorCode: TTErrorCode.MetadataFileNotFound)
            return
        }
        
        self.currentDir = targetUrl
        self.opfUrl = nil
        
        parser!.delegate = self
        
        if !parser!.parse() {
            LogE(NSString(format: "[%d] Failed to start parse. dir:%@", TTErrorCode.NavigationFileNotFound.rawValue, containerUrl))
            didParseFailure(errorCode: TTErrorCode.MetadataFileNotFound)
        }
    }
    
    
    //
    // MARK: NSXMLParserDelegate
    //
    
    // ファイルの読み込みを開始
    func parserDidStartDocument(parser: NSXMLParser) {
        LogM("--- start parse.")
    }
    
    // 要素の開始タグを読み込み
    func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String])
    {
        Log(NSString(format: " - found element:[%@] attr[%@]", elementName, attributeDict))
        
        if elementName == ContainerTag.RootFile.rawValue {
            let fullPath: String? = attributeDict[ContainerAttr.FullPath.rawValue]
            if fullPath != nil {
                Log(NSString(format: "full-path:%@", fullPath!))
                self.opfUrl = self.currentDir!.URLByAppendingPathComponent(fullPath!)
            }
        }

/*
        if elementName == SmilTag.H1.rawValue || elementName == SmilTag.H2.rawValue {
            self.isInSmil = true
        } else if self.isInSmil {
            if elementName == SmilTag.A.rawValue {
                // smilファイル情報取得
                var href: String = attributeDict[SmilAttr.Href.rawValue] as! String
                var ary: [String] = href.componentsSeparatedByString("#")
                var path: String = currentDir.stringByAppendingPathComponent(ary[0])
                Log(NSString(format: "path:%@", path))
                self.daisy.navigation.contentsPaths.append(path)
            }
        }
*/
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        Log(NSString(format: " - found value:[%@]", string))
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - found element:[%@]", elementName))
        
        if self.isInRoot {
            if elementName == ContainerTag.RootFile.rawValue {
                self.isInRoot = false
            }
        }
    }
    
    // ファイルの読み込みを終了
    func parserDidEndDocument(parser: NSXMLParser) {
        LogM("--- end parse.")
        
        if self.didParseSuccess != nil {
            self.didParseSuccess!(opfUrl: self.opfUrl)
        }
    }
    
}