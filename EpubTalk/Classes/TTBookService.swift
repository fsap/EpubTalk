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
    func validate(targetUrl :NSURL)->TTErrorCode {
        Log(NSString(format: "--- target path:%@", targetUrl.path!))
        
        if targetUrl == "" {
            return TTErrorCode.FailedToGetFile
        }
        let filename: String = targetUrl.lastPathComponent!.stringByRemovingPercentEncoding!
        
        // ファイルの存在チェック
        if !(self.fileManager.exists(targetUrl.path!)) {
            Log(NSString(format: "%@ not found.", targetUrl.path!))
            return TTErrorCode.FileNotExists
        }
        
        // ファイル形式のチェック
        if !(FileManager.isValiedExtension(filename)) {
            Log(NSString(format: "Unsupported type:%@", filename))
            self.fileManager.removeFile(targetUrl.path!)
            return TTErrorCode.UnsupportedFileType
        }
        
        return TTErrorCode.Normal;
    }
    
    //
    // ファイルの取り込み
    //
    func importDaisy(sourceUrl :NSURL, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void))->Void {
        
        self.keepLoading = true
        
        let filename: String = sourceUrl.lastPathComponent!.stringByRemovingPercentEncoding!
        let tmpUrl: NSURL = FileManager.getTmpDir()
        let expandUrl: NSURL = tmpUrl.URLByAppendingPathComponent(filename).URLByDeletingPathExtension!
        
        // 外部から渡ってきたファイルのパス ex) sadbox/Documents/Inbox/What_Is_HTML5_.zip
        let sourcePath: String = sourceUrl.path!
        // 作業用ディレクトリ ex) sadbox/tmp/
        let tmpPath: String = tmpUrl.path!
        // 作業ファイル展開用ディレクトリ ex) sadbox/tmp/What_Is_HTML5_
        let expandPath: String = expandUrl.path!
        
        if (sourceUrl.pathExtension == Constants.kImportableExtensions[0]
            || sourceUrl.pathExtension == Constants.kImportableExtensions[1]) {
                // 圧縮ファイル展開
                if !(self.fileManager.unzip(sourcePath, expandPath: expandPath)) {
                    LogE(NSString(format: "Unable to expand path:%@ file:%@", sourceUrl, filename))
                    deInitImport([sourcePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
                    return
                }
                
        } else {
            LogE(NSString(format: "Unable to expand:%@", filename))
            deInitImport([sourcePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
            return
        }

        Log(NSString(format: "tmp_dir:%@", try! self.fileManager.fileManager.contentsOfDirectoryAtPath(tmpPath)))
        
        if !keepLoading {
            deInitImport([sourcePath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
            return
        }
        
        // 初期化
        self.fileManager.initImport()
        
        let epubManager: EpubManager = EpubManager.sharedInstance
        epubManager.searchMetaData(expandUrl, didSuccess: { (opfUrl) -> Void in
            // メタ情報の読み込みに成功
            Log(NSString(format: "success to get metadata. path:%@", opfUrl))
            
            if !self.keepLoading {
                self.deInitImport([sourcePath, expandPath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                return
            }
            
            let queue: dispatch_queue_t = dispatch_queue_create("loadMetaData", nil)
            dispatch_async(queue, { () -> Void in
                epubManager.loadContents(opfUrl, didSuccess: { (epub) -> Void in
                    // ナビゲーション情報の読み込みに成功
                    Log(NSString(format: "success to load navigation. contents paths:%@", epub.navigation.contentsPaths))
                    Log(NSString(format: "epub: title:%@ language:%@", epub.metadata.title, epub.metadata.language))
                    
                    if !self.keepLoading {
                        self.deInitImport([sourcePath, expandPath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    let saveFilePath = self.fileManager.loadHtmlFiles(epub.navigation.contentsPaths, saveUrl:expandUrl, metadata: epub.metadata)
                    if !self.keepLoading {
                        self.deInitImport([sourcePath, expandPath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    if saveFilePath == "" {
                        self.deInitImport([sourcePath, expandPath], errorCode: TTErrorCode.FailedToLoadFile, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 本棚へ登録
                    let result = self.fileManager.saveToBook(saveFilePath)
                    if result != TTErrorCode.Normal {
                        self.deInitImport([sourcePath, expandPath], errorCode: result, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 図書情報をDBに保存
                    /*
                    let book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
                    book.title = epub.metadata.title
                    book.language = epub.metadata.language
                    let saveFileUrl: NSURL = NSURL(fileURLWithPath: saveFilePath)
                    book.filename = saveFileUrl.URLByDeletingPathExtension!.lastPathComponent!
                    book.sort_num = self.getBookList().count
                    book.book_id = self.getBookList().count
                    let ret = self.dataManager.save()
                    */
                    let ret = self.saveBook(epub, saveFileUrl: NSURL(fileURLWithPath: saveFilePath))
                    if ret != TTErrorCode.Normal {
                        self.deInitImport([sourcePath, expandPath], errorCode: ret, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 終了処理
                    self.deInitImport([sourcePath, expandPath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)

                }, didFailure: { (errorCode) -> Void in
                    LogE(NSString(format: "[%d]Failed to load contents. dir:%@", errorCode.rawValue, expandPath))
                    self.deInitImport([sourcePath, expandPath], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
                })
            })

        }, didFailure: { (errorCode) -> Void in
            LogE(NSString(format: "[%d]Invalid directory format. dir:%@", errorCode.rawValue, expandPath))
            self.deInitImport([sourcePath, expandPath], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
        })
        
    }
    
    func saveBook(epub: Epub, saveFileUrl: NSURL)->TTErrorCode {
        // 表示オブジェクトの並び順更新
        for shelfObject in self.getShelfObjectList() {
            let sort: Int = shelfObject.sort_num.integerValue
            shelfObject.sort_num = sort+1
            Log(NSString(format: "***** shelf object updated. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
                shelfObject.type,
                shelfObject.target_id,
                shelfObject.name,
                shelfObject.sort_num,
                shelfObject.create_time
            ))
        }
        
        // 図書本体の登録
        let book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
        book.book_id = DataManager.createUUID()
        book.title = epub.metadata.title
        book.language = epub.metadata.language
        book.filename = saveFileUrl.URLByDeletingPathExtension!.lastPathComponent!
//        book.sort_num = nil
        
        // 表示オブジェクトとして登録
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Book.rawValue
        newShelfObject.target_id = book.book_id
        newShelfObject.name = book.title
        newShelfObject.sort_num = 1
        newShelfObject.create_time = NSDate()
        
        let ret = self.dataManager.save()
        Log(NSString(format: "***** book saved. id:%@ title:%@ lang:%@ filename:%@",
            book.book_id,
            book.title,
            book.language,
            book.filename
        ))
        Log(NSString(format: "***** shelf object saved. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
            newShelfObject.type,
            newShelfObject.target_id,
            newShelfObject.name,
            newShelfObject.sort_num,
            newShelfObject.create_time
        ))
        
        return ret
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
        let bookUrl: NSURL = FileManager.getImportDir(nil)
        if !(fileManager.exists(bookUrl.path!)) {
            return []
        }

        var result:[String] = []
        var files: [String] = []
        do {
            files = try self.fileManager.fileManager.contentsOfDirectoryAtPath(bookUrl.path!)
        } catch let error as NSError {
            LogE(NSString(format: "An error occurred. [%d][%@]", error.code, error.description))
        }
        for file in files {
            let file:String = file 
            result.append(file)
        }
        return result
    }
    
    //
    // 本棚に表示するオブジェクト一覧を取得
    //
    func getShelfObjectList()->[ShelfObjectEntity] {
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: true)
        let results: [ShelfObjectEntity] = self.dataManager.find(
            DataManager.Const.kShelfObjectEntityName,
            condition: nil,
            sort: [sortDescriptor],
            limit: nil
        ) as! [ShelfObjectEntity]

        return results
    }
    
    // フォルダを名前で検索
    func getFolderByName(folderName: String)->FolderEntity? {
        let predicate = NSPredicate(format: "name = %@", folderName)
        let results: [FolderEntity]? = self.dataManager.find(
            DataManager.Const.kFolderEntityName,
            condition: predicate,
            sort: nil,
            limit: 1
            ) as! [FolderEntity]?
        
        if results == nil {
            return nil
        }
        return results!.first
    }
    
    // 図書をIDで検索
    func getBookById(bookId: String)->BookEntity? {
        let predicate = NSPredicate(format: "book_id = %@", bookId)
        let results: [BookEntity]? = self.dataManager.find(
            DataManager.Const.kBookEntityName,
            condition: predicate,
            sort: nil,
            limit: 1
            ) as! [BookEntity]?
        
        if results == nil {
            return nil
        }
        return results!.first
    }
    
    // フォルダを作成
    func createFolder(folderName: String)->TTErrorCode {
        
        // 重複をチェック
        if self.getFolderByName(folderName) == nil {
            return TTErrorCode.DuplicateFolderName
        }
        
        // フォルダを登録
        let newFolder: FolderEntity = self.dataManager.getEntity(DataManager.Const.kFolderEntityName) as! FolderEntity
        newFolder.folder_id = DataManager.createUUID()
        newFolder.name = folderName
        
        // 表示オブジェクトとして登録
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Folder.rawValue
        newShelfObject.target_id = newFolder.folder_id
        newShelfObject.name = newFolder.name
        newShelfObject.sort_num = self.getShelfObjectList().count + 1
        newShelfObject.create_time = NSDate()
        
        let ret = self.dataManager.save()
        Log(NSString(format: "***** folder saved. id:%@ name:%@",
            newFolder.folder_id,
            newFolder.name
            ))
        
        Log(NSString(format: "***** shelf object saved. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
            newShelfObject.type,
            newShelfObject.target_id,
            newShelfObject.name,
            newShelfObject.sort_num,
            newShelfObject.create_time
            ))
        
        return ret
    }

    //
    // 渡されたリストの順番にソートを更新する
    //
    func refreshSort(shelfObjectList: [ShelfObjectEntity]) {
        for (index, shelfObject): (Int, ShelfObjectEntity) in shelfObjectList.enumerate() {
            shelfObject.sort_num = index+1
        }
        self.dataManager.save()
    }
    
    // 図書ファイルを削除
    func deleteBook(book: BookEntity)->TTErrorCode {
        // ファイル削除
        let fileUrl: NSURL = FileManager.getImportDir(book.filename)
        let fileResult: TTErrorCode = self.fileManager.removeFile(fileUrl.path!)
        Log(NSString(format: "remove file:%@", fileUrl.path!))
        if fileResult != TTErrorCode.Normal {
            return fileResult
        }
        
        // 完了したらDBからも削除
        let dbResult: TTErrorCode = self.dataManager.remove(book)
        
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