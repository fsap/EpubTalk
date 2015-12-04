//
//  Constants.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation


// 定数定義
struct Constants {

    /**
     * ファイル操作関連
     */
    // 取り込み可能な拡張子
    static let kImportableExtensions: [String] = ["zip", "epub"]
    // 他アプリからエクスポートされたファイルの格納場所
    static let kInboxDocumentPath: String = "Documents/Inbox"
    // 一時作業用ディレクトリ
    static let kTmpDocumentPath: String = "tmp/"
    // 図書ファイルとして保存するディレクトリ
    static let kSaveDocumentPath: String = "Library/Books"

    /**
     * 図書関連
     */
    // メタデータの言語とIDのマッピングリスト
    static let MetaLanguageId: [String: UInt8] = [
        "en-US": 1,
        "en-GB": 2,
        "en-AU": 3,
        "en-IE": 4,
        "en-ZA": 5,
        "ar-SA": 6,
        "cs-CZ": 7,
        "da-DK": 8,
        "de-DE": 9,
        "el-GR": 10,
        "es-ES": 11,
        "es-MX": 12,
        "fi-FI": 13,
        "fr-CA": 14,
        "fr-FR": 15,
        "hi-IN": 16,
        "hu-HU": 17,
        "id-ID": 18,
        "it-IT": 19,
        "ko-KR": 20,
        "nl-NL": 21,
        "no-NO": 22,
        "pl-PL": 23,
        "pt-BR": 24,
        "pt-PT": 25,
        "ru-RU": 26,
        "sv-SE": 27,
        "th-TH": 28,
        "sk-SK": 29,
//        "th-TH": 30,    // 重複
        "zh-TW": 31,
        "zh-CN": 32,
        "zh-HK": 33,
        "ja": 36,
        "he-IL": 34
    ]
    
    // リストにない場合のデフォルト言語設定
    static let MetaLanguageDefaultId: UInt8 = 1
    

    /**
     * 課金関連
     */
    static let kInAppPurchaseProductiId = "jp.fsap.epubtalkdev.product"
    static let kSavePurchaseStatusKey = "purchase_status"
}