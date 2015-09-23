//
//  OpfManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class OpfManager: NSObject, NSXMLParserDelegate {
    
    // 定数
    struct Const {
        static let kOpfFileExtension: String = "opf"
    }

    private var didParseSuccess: ((daisy: Daisy)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var daisy: Daisy
    private var isInDcMetadata: Bool
    private var isInManifest: Bool
    private var currentElement: String
    private var currentDir: String
    
    
    class var sharedInstance : OpfManager {
        struct Static {
            static let instance : OpfManager = OpfManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.daisy = Daisy()
        self.isInDcMetadata = false
        self.isInManifest = false
        self.currentElement = ""
        self.currentDir = ""
        
        super.init()
    }
    
    func startParseOpfFile(opfFilePath: String,
        didParseSuccess: ((daisy: Daisy)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(opfFilePath)
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: url)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.MetadataFileNotFound)
            return
        }
        
        currentDir = opfFilePath.stringByDeletingLastPathComponent
        
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
//        Log(NSString(format: " - found element:[%@] attr[%@]", elementName, attributeDict))
        
        if elementName == DCMetadataTag.DC_Metadata.rawValue {
            self.isInDcMetadata = true
        } else if self.isInDcMetadata {
            self.currentElement = elementName
        }
        
        if elementName == ManifestTag.Manifest.rawValue {
            self.isInManifest = true
            
        } else if self.isInManifest {
            if elementName == ManifestTag.Item.rawValue {
                // xmlファイル情報のみ取得
                var attr: String = attributeDict[ManifestItemAttr.MediaType.rawValue] as! String
                if attr == MediaTypes.XML.rawValue {
                    var href: String = attributeDict[ManifestItemAttr.Href.rawValue] as! String
                    var path: String = currentDir.stringByAppendingPathComponent(href)
                    self.daisy.navigation.contentsPaths.append(path)
                }
            }
        }
        
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
//        Log(NSString(format: " - found value:[%@] current_elem:%@", string!, self.currentElement))
        
        if self.isInDcMetadata {
            switch self.currentElement {
            case DCMetadataTag.DC_Identifier.rawValue:
                self.daisy.metadata.identifier = string!
                break
            case DCMetadataTag.DC_Title.rawValue:
                self.daisy.metadata.title = string!
                break
            case DCMetadataTag.DC_Publisher.rawValue:
                self.daisy.metadata.publisher = string!
                break
//            case DCMetadataTag.DC_Subject.rawValue:
//                self.daisy.metadata.subject = string!
//                break
            case DCMetadataTag.DC_Date.rawValue:
                self.daisy.metadata.date = string!
                break
            case DCMetadataTag.DC_Creator.rawValue:
                self.daisy.metadata.creator = string!
                break
            case DCMetadataTag.DC_Language.rawValue:
                self.daisy.metadata.language = string!
                break
            case DCMetadataTag.DC_Format.rawValue:
                self.daisy.metadata.format = string!
                break
            default:
                break
            }
        }
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        Log(NSString(format: " - found element:[%@]", elementName))
        
        if self.isInDcMetadata {
            if elementName == DCMetadataTag.DC_Metadata.rawValue {
                self.isInDcMetadata = false
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
            self.didParseSuccess!(daisy: self.daisy)
        }
    }
    
}