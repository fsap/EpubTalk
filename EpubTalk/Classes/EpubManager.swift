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
    static let MetadataFileName:String = "container.xml"
    static let MetadataFileExtension:String = "opf"
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
    func detectEpubStandard(targetUrl: NSURL, didSuccess:((path: NSURL?)->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        
        let fileManager: FileManager = FileManager.sharedInstance
        
        // メタデータディレクトリをサーチ
        var metaDataPath: String? = nil
        if fileManager.searchFile(EpubStandard_3_0.MetadataDirectory, targetUrl: targetUrl, recursive: true, result: &metaDataPath) {
            Log(NSString(format: "META-INF found. %@", try! fileManager.fileManager.contentsOfDirectoryAtPath(metaDataPath!)))
            // META-INF内からcontainerをサーチ
            var containerPath: String? = nil
            if fileManager.searchFile(EpubStandard_3_0.MetadataFileName, targetUrl: metaDataPath!, recursive: true, result: &containerPath) {
                didSuccess(path: containerPath)
                return
            }
            LogE(NSString(format: "[%d] meta data file not found. dir:%@", TTErrorCode.FiledToParseMetadataFile.rawValue, containerPath!))
            didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
            return
        }
    }

    //
    // メタ情報の読み込み
    //
    func loadMetadata(
        targetPath:String,
        containerPath: String,
        didSuccess:((epub: Epub)->Void),
        didFailure:((errorCode: TTErrorCode)->Void)
        )
    {
        let fileManager: FileManager = FileManager.sharedInstance
        
        let containerManager: ContainerManager = ContainerManager.sharedInstance
        containerManager.startParseContainerFile(containerPath, didParseSuccess: { (opfFilePath) -> Void in
            Log(NSString(format: "parse OPF:%@", (targetPath as NSString).stringByAppendingPathComponent(opfFilePath)))
            
            let queue: dispatch_queue_t = dispatch_queue_create("parseOpf", nil)
            dispatch_async(queue, { () -> Void in
                // opfを読み取る
                let opfManager: OpfManager = OpfManager.sharedInstance
                opfManager.startParseOpfFile((targetPath as NSString).stringByAppendingPathComponent(opfFilePath), didParseSuccess: { (epub) -> Void in
                    didSuccess(epub: epub)
                    
                    }, didParseFailure: { (errorCode) -> Void in
                        LogE(NSString(format: "Metadata file not found. dir:%@", opfFilePath))
                        didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                })
            })
        }) { (errorCode) -> Void in
            LogE(NSString(format: "Container file %@ not found.", targetPath))
            didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
        }
    }
}