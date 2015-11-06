//
//  OpfManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class OpfManager: NSObject, NSXMLParserDelegate {
    
    private var didParseSuccess: ((ncxUrl: NSURL?, metadata: Metadata)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var ncxUrl: NSURL?
    private var metadata: Metadata
    private var isInMetadata: Bool
    private var isInManifest: Bool
    private var currentElement: String
    private var currentDir: NSURL?
    
    
    class var sharedInstance : OpfManager {
        struct Static {
            static let instance : OpfManager = OpfManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.ncxUrl = nil
        self.metadata = Metadata()
        self.isInMetadata = false
        self.isInManifest = false
        self.currentElement = ""
        self.currentDir = nil
        
        super.init()
    }
    
    func startParseOpfFile(opfUrl: NSURL,
        didParseSuccess: ((ncxUrl: NSURL?, metadata: Metadata)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: opfUrl)
        
        if parser == nil {
            LogE(NSString(format: "[%d] opf not found. dir:%@", TTErrorCode.NavigationFileNotFound.rawValue, opfUrl))
            didParseFailure(errorCode: TTErrorCode.NavigationFileNotFound)
            return
        }
        
        self.currentDir = opfUrl.URLByDeletingLastPathComponent
        
        self.ncxUrl = nil
        self.metadata = Metadata()
        
        parser!.delegate = self
        
        if !parser!.parse() {
            LogE(NSString(format: "[%d] Failed to start parse. dir:%@", TTErrorCode.NavigationFileNotFound.rawValue, opfUrl))
            didParseFailure(errorCode: TTErrorCode.NavigationFileNotFound)
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
        
        if elementName == MetadataTag.Metadata.rawValue {
            self.isInMetadata = true
            
        } else if self.isInMetadata {
            self.currentElement = elementName
        }
        Log(NSString(format: " - current element:[%@]", self.currentElement))
        
        if elementName == ManifestTag.Manifest.rawValue {
            self.isInManifest = true
            
        } else if self.isInManifest {
            if elementName == ManifestTag.Item.rawValue {
                // xmlファイル情報のみ取得
                let attr: String? = attributeDict[ManifestItemAttr.MediaType.rawValue]
                if attr == MediaTypes.NOC.rawValue {
//                    let itemId: String = attributeDict[ManifestItemAttr.Id.rawValue]!
//                    if itemId == EpubStandard_3_0.NativationFileExtension {
                        let href: String = attributeDict[ManifestItemAttr.Href.rawValue]!
                        let path: String = self.currentDir!.URLByAppendingPathComponent(href).path!
                        self.ncxUrl = NSURL(fileURLWithPath: path)
//                    }
                }
            }
        }
        
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        Log(NSString(format: " - found value:[%@] current_elem:%@", string, self.currentElement))
        
        if self.isInMetadata {
            switch self.currentElement {
            case MetadataTag.DC_Identifier.rawValue:
                self.metadata.identifier = string
                break
            case MetadataTag.DC_Title.rawValue:
                if self.metadata.title == "" {
                    self.metadata.title = string
                } else {
                    self.metadata.title += string
                }
                Log(NSString(format: "title:%@", self.metadata.title))
                break
            case MetadataTag.DC_Publisher.rawValue:
                self.metadata.publisher = string
                break
            case MetadataTag.DC_Date.rawValue:
                self.metadata.date = string
                break
            case MetadataTag.DC_Creator.rawValue:
                self.metadata.creator = string
                break
            case MetadataTag.DC_Language.rawValue:
                self.metadata.language = string
                break
            case MetadataTag.DC_Format.rawValue:
                self.metadata.format = string
                break
            default:
                break
            }
        }
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - end element:[%@] current[%@]", elementName, self.currentElement))
        
        if self.isInMetadata {
            if elementName == MetadataTag.Metadata.rawValue {
                self.isInMetadata = false
            }
            self.currentElement = ""
        }
        if self.isInManifest {
            if elementName == ManifestTag.Manifest.rawValue {
                self.isInManifest = false
            }
        }
    }
    
    // ファイルの読み込みを終了
    func parserDidEndDocument(parser: NSXMLParser) {
        LogM("--- end parse.")
        
        if self.didParseSuccess != nil {
            self.didParseSuccess!(ncxUrl: self.ncxUrl, metadata: self.metadata)
        }
    }
    
}