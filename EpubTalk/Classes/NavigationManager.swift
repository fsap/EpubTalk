//
//  NavigationManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class NavigationManager: NSObject, NSXMLParserDelegate {
    
    private var didParseSuccess: ((epub: Epub)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var epub: Epub
    private var currentDir: NSURL?
    
    
    class var sharedInstance : NavigationManager {
        struct Static {
            static let instance : NavigationManager = NavigationManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.epub = Epub()
        self.currentDir = nil
        
        super.init()
    }
    
    func startParseOpfFile(ncxUrl: NSURL,
        didParseSuccess: ((epub: Epub)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: ncxUrl)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.NavigationFileNotFound)
            return
        }
        
        currentDir = ncxUrl.URLByDeletingLastPathComponent
        
        // 初期化しておく
        self.epub = Epub()
        
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
        attributes attributeDict: [String : String])
    {
        Log(NSString(format: " - found element:[%@] attr[%@]", elementName, attributeDict))
        
        if elementName == ContentTag.Content.rawValue {
            let contentPath: String? = attributeDict[ContentAttr.Src.rawValue]
            if contentPath != nil {
                Log(NSString(format: "content src:%@", contentPath!))
                self.epub.navigation.contentsPaths.append(contentPath!)
            }
        }
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        Log(NSString(format: " - found value:[%@]", string))
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - end element:[%@]", elementName))
        
    }
    
    // ファイルの読み込みを終了
    func parserDidEndDocument(parser: NSXMLParser) {
        LogM("--- end parse.")
        
        if self.didParseSuccess != nil {
            self.didParseSuccess!(epub: self.epub)
        }
    }
    
}