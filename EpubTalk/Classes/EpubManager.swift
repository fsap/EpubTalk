//
//  EpubManager.swift
//  EpubTalk
//
//  Created by Fujiwara on 2015/09/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation
import UIKit

struct EpubStandard_1 {
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
        if fileManager.searchFile(EpubStandard_1.MetadataDirectory, targetDir: targetFileDir, recursive: true, result: &metaDataPath) {
            // META-INF内からcontainerをサーチ
            var containerPath: String? = nil
            if fileManager.searchFile(EpubStandard_1.MetadataFileName, targetDir: metaDataPath!, recursive: true, result: &containerPath) {
                // opfを読み取る
                return
            }
            LogE(NSString(format: "[%d] meta data file not found. dir:%@", TTErrorCode.FiledToParseMetadataFile.rawValue, containerPath!))
            didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
            return
        }
    }
}