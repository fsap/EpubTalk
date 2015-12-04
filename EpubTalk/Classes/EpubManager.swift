//
//  EpubManager.swift
//  EpubTalk
//
//  Created by Fujiwara on 2015/09/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation
import UIKit

struct EpubStandard_3_0 {
    static let Version: CGFloat = 3.0
    static let MetadataDirectory: String = "META-INF"
    static let MetadataFileName: String = "container.xml"
    static let MetadataFileExtension: String = "opf"
    static let NativationFileExtension: String = "ncx"
    static let NavigationFileName: String = "toc.ncx"
}

class EpubManager: NSObject {
    
    class var sharedInstance : EpubManager {
        struct Static {
            static let instance : EpubManager = EpubManager()
        }
        return Static.instance
    }
    
    ///
    /// Epub仕様に沿って必要ファイルを読みに行く
    /// - parameter String: チェックするディレクトリ(zip展開済み)
    /// - parameter Closure: 処理に成功した時のクロージャを定義
    /// - parameter Closure: 処理に失敗した時のクロージャを定義
    ///
    func detectEpubStandard(targetUrl: NSURL, didSuccess:((containerUrl: NSURL?)->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        
        let fileManager: FileManager = FileManager.sharedInstance
        
        // メタデータディレクトリをサーチ
        var metaDataPath: String? = nil
        if fileManager.searchFile(EpubStandard_3_0.MetadataDirectory, targetUrl: targetUrl, recursive: true, result: &metaDataPath) {
            Log(NSString(format: "META-INF found. %@", try! fileManager.fileManager.contentsOfDirectoryAtPath(metaDataPath!)))
            // META-INF内からcontainerをサーチ
            var containerPath: String? = nil
            let metaDataUrl: NSURL = NSURL(fileURLWithPath: metaDataPath!)
            if fileManager.searchFile(EpubStandard_3_0.MetadataFileName, targetUrl: metaDataUrl, recursive: true, result: &containerPath) {
                didSuccess(containerUrl: NSURL(fileURLWithPath: containerPath!))
                return
            }
        }
        LogE(NSString(format: "[%d] meta data file not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
        didFailure(errorCode: TTErrorCode.MetadataFileNotFound)
    }
    
    func searchMetaData(
        targetUrl: NSURL,
        didSuccess:((opfUrl: NSURL)->Void),
        didFailure:((errorCode: TTErrorCode)->Void))
    {
        let fileManager: FileManager = FileManager.sharedInstance
        
        // META-INFディレクトリをサーチ
        var metaInfPath: String? = nil
        if !fileManager.searchFile(EpubStandard_3_0.MetadataDirectory, targetUrl: targetUrl, recursive: true, result: &metaInfPath) {
            LogE(NSString(format: "[%d] META-INF file not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
            didFailure(errorCode: TTErrorCode.MetadataFileNotFound)
            
        } else {
            Log(NSString(format: "META-INF found. %@", try! fileManager.fileManager.contentsOfDirectoryAtPath(metaInfPath!)))
            
            // META-INF内からcontainerをサーチ
            var containerPath: String? = nil
            let metaInfUrl: NSURL = NSURL(fileURLWithPath: metaInfPath!)
            if !fileManager.searchFile(EpubStandard_3_0.MetadataFileName, targetUrl: metaInfUrl, recursive: true, result: &containerPath) {
                LogE(NSString(format: "[%d] container not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
                didFailure(errorCode: TTErrorCode.MetadataFileNotFound)

            } else {
                Log(NSString(format: "container found. %@", containerPath!))
                
                // container.xmlからopfをサーチ
                let containerManager: ContainerManager = ContainerManager.sharedInstance
                let containerUrl: NSURL = NSURL(fileURLWithPath: containerPath!)
                containerManager.startParseContainerFile(
                    targetUrl,
                    containerUrl: containerUrl,
                    didParseSuccess: {(opfUrl: NSURL?) -> Void in
                        if opfUrl != nil {
                            Log(NSString(format: "opf found. %@", opfUrl!))
                            didSuccess(opfUrl: opfUrl!)
                        } else {
                            LogE(NSString(format: "[%d] opf not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
                            didFailure(errorCode: TTErrorCode.MetadataFileNotFound)
                        }
                    },
                    didParseFailure: { (errorCode) -> Void in
                        LogE(NSString(format: "[%d] opf not found. dir:%@", TTErrorCode.MetadataFileNotFound.rawValue, targetUrl))
                        didFailure(errorCode: errorCode)
                    }
                )
            }
        }
    }
    
    func loadContents(
        opfUrl: NSURL,
        didSuccess:((epub: Epub)->Void),
        didFailure:((errorCode: TTErrorCode)->Void)
        )
    {
        Log(NSString(format: "parse OPF:%@", opfUrl))
        
        // opfファイル内をパースしてtoc.ncxファイルをサーチ
        let opfManager: OpfManager = OpfManager.sharedInstance
        opfManager.startParseOpfFile(
            opfUrl,
            didParseSuccess: { (epub) -> Void in
                LogM("Epub file found.")
                didSuccess(epub: epub)
            },
            didParseFailure: { (errorCode) -> Void in
                LogE(NSString(format: "[%d] Contents file not found. dir:%@", TTErrorCode.NavigationFileNotFound.rawValue, opfUrl))
                didFailure(errorCode: TTErrorCode.NavigationFileNotFound)
            }
        )
    }
}