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
    
    static func getHomeURL()->NSURL {
        return NSURL(fileURLWithPath: NSHomeDirectory())
    }
    
    ///
    /// 他アプリからエクスポートされたファイルの格納場所を取得
    ///
    static func getInboxPath(filename: String?)-> String {
        return getInboxDir(filename).path!
    }
    
    static func getInboxDir(filename: String?)->NSURL {
        var inboxUrl: NSURL = getHomeURL().URLByAppendingPathComponent(Constants.kInboxDocumentPath)
        if (filename != nil) {
            inboxUrl = inboxUrl.URLByAppendingPathComponent(filename!)
        }
        return inboxUrl
    }
    
    ///
    /// 本棚のパスを取得
    ///
    static func getImportPath(filename: String?)->String {
        return getImportDir(filename).path!
    }
    
    static func getImportDir(filename: String?)->NSURL {
        var importUrl: NSURL = getHomeURL().URLByAppendingPathComponent(Constants.kSaveDocumentPath)
        if (filename != nil) {
            importUrl = importUrl.URLByAppendingPathComponent(filename!)
        }
        return importUrl
    }
    
    ///
    /// 作業用のパスを取得
    ///
    static func getTmpDirString()->String {
        return getHomeURL().URLByAppendingPathComponent(Constants.kTmpDocumentPath).path!
    }
    
    static func getTmpDir()->NSURL {
        return getHomeURL().URLByAppendingPathComponent(Constants.kTmpDocumentPath)
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
        return Constants.kImportableExtensions.contains(NSString(format: "%@", NSURL(fileURLWithPath:filename).pathExtension!) as String)
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
    func unzip(importFilePath : String, expandPath : String)->Bool {
        if (exists(expandPath)) {
            // ToDo: 例外処理
            try! self.fileManager.removeItemAtPath(expandPath)
        }
        return SSZipArchive.unzipFileAtPath(importFilePath, toDestination: expandPath)
    }
    
    ///
    /// ファイルを検索
    /// - parameter ファイル名(ディレクトリも可):
    /// - parameter 対象ディレクトリ:
    /// - parameter 再帰的に検索を行うかどうか:
    func searchFile(filename: String, targetUrl: NSURL, recursive: Bool, inout result: String?)->Bool {
        
        // 対象ディレクトリが存在しない
        if !exists(targetUrl.path!) {
            LogE(NSString(format: "Search target directory not found. dir:%@", targetUrl))
            return false
        }
        
        // 配下のファイルを取得
        var contents: [String] = []
        do {
            contents = try self.fileManager.contentsOfDirectoryAtPath(targetUrl.path!)
        } catch let error as NSError {
            LogE(NSString(format: "Search target directory has no contents. dir:%@ [%d][msg]", targetUrl, error.code, error.description))
            return false
        }
        for c in contents {
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(targetUrl.URLByAppendingPathComponent(content).path!, isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ファイル名をチェック
            if content == filename {
                result = targetUrl.URLByAppendingPathComponent(content).path!
                return true
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchFile(filename, targetUrl: targetUrl.URLByAppendingPathComponent(content), recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
        }
        
        return false
    }

    ///
    /// 拡張子を指定してファイルを検索
    /// - parameter 拡張子:
    /// - parameter 対象ディレクトリ:
    /// - parameter 再帰的に検索を行うかどうか:
    func searchExtension(ext: String, targetUrl: NSURL, recursive: Bool, inout result: String?)->Bool {
        
        // 対象ディレクトリが存在しない
        if !exists(targetUrl.path!) {
            LogE(NSString(format: "Search target directory not found. dir:%@", targetUrl.path!))
            return false
        }
        
        // 配下のファイルを取得
        var contents: [String] = []
        do {
            contents = try self.fileManager.contentsOfDirectoryAtPath(targetUrl.path!)
        } catch let error as NSError {
            LogE(NSString(format: "Search target directory has no contents. dir:%@ [%d][msg]", targetUrl.path!, error.code, error.description))
            return false
        }
        
        for c in contents {
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(targetUrl.URLByAppendingPathComponent(content).path!, isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchExtension(ext, targetUrl: targetUrl.URLByAppendingPathComponent(content), recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
            
            // 拡張子をチェック
            if NSURL(fileURLWithPath: content).pathExtension == ext {
                result = targetUrl.URLByAppendingPathComponent(content).path!
                return true
            }
        }
        
        return false
    }
    
    //
    // インポートを開始するにあたっての初期処理
    //
    func initImport()->Void {
        if !(exists(FileManager.getImportPath(nil))) {
            do {
                try self.fileManager.createDirectoryAtPath(FileManager.getImportPath(nil), withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                LogE(NSString(format: "Failed to create dir. dir:[%@] [%d][%@]", FileManager.getImportPath(nil), error.code, error.description))
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
    func loadXmlFiles(xmlFilePaths:[String], saveUrl: NSURL, metadata: Metadata)->String {
        Log(NSString(format: "xml_file_path:%@", xmlFilePaths))
        if xmlFilePaths.count == 0 {
            LogE(NSString(format: "No xml files. [%@]", xmlFilePaths))
            return ""
        }
        
        // コンテンツ読み出し
        let brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        let file = File()
        file.DataSet(brllist)
        var headInfo: TDV_HEAD = TDV_HEAD()
        memset(&headInfo, 0x00, sizeof(TDV_HEAD))
        // メタ情報の設定
        headInfo.VoiceGengo = Constants.MetaLanguageDefaultId
        if Constants.MetaLanguageId[metadata.language] != nil {
            headInfo.VoiceGengo = Constants.MetaLanguageId[metadata.language]!
        }
        Log(NSString(format: "lang:%d", headInfo.VoiceGengo))
        
        for (index,xml) in xmlFilePaths.enumerate() {
            if !keepLoading {
                keepLoading = true
                return ""
            }
            
            let xmlFile:String = xml
            Log(NSString(format: "xml:%@", xmlFile))
            
            let tagetFile:[CChar] = xml.cStringUsingEncoding(NSUTF8StringEncoding)!
            let mode:Int32 = index == 0 ? 0 : 1
            file.LoadXmlFile(tagetFile, readMode: mode)
        }
        // 一時保存
        let titleBaseName = saveUrl.URLByDeletingPathExtension?.lastPathComponent!
        Log(NSString(format: "base name:%@", titleBaseName!))
        let saveFilePath:String = saveUrl.URLByAppendingPathComponent(titleBaseName! + ".tdv").path!
        Log(NSString(format: "save_to:%@", saveFilePath))
        if !(file.SaveTdvFile(saveFilePath.cStringUsingEncoding(NSUTF8StringEncoding)!, head:&headInfo)) {
            LogE(NSString(format: "Failed to save tdv file. save_file[%@]", saveFilePath))
            keepLoading = true
            return ""
        }
        keepLoading = true

        return saveFilePath
    }
    
    //
    // HTMLファイルの読み込み
    //
    func loadHtmlFiles(htmlFilePaths:[String], saveUrl: NSURL, metadata: Metadata)->String {
        Log(NSString(format: "html_file_path:%@", htmlFilePaths))
        if htmlFilePaths.count == 0 {
            LogE(NSString(format: "No html files. [%@]", htmlFilePaths))
            return ""
        }
        
        // コンテンツ読み出し
        let brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        let file = File()
        file.DataSet(brllist)
        var headInfo: TDV_HEAD = TDV_HEAD()
        memset(&headInfo, 0x00, sizeof(TDV_HEAD))
        // メタ情報の設定
        headInfo.VoiceGengo = Constants.MetaLanguageDefaultId
        if Constants.MetaLanguageId[metadata.language] != nil {
            headInfo.VoiceGengo = Constants.MetaLanguageId[metadata.language]!
        }
        Log(NSString(format: "lang:%d", headInfo.VoiceGengo))
        
        for (index,html) in htmlFilePaths.enumerate() {
            if !keepLoading {
                keepLoading = true
                return ""
            }
            
            let htmlFile: String = html
            let htmlUrl: NSURL = NSURL(fileURLWithPath: htmlFile)
            Log(NSString(format: "html:%@", htmlFile))
            
            let targetFile:[CChar] = html.cStringUsingEncoding(NSUTF8StringEncoding)!
            let mode:Int32 = index == 0 ? 0 : 1
            if htmlUrl.pathExtension == ContentExt.HTML.rawValue || htmlUrl.pathExtension == ContentExt.XHTML.rawValue {
                file.LoadHtmlFile(targetFile, readMode: mode)
            }
            else if htmlUrl.pathExtension == ContentExt.XML.rawValue {
                file.LoadXmlFile(targetFile, readMode: mode)
            }
        }
        // 一時保存
        let titleBaseName = saveUrl.URLByDeletingPathExtension?.lastPathComponent!
        Log(NSString(format: "base name:%@", titleBaseName!))
        let saveFilePath:String = saveUrl.URLByAppendingPathComponent(titleBaseName! + ".tdv").path!
        Log(NSString(format: "save_to:%@", saveFilePath))
        if !(file.SaveTdvFile(saveFilePath.cStringUsingEncoding(NSUTF8StringEncoding)!, head:&headInfo)) {
            LogE(NSString(format: "Failed to save tdv file. save_file[%@]", saveFilePath))
            keepLoading = true
            return ""
        }
        keepLoading = true
        
        return saveFilePath
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
        let saveFileName = NSURL(fileURLWithPath: importFilePath).lastPathComponent
        // タイトル名
        let titleBaseName = NSURL(fileURLWithPath: saveFileName!).URLByDeletingPathExtension!.path
        // 保存先ディレクトリ
        let saveDir: NSURL = FileManager.getImportDir(titleBaseName!)
        // 保存先フルパス
        let saveFilePath = saveDir.URLByAppendingPathComponent(saveFileName!).path
        Log(NSString(format: "save_to:%@", saveFilePath!))
        
        // すでに取り込み済み
        if exists(saveFilePath!) {
            return TTErrorCode.FileAlreadyExists
        }

        // 保存用ディレクトリの作成
        do {
            try self.fileManager.createDirectoryAtPath(saveDir.path!, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            Log(NSString(format: "Failed to create dir for save. dir:[%@] [%d][%@]", saveDir, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        // 保存
        do {
            try self.fileManager.copyItemAtPath(importFilePath, toPath: saveFilePath!)
        } catch let error as NSError {
            Log(NSString(format: "Failed to save file. save_path:[%@] [%d][%@]", saveFilePath!, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }
        // パーミッションを変える
        let attr: Dictionary<String, Int> = [NSFilePosixPermissions: 777]
        do {
            try self.fileManager.setAttributes(attr, ofItemAtPath: saveFilePath!)
        } catch let error as NSError {
            Log(NSString(format: "Failed to change file. attr:[%@] [%d][%@]", attr, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }

        return TTErrorCode.Normal
    }
    

    // 指定ファイルを削除
    func removeFile(path:String)->TTErrorCode {
        Log(NSString(format: "remove file:%@", path))
        do {
            try self.fileManager.removeItemAtPath(path)
        } catch let error as NSError {
            Log(NSString(format: "Failed to delete file. path:[%@] [%d][%@]", path, error.code, error.description))
            return TTErrorCode.FailedToDeleteFile
        }
        
        return TTErrorCode.Normal
    }

}