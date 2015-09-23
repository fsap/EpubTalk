//
//  FileManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class FileManager: NSObject {
    
    let fileManager : NSFileManager = NSFileManager.defaultManager()
    
    private var keepLoading: Bool

    class var sharedInstance : FileManager {
        struct Static {
            static let instance : FileManager = FileManager()
        }
        return Static.instance
    }

    override init() {
        self.keepLoading = true
    }
    
    ///
    /// 他アプリからエクスポートされたファイルの格納場所を取得
    ///
    static func getInboxDir()-> String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kInboxDocumentPath)
    }
    
    ///
    /// 本棚のパスを取得
    ///
    static func getImportDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kSaveDocumentPath)
    }
    
    ///
    /// 作業用のパスを取得
    ///
    static func getTmpDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kTmpDocumentPath)
    }
    
    ///
    /// 指定したファイル(ディレクトリ)が存在するか
    /// :param: String ファイルまたはディレクトリ
    func exists(path : String)->Bool {
        return self.fileManager.fileExistsAtPath(path)
    }
    
    ///
    /// 有効な拡張子か
    /// :param: String ファイル名
    static func isValiedExtension(filename : String)->Bool {
        return contains(Constants.kImportableExtensions, filename.pathExtension)
    }
    
    ///
    /// システムファイルかどうか
    ///
    func isSystemFile(filename: String)->Bool {
        if filename[filename.startIndex] == "_" || filename[filename.startIndex] == "." {
            return true
        }
        return false
    }
    
    ///
    /// zip解凍
    /// :param: String 圧縮ファイルのファイル名をフルパスで指定
    /// :param: String 展開先のディレクトリ
    func unzip(importFilePath : String, expandDir : String)->Bool {
        if (exists(expandDir)) {
            self.fileManager.removeItemAtPath(expandDir, error: nil)
        }
        return SSZipArchive.unzipFileAtPath(importFilePath, toDestination: expandDir)
    }
    
    ///
    /// ファイルを検索
    /// :param: ファイル名(ディレクトリも可)
    /// :param: 対象ディレクトリ
    /// :param: 再帰的に検索を行うかどうか
    func searchFile(filename: String, targetDir: String, recursive: Bool, inout result: String?)->Bool {
        
        let target: String = targetDir.stringByRemovingPercentEncoding!

        // 対象ディレクトリが存在しない
        if !exists(target) {
            LogE(NSString(format: "Search target directory not found. dir:%@", target))
            return false
        }
        
        // 配下のファイルを取得
        var err: NSError? = nil
        let contents = self.fileManager.contentsOfDirectoryAtPath(target, error: &err)!
        if err != nil {
            LogE(NSString(format: "Search target directory has no contents. dif:%@ err_code:%d msg:%@", target, err!.code, err!.description))
            return false
        }
        for c in contents {
            let c: String  = c as! String
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(target.stringByAppendingPathComponent(content), isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchFile(filename, targetDir: target.stringByAppendingPathComponent(content), recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
            
            // ファイル名をチェック
            if content == filename {
                result = target.stringByAppendingPathComponent(content)
                return true
            }
        }
        
        return false
    }

    ///
    /// 拡張子を指定してファイルを検索
    /// :param: 拡張子
    /// :param: 対象ディレクトリ
    /// :param: 再帰的に検索を行うかどうか
    func searchExtension(ext: String, targetDir: String, recursive: Bool, inout result: String?)->Bool {
        
        let target: String = targetDir.stringByRemovingPercentEncoding!
        
        // 対象ディレクトリが存在しない
        if !exists(target) {
            LogE(NSString(format: "Search target directory not found. dir:%@", target))
            return false
        }
        
        // 配下のファイルを取得
        var err: NSError? = nil
        let contents = self.fileManager.contentsOfDirectoryAtPath(target, error: &err)!
        if err != nil {
            LogE(NSString(format: "Search target directory has no contents. dif:%@ err_code:%d msg:%@", target, err!.code, err!.description))
            return false
        }
        for c in contents {
            let c: String  = c as! String
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(target.stringByAppendingPathComponent(content), isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchExtension(ext, targetDir: target.stringByAppendingPathComponent(content), recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
            
            // 拡張子をチェック
            if content.pathExtension == ext {
                result = target.stringByAppendingPathComponent(content)
                return true
            }
        }
        
        return false
    }
    
    //
    // インポートを開始するにあたっての初期処理
    //
    func initImport()->Void {
        if !(exists(FileManager.getImportDir())) {
            var err:NSError? = nil
            self.fileManager.createDirectoryAtPath(FileManager.getImportDir(), withIntermediateDirectories: false, attributes: nil, error: &err)
            if err != nil {
                LogE(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            }
        }
    }
    
    //
    // インポート終了後の共通処理
    //
    func deInitImport(paths:[String])->Void {
        var isDir = ObjCBool(true)
        for path in paths {
            if !(self.fileManager.fileExistsAtPath(path, isDirectory: &isDir)) {
                continue
            }
            removeFile(path)
        }
    }

    //
    // XMLファイルの読み込み
    //
    func loadXmlFiles(xmlFilePaths:[String], saveDir: String, metadata: Metadata)->String {
        Log(NSString(format: "xml_file_path:%@", xmlFilePaths))
        if xmlFilePaths.count == 0 {
            LogE(NSString(format: "No xml files. [%@]", xmlFilePaths))
            return ""
        }
        
        // コンテンツ読み出し
        var brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        var file = File()
        file.DataSet(brllist)
        var headInfo: TDV_HEAD = TDV_HEAD()
        memset(&headInfo, 0x00, sizeof(TDV_HEAD))
        // メタ情報の設定
        switch metadata.language.lowercaseString {
        case Languages.ja.langString():
            headInfo.VoiceGengo = Languages.ja.rawValue
            break
        case Languages.en_us.langString():
            headInfo.VoiceGengo = Languages.en_us.rawValue
            break
        default:
            break
        }
        
        for (index,xml) in enumerate(xmlFilePaths) {
            if !keepLoading {
                keepLoading = true
                return ""
            }
            
            var xmlFile:String = xml
            Log(NSString(format: "xml:%@", xmlFile))
            
            let tagetFile:[CChar] = xml.cStringUsingEncoding(NSUTF8StringEncoding)!
            let mode:Int32 = index == 0 ? 0 : 1
            file.LoadXmlFile(tagetFile, readMode: mode)
        }
        // 一時保存
        let titleBaseName = saveDir.lastPathComponent.stringByDeletingPathExtension
        let saveFileName:String = saveDir.stringByAppendingPathComponent(titleBaseName + ".tdv")
        Log(NSString(format: "save_to:%@", saveFileName))
        if !(file.SaveTdvFile(saveFileName.cStringUsingEncoding(NSUTF8StringEncoding)!, head:&headInfo)) {
            LogE(NSString(format: "Failed to save tdv file. save_file[%@]", saveFileName))
            keepLoading = true
            return ""
        }
        keepLoading = true

        return saveFileName
    }
    
    func cancelLoad() {
        keepLoading = false
    }
    
    //
    // 指定ファイルをブックへ登録
    //
    func saveToBook(importFilePath:String)->TTErrorCode {
        Log(NSString(format: "import_file:%@", importFilePath))
        if !(exists(importFilePath)) {
            return TTErrorCode.FailedToLoadFile
        }
        
        // 保存ファイル名
        let saveFileName = importFilePath.lastPathComponent
        // タイトル名
        let titleBaseName = saveFileName.stringByDeletingPathExtension
        // 保存先ディレクトリ
        let saveDir = FileManager.getImportDir().stringByAppendingPathComponent(titleBaseName)
        // 保存先フルパス
        let saveFilePath = saveDir.stringByAppendingPathComponent(saveFileName)
        Log(NSString(format: "save_to:%@", saveFilePath))
        
        // すでに取り込み済み
        if exists(saveFilePath) {
            return TTErrorCode.FileAlreadyExists
        }
        
        // 保存用ディレクトリの作成
        var err:NSError?
        self.fileManager.createDirectoryAtPath(saveDir, withIntermediateDirectories: false, attributes: nil, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        // 保存
        self.fileManager.copyItemAtPath(importFilePath, toPath: saveFilePath, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToSaveFile
        }
        // パーミッションを変える
        var attr: Dictionary<String, Int> = [NSFilePosixPermissions: 777]
        self.fileManager.setAttributes(attr, ofItemAtPath: saveFilePath, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        return TTErrorCode.Normal
    }
    

    // 指定ファイルを削除
    func removeFile(path:String)->TTErrorCode {
        var err:NSError? = nil
        self.fileManager.removeItemAtPath(path, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToDeleteFile
        }
        return TTErrorCode.Normal
    }

}