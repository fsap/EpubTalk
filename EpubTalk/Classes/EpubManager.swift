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
    /// :param: String チェックするディレクトリ(zip展開済み)
    /// :param: Closure 処理に成功した時のクロージャを定義
    /// :param: Closure 処理に失敗した時のクロージャを定義
    ///
    func detectEpubStandard(targetFileDir: String, didSuccess:((version: CGFloat)->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        
        let fileManager: FileManager = FileManager.sharedInstance
        
        // メタデータディレクトリをサーチ
        var metaDataPath: String? = nil
        if fileManager.searchFile(EpubStandard_3_0.MetadataDirectory, targetDir: targetFileDir, recursive: true, result: &metaDataPath) {
            // META-INF内からcontainerをサーチ
            var containerPath: String? = nil
            if fileManager.searchFile(EpubStandard_3_0.MetadataFileName, targetDir: metaDataPath!, recursive: true, result: &containerPath) {
                didSuccess(version: EpubStandard_3_0.Version)
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
        targetDir :String,
        didSuccess:((epub: AnyObject)->Void),
        didFailure:((errorCode: TTErrorCode)->Void)
        )
    {
        let fileManager: FileManager = FileManager.sharedInstance
        
        var opfFilePath: String? = nil
        if fileManager.searchExtension(DaisyStandard3.MetadataFileExtension, targetDir: targetDir, recursive: true, result: &opfFilePath) {
            // opfを読み取る
            let opfManager: OpfManager = OpfManager.sharedInstance
            opfManager.startParseOpfFile(opfFilePath!, didParseSuccess: { (daisy) -> Void in
                didSuccess(epub: daisy)
                
                }, didParseFailure: { (errorCode) -> Void in
                    LogE(NSString(format: "Metadata file %@ not found. dir:%@", DaisyStandard3.MetadataFileExtension, opfFilePath!))
                    didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
            })
        }
    }
}