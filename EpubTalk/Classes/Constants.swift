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
     * 課金関連
     */
    static let kInAppPurchaseProductiId = "jp.fsap.epubtalkdev.product";
}