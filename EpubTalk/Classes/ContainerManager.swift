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
    
    private var didParseSuccess: ((opfPath: String)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var opfFilePath: String
    private var isInRoot: Bool
    private var currentDir: String
    
    
    class var sharedInstance : ContainerManager {
        struct Static {
            static let instance : ContainerManager = ContainerManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.opfFilePath = ""
        self.isInRoot = false
        self.currentDir = ""
        
        super.init()
    }
    
    func startParseContainerFile(containerFilePath: String,
        didParseSuccess: ((opfFilePath: String)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(containerFilePath)
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: url)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.MetadataFileNotFound)
            return
        }
        
        currentDir = containerFilePath.stringByDeletingLastPathComponent
        
        parser!.delegate = self
        
        parser!.parse()
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
        attributes attributeDict: [NSObject : AnyObject])
    {
        Log(NSString(format: " - found element:[%@] attr[%@]", elementName, attributeDict))
        
        if elementName == ContainerTag.RootFile.rawValue {
            var fullPath: String? = attributeDict[ContainerAttr.FullPath.rawValue] as? String
            Log(NSString(format: "full-path:%@", fullPath!))
            self.opfFilePath = fullPath!
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
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        Log(NSString(format: " - found value:[%@]", string!))
        
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
            self.didParseSuccess!(opfPath: self.opfFilePath)
        }
    }
    
}