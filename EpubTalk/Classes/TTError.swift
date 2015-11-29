//
//  TTError.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/20.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

enum TTErrorCode :Int {
    case Normal = 0
    // 1xx : ファイル読み込みに関するエラー
    case FailedToGetFile = 101,
        FileNotExists,
        UnsupportedFileType,
        FailedToLoadFile,
        FileAlreadyExists,
        FailedToSaveFile,
        FailedToDeleteFile,
        MetadataFileNotFound,
        NavigationFileNotFound,
        ContentFileNotFound
    // 2xx : DBに関するエラー
    case FailedToSaveDB = 201
    // 3xx : フォルダ作成に関するエラー
    case DuplicateFolderName = 301,
        CannotDeleteFolder,
        FailedToPasteBook,
        DuplicateBook
    // 4xx : 課金に関するエラー
    case CannotUseInAppPurchase = 401,
        FailedToPurchase,
        FailedToRestore,
        CanceledToPurchase
    // 5xx 入力チェック系
    case InvalidParameter = 501,
        InvalidId,
        BlankString,
        StringTooLong,
        InvalidString
    // 9xx Internal Error
    case InternalError = 999
}

class TTError {
    static func getErrorMessage(code : TTErrorCode)->String {
        let key = "error_msg_" + (NSString(format: "%03d", code.rawValue) as String)
        return NSLocalizedString(key, comment: "err")
    }
}