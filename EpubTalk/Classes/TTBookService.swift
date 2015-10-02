//
//  TTBookService.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/13.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

protocol BookServiceDelegate {
    func importStarted()
    func importCompleted()
    func importFailed()
}


//
// ブックファイル管理クラス
//
class TTBookService {
    
    var fileManager: FileManager = FileManager.sharedInstance
    var dataManager: DataManager = DataManager.sharedInstance
    
    var delegate: BookServiceDelegate?
    
    private var keepLoading: Bool
    
    class var sharedInstance : TTBookService {
        struct Static {
            static let instance : TTBookService = TTBookService()
        }
        return Static.instance
    }
    
    init () {
        self.keepLoading = true
    }
    
    deinit {
        
    }
    
    //
    // ファイル形式の検証
    //
    func validate(target :String)->TTErrorCode {
        
        if target == "" {
            return TTErrorCode.FailedToGetFile
        }
        var filename: String = target.stringByRemovingPercentEncoding!

        let filepath = FileManager.getInboxDir().stringByAppendingPathComponent(filename)
        Log(NSString(format: "--- paht:%@", filepath))
        
        // ファイルの存在チェック
        if !(self.fileManager.exists(filepath)) {
            Log(NSString(format: "%@ not found.", filepath))
            return TTErrorCode.FileNotExists
        }
        
        // ファイル形式のチェック
        if !(FileManager.isValidExtension(filename)) {
            Log(NSString(format: "Unsupported type:%@", filename))
            self.fileManager.removeFile(filepath)
            return TTErrorCode.UnsupportedFileType
        }
        
        return TTErrorCode.Normal;
    }
    
    //
    // ファイルの取り込み
    //
    func importDaisy(target :String, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void))->Void {
        
//        self.delegate?.importStarted()
        self.keepLoading = true
        
        var filename: String = target.stringByRemovingPercentEncoding!
        // 外部から渡ってきたファイルのパス ex) sadbox/Documents/Inbox/What_Is_HTML5_.zip
        let importFilePath = FileManager.getInboxDir().stringByAppendingPathComponent(filename)
        // 作業用ディレクトリ ex) sadbox/tmp/
        let tmpDir = FileManager.getTmpDir()
        // 作業ファイル展開用ディレクトリ ex) sadbox/tmp/What_Is_HTML5_
        let expandDir = tmpDir.stringByAppendingPathComponent(filename.stringByDeletingPathExtension)
        // 取り込み先ディレクトリ ex) sandbox/Library/Books/
        let bookDir = FileManager.getImportDir()
        
        if (filename.pathExtension == Constants.kImportableExtensions[0]
            || filename.pathExtension == Constants.kImportableExtensions[1]
            || filename.pathExtension == Constants.kImportableExtensions[2]) {
            // 圧縮ファイル展開
            if !(self.fileManager.unzip(importFilePath, expandDir: expandDir)) {
                LogE(NSString(format: "Unable to expand:%@", filename))
                deInitImport([importFilePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
                return
            }
            
        } else {
            LogE(NSString(format: "Unable to expand:%@", filename))
            deInitImport([importFilePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
            return
        }
        Log(NSString(format: "tmp_dir:%@", self.fileManager.fileManager.contentsOfDirectoryAtPath(tmpDir, error: nil)!))
        
        if !keepLoading {
            deInitImport([importFilePath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
            return
        }
        
        self.fileManager.initImport()
        
        let epubManager: EpubManager = EpubManager.sharedInstance
        epubManager.detectEpubStandard(expandDir, didSuccess: { (path) -> Void in
            Log(NSString(format: "success. path:%@", path!))
            
            if !self.keepLoading {
                self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                return
            }
            
            let queue: dispatch_queue_t = dispatch_queue_create("loadMetaData", nil)
            dispatch_async(queue, { () -> Void in
                
                epubManager.loadMetadata(expandDir, containerPath: path!, didSuccess: { (epub) -> Void in
                    // メタ情報の読み込みに成功
                    Log(NSString(format: "success to get metadata. paths:%@", epub.navigation.contentsPaths))
                    Log(NSString(format: "epub: title:%@ language:%@", epub.metadata.title, epub.metadata.language))
                    
                    if !self.keepLoading {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    let saveFilePath = self.fileManager.loadXmlFiles(epub.navigation.contentsPaths, saveDir:expandDir, metadata: epub.metadata)
                    if !self.keepLoading {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    if saveFilePath == "" {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.FailedToLoadFile, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 本棚へ登録
                    var result = self.fileManager.saveToBook(saveFilePath)
                    if result != TTErrorCode.Normal {
                        self.deInitImport([importFilePath, expandDir], errorCode: result, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 図書情報をDBに保存
                    var book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
                    book.title = epub.metadata.title
                    book.language = epub.metadata.language
                    book.filename = saveFilePath.lastPathComponent.stringByDeletingPathExtension
                    book.sort_num = self.getBookList().count
                    var ret = self.dataManager.save()
                    if ret != TTErrorCode.Normal {
                        self.deInitImport([importFilePath, expandDir], errorCode: ret, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 終了処理
                    self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                }, didFailure: { (errorCode) -> Void in
                    LogE(NSString(format: "[%d]Failed to load metadata. dir:%@", errorCode.rawValue, expandDir))
                    self.deInitImport([importFilePath, expandDir], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
                })
            })
            
        }) { (errorCode) -> Void in
            LogE(NSString(format: "[%d]Invalid directory format. dir:%@", errorCode.rawValue, expandDir))
            self.deInitImport([importFilePath, expandDir], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
        }
        
    }
    
    //
    // 読み込みキャンセル
    //
    func cancelImport() {
        self.fileManager.cancelLoad()
        keepLoading = false
    }
    
    func getImportedFiles()->[String] {

        // 取り込み先ディレクトリ
        let bookDir = FileManager.getImportDir()
        if !(fileManager.exists(bookDir)) {
            return []
        }

        var result:[String] = []
        let files = self.fileManager.fileManager.contentsOfDirectoryAtPath(bookDir, error: nil)!
        for file in files {
            var file:String = file as! String
            result.append(file)
        }
        return result
    }
    
    //
    // 保存済み図書リストを取得
    //
    func getBookList()->[BookEntity] {
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: false)
        let results: [BookEntity] = self.dataManager.find(DataManager.Const.kBookEntityName, condition: nil, sort: [sortDescriptor]) as! [BookEntity]

        return results
    }
    
    // 図書ファイルを削除
    func deleteBook(book: BookEntity)->TTErrorCode {
        // ファイル削除
        let filepath: String = FileManager.getImportDir().stringByAppendingPathComponent(book.filename)
        let fileResult: TTErrorCode = self.fileManager.removeFile(filepath)
        Log(NSString(format: "remove file:%@", filepath))
        if fileResult != TTErrorCode.Normal {
            return fileResult
        }
        
        // 完了したらDBからも削除
        var dbResult: TTErrorCode = self.dataManager.remove(book)
        
        return dbResult
    }
    
    //
    // MARK: Private
    //
    
    //
    // 終了時の共通処理
    //
    func deInitImport(deleteFilePaths: [String], errorCode: TTErrorCode, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        self.keepLoading = true
        self.fileManager.deInitImport(deleteFilePaths)
        if errorCode == TTErrorCode.Normal {
            self.delegate?.importCompleted()
            didSuccess()
        } else {
            self.delegate?.importFailed()
            didFailure(errorCode: errorCode)
        }
    }
}