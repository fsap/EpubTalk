//
//  DaisyManager.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

enum DaisyStandards: CGFloat {
    case Version2_02 = 2.02
    case Version3 = 3
}

struct DaisyStandard2_02 {
    static let Version: CGFloat = 2.02
    static let MetadataFileName:String = "ncc.html"
    static let IndexFileName:String = "ncc.html"
}

struct DaisyStandard3 {
    static let Version: CGFloat = 3
    static let MetadataFileExtension:String = "opf"
    static let IndexFileExtension:String = "ncx"
}


class DaisyManager: NSObject {
    
    var daisies: [Daisy]
    
    override init() {
        daisies = []
    }
    
    class var sharedInstance : DaisyManager {
        struct Static {
            static let instance : DaisyManager = DaisyManager()
        }
        return Static.instance
    }
    
    ///
    /// Daisy規格のチェック
    /// :param: String チェックするディレクトリ(zip展開済み)
    /// :param: Closure 処理に成功した時のクロージャを定義
    /// :param: Closure 処理に失敗した時のクロージャを定義
    ///
    func detectDaisyStandard(targetFileDir: String, didSuccess:((version: CGFloat)->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        
        let fileManager: FileManager = FileManager.sharedInstance
        
        // マルチDAISYか確認するためにdiscinfoをサーチ
        var discInfoPath: String? = nil
        if fileManager.searchFile(Constants.kMultiDaisyInfoFile, targetDir: targetFileDir, recursive: true, result: &discInfoPath) {
            // discinfoを読み取る
            let discInfoManager: DiscInfoManager = DiscInfoManager.sharedInstance
            discInfoManager.startParseDiscInfoFile(discInfoPath!, didParseSuccess: { (discInfos) -> Void in
                // discinfo解析失敗
                if discInfos.count == 0 {
                    LogE(NSString(format: "discinfo.html is not found. dir:%@", targetFileDir))
                    didFailure(errorCode: TTErrorCode.FailedToLoadFile)
                    return
                }
                
                // メタ情報を探しにいく
                for discinfo in discInfos {
                    /* 2.02は対象外(エラーとする)
                    let nccPath: String = discinfo.href
                    // nccじゃない
                    if nccPath.lastPathComponent != DaisyStandard2_02.MetadataFileName {
                        LogE(NSString(format: "ncc path is invalid. ncc:%@", nccPath))
                        didFailure(errorCode: TTErrorCode.FailedToLoadFile)
                        return
                    }
                    */
                    
                    let opfPath: String = discinfo.href
                    if opfPath.pathExtension != DaisyStandard3.MetadataFileExtension {
                        LogE(NSString(format: "opf path is invalid. opf:%@", opfPath))
                        didFailure(errorCode: TTErrorCode.FailedToLoadFile)
                        return
                    }
                }
                /*
                // 2.02チェックOK
                didSuccess(version: DaisyStandards.Version2_02.rawValue)
                */
                didSuccess(version: DaisyStandards.Version3.rawValue)
            }, didParseFailure: { (errorCode) -> Void in
                LogE(NSString(format: "[%d] Failed to parse discinfo.html. dir:%@", errorCode.rawValue, discInfoPath!))
                didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                return
            })
            return
        }
        
        /* 2.02は対象外(エラーとする)
        // 規格2.02のファイル構成で読みに行く
        var nccFilePath: String? = nil
        if fileManager.searchFile(DaisyStandard2_02.MetadataFileName, targetDir: targetFileDir, recursive: true, result: &nccFilePath) {
            // nccを読み取る
            let nccManager: NccManager = NccManager.sharedInstance
            nccManager.startParseNccFile(nccFilePath!, didParseSuccess: { (daisy) -> Void in
                // 2.02チェックOK
                didSuccess(version: DaisyStandards.Version2_02.rawValue)
                
            }, didParseFailure: { (errorCode) -> Void in
                LogE(NSString(format: "[%d] Failed to parse ncc.html. dir:%@", errorCode.rawValue, nccFilePath!))
                didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                return
            })
            return
        }
        */
        
        // 規格3のファイル構成で読みに行く
        var opfFilePath: String? = nil
        if fileManager.searchExtension(DaisyStandard3.MetadataFileExtension, targetDir: targetFileDir, recursive: true, result: &opfFilePath) {
            // opfを読み取る
            let opfManager: OpfManager = OpfManager.sharedInstance
            opfManager.startParseOpfFile(opfFilePath!, didParseSuccess: { (daisy) -> Void in
                // 3チェックOK
                didSuccess(version: DaisyStandards.Version3.rawValue)
                
            }, didParseFailure: { (errorCode) -> Void in
                LogE(NSString(format: "[%d] Failed to parse opf. dir:%@", errorCode.rawValue, opfFilePath!))
                didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                return
            })
            return
        }
    }
    
    //
    // メタ情報の読み込み
    //
    func loadMetadata(
        targetDir :String,
        version: CGFloat,
        didSuccess:((daisy: Daisy)->Void),
        didFailure:((errorCode: TTErrorCode)->Void)
    )
    {
        let fileManager: FileManager = FileManager.sharedInstance
        
        // 規格によって出しわけ :ToDo:この辺はもう少しうまくやる
        if version == DaisyStandards.Version2_02.rawValue {
            var nccFilePath: String? = nil
            if fileManager.searchFile(DaisyStandard2_02.MetadataFileName, targetDir: targetDir, recursive: true, result: &nccFilePath) {
                // nccを読み取る
                let nccManager: NccManager = NccManager.sharedInstance
                nccManager.startParseNccFile(nccFilePath!, didParseSuccess: { (daisy) -> Void in
                    didSuccess(daisy: daisy)
                    
                    }, didParseFailure: { (errorCode) -> Void in
                        LogE(NSString(format: "[%d] Failed to parse ncc.html. dir:%@", errorCode.rawValue, nccFilePath!))
                        didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                })
            } else {
                LogE(NSString(format: "Metadata file %@ not found. dir:%@", DaisyStandard2_02.MetadataFileName, nccFilePath!))
                didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
            }
            return
        }
        
        if version == DaisyStandards.Version3.rawValue {
            var opfFilePath: String? = nil
            if fileManager.searchExtension(DaisyStandard3.MetadataFileExtension, targetDir: targetDir, recursive: true, result: &opfFilePath) {
                // opfを読み取る
                let opfManager: OpfManager = OpfManager.sharedInstance
                opfManager.startParseOpfFile(opfFilePath!, didParseSuccess: { (daisy) -> Void in
                    didSuccess(daisy: daisy)
                    
                }, didParseFailure: { (errorCode) -> Void in
                    LogE(NSString(format: "Metadata file %@ not found. dir:%@", DaisyStandard3.MetadataFileExtension, opfFilePath!))
                    didFailure(errorCode: TTErrorCode.FiledToParseMetadataFile)
                })
            }
            return
        }
    }
}