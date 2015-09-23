//
//  NccManager.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum SmilTag: String {
    case H1 = "h1"
    case H2 = "h2"
    case A = "a"
}

enum SmilAttr: String {
    case Href = "href"
}


class NccManager: NSObject, NSXMLParserDelegate {
    
    private var didParseSuccess: ((daisy: Daisy)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var daisy: Daisy
    private var isInMetadata: Bool
    private var isInSmil: Bool
    private var currentDir: String
    
    
    class var sharedInstance : NccManager {
        struct Static {
            static let instance : NccManager = NccManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.daisy = Daisy()
        self.isInMetadata = false
        self.isInSmil = false
        self.currentDir = ""
        
        super.init()
    }
    
    func startParseNccFile(nccFilePath: String,
        didParseSuccess: ((daisy: Daisy)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(nccFilePath)
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: url)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.MetadataFileNotFound)
            return
        }
        
        currentDir = nccFilePath.stringByDeletingLastPathComponent
        
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
        
        if elementName == MetadataTag.Metadata.rawValue {
            
            let name: String? = attributeDict[MetadataAttr.Name.rawValue] as? String
            if name != nil {
                let content: String = attributeDict[MetadataAttr.Content.rawValue] as! String
                switch name! {
                case MetadataTag.DC_Identifier.rawValue:
                    self.daisy.metadata.identifier = content
                    break
                case MetadataTag.DC_Title.rawValue:
                    self.daisy.metadata.title = content
                    break
                case MetadataTag.DC_Publisher.rawValue:
                    self.daisy.metadata.publisher = content
                    break
                case MetadataTag.DC_Date.rawValue:
                    self.daisy.metadata.date = content
                    break
                case MetadataTag.DC_Creator.rawValue:
                    self.daisy.metadata.creator = content
                    break
                case MetadataTag.DC_Language.rawValue:
                    self.daisy.metadata.language = content
                    break
                case MetadataTag.DC_Format.rawValue:
                    self.daisy.metadata.format = content
                    break
                default:
                    break
                }
            }
        }
        
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
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        Log(NSString(format: " - found value:[%@]", string!))
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - found element:[%@]", elementName))
        
        if self.isInMetadata {
            if elementName == MetadataTag.Metadata.rawValue {
                self.isInMetadata = false
            }
        }
        if self.isInSmil {
            if elementName == SmilTag.H1.rawValue || elementName == SmilTag.H2.rawValue {
                self.isInSmil = false
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