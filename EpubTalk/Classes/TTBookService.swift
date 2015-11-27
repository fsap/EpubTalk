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


enum BookCommand: Int {
    case None = -1
    case Copy = 1,
    Cut
}

//
// ブックファイル管理クラス
//
class TTBookService {
    
    var fileManager: FileManager = FileManager.sharedInstance
    var dataManager: DataManager = DataManager.sharedInstance
    
    var delegate: BookServiceDelegate?
    
    var bookCommand: BookCommand
    var clipboard: BookEntity?
//    var copiedBook: BookEntity?
//    var cutBook: BookEntity?
    
    private var keepLoading: Bool
    
    class var sharedInstance : TTBookService {
        struct Static {
            static let instance : TTBookService = TTBookService()
        }
        return Static.instance
    }
    
    init () {
        self.keepLoading = true
        self.clipboard = nil
        self.bookCommand = .None
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
            shelfObject.trace()
//            Log(NSString(format: "***** shelf object updated. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
//                shelfObject.type,
//                shelfObject.target_id,
//                shelfObject.name,
//                shelfObject.sort_num,
//                shelfObject.create_time
//            ))
        }
        
        // 図書本体の登録
        let book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
        book.book_id = DataManager.createUUID()
        book.title = epub.metadata.title
        book.language = epub.metadata.language
        book.filename = saveFileUrl.URLByDeletingPathExtension!.lastPathComponent!
        book.folder_id = SystemFolderID.Root.rawValue
//        book.sort_num = nil
        book.trace()
        
        // 表示オブジェクトとして登録
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Book.rawValue
        newShelfObject.target_id = book.book_id
        newShelfObject.name = book.title
        newShelfObject.sort_num = 1
        newShelfObject.create_time = NSDate()
        newShelfObject.trace()
        
        let ret = self.dataManager.save()
//        Log(NSString(format: "***** book saved. id:%@ title:%@ lang:%@ filename:%@",
//            book.book_id,
//            book.title,
//            book.language,
//            book.filename
//        ))
//        Log(NSString(format: "***** shelf object saved. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
//            newShelfObject.type,
//            newShelfObject.target_id,
//            newShelfObject.name,
//            newShelfObject.sort_num,
//            newShelfObject.create_time
//        ))
        
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
    // MARK: DB Operation
    //
    
    // MARK: Get
    
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
    
    // 本棚オブジェクトをIDで検索
    func getShelfObjectById(type: String, targetId: String)->ShelfObjectEntity? {
        let predicate: NSPredicate = NSPredicate(format: "type = %@ AND target_id = %@", type, targetId)
        let results: [ShelfObjectEntity]? = self.dataManager.find(
            DataManager.Const.kShelfObjectEntityName,
            condition: predicate,
            sort: nil,
            limit: 1
            ) as! [ShelfObjectEntity]?
        
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
    
    // フォルダIDで検索
    func getFolderById(folderId: String)->FolderEntity? {
        let predicate = NSPredicate(format: "folder_id = %@", folderId)
        let results: [FolderEntity]? = self.dataManager.find(
            DataManager.Const.kFolderEntityName,
            condition: predicate,
            sort: nil,
            limit: 1
            ) as! [FolderEntity]?
        Log(NSString(format: "result books:%@", (results != nil) ? results! : "None"))
        
        if results == nil {
            return nil
        }
        return results!.first
    }
    
    // フォルダ内図書を検索
    func getBooksInFolder(folderId: String)->[BookEntity]? {
        let predicate = NSPredicate(format: "folder_id = %@", folderId)
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: true)
        let results: [BookEntity]? = self.dataManager.find(
            DataManager.Const.kBookEntityName,
            condition: predicate,
            sort: [sortDescriptor],
            limit: nil
            ) as! [BookEntity]?
        Log(NSString(format: "result books:%@", (results != nil) ? results! : "None"))
        
        return results
    }
    
    // MARK: Create
    
    // フォルダを作成
    func createFolder(folderName: String?)->TTErrorCode {
        
        // Validation
        if let errorCode: TTErrorCode = Validator.validateName(folderName) {
            if errorCode != TTErrorCode.Normal {
                return errorCode
            }
        }
        
        // 重複をチェック
        if self.getFolderByName(folderName!) != nil {
            return TTErrorCode.DuplicateFolderName
        }
        
        // フォルダを登録
        let newFolder: FolderEntity = self.dataManager.getEntity(DataManager.Const.kFolderEntityName) as! FolderEntity
        newFolder.folder_id = DataManager.createUUID()
        newFolder.name = folderName!
        newFolder.trace()
        
        // 表示オブジェクトとして登録
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Folder.rawValue
        newShelfObject.target_id = newFolder.folder_id
        newShelfObject.name = newFolder.name
        newShelfObject.sort_num = self.getShelfObjectList().count + 1
        newShelfObject.create_time = NSDate()
        newShelfObject.trace()
        
        let ret = self.dataManager.save()
//        Log(NSString(format: "***** folder saved. id:%@ name:%@",
//            newFolder.folder_id,
//            newFolder.name
//            ))
//        
//        Log(NSString(format: "***** shelf object saved. type:%@ target_id:%@ name:%@ sort:%@ create_time:%@",
//            newShelfObject.type,
//            newShelfObject.target_id,
//            newShelfObject.name,
//            newShelfObject.sort_num,
//            newShelfObject.create_time
//            ))
        
        return ret
    }
    
    // フォルダを更新
    func updateFolder(folderId: String, folderName: String?)->TTErrorCode {
        
        // Validation
        if let errorCode: TTErrorCode = Validator.validateName(folderName) {
            if errorCode != TTErrorCode.Normal {
                return errorCode
            }
        }
        
        // 重複をチェック
        if self.getFolderByName(folderName!) != nil {
            return TTErrorCode.DuplicateFolderName
        }
        
        let folder: FolderEntity = self.getFolderById(folderId)!
        folder.name = folderName!
        folder.trace()
        
        // 表示オブジェクトの更新
        let shelfObject: ShelfObjectEntity = self.getShelfObjectById(ShelfObjectTypes.Folder.rawValue, targetId: folderId)!
        shelfObject.name = folderName!
        shelfObject.trace()
        
        return self.dataManager.save()
    }
    
    // MARK: Update

    //
    // 渡された本棚オブジェクトリストの順番にソートを更新する
    //
    func refreshSort(shelfObjectList: [ShelfObjectEntity])->TTErrorCode {
        for (index, shelfObject): (Int, ShelfObjectEntity) in shelfObjectList.enumerate() {
            shelfObject.sort_num = index+1
        }
        return self.dataManager.save()
    }
    
    //
    // 渡された図書オブジェクトリストの順番にソートを更新する
    //
    func refreshSort(bookList: [BookEntity])->TTErrorCode {
        for (index, book): (Int, BookEntity) in bookList.enumerate() {
            book.sort_num = index+1
        }
        return self.dataManager.save()
    }
    
    // MARK: Delete
    
    // 本棚表示オブジェクトを削除
    func deleteShelfObject(shelfObject: ShelfObjectEntity)->TTErrorCode {
        let dbResult: TTErrorCode = self.dataManager.remove(shelfObject)
        
        return dbResult
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
    
    // フォルダを削除
    func deleteFolder(folder: FolderEntity)->TTErrorCode {
        let books: [BookEntity]? = self.getBooksInFolder(folder.folder_id)
        // 中が空でない
        if books != nil && books?.count > 0 {
            return TTErrorCode.CannotDeleteFolder
        }
        
        let dbResult: TTErrorCode = self.dataManager.remove(folder)
        
        return dbResult
    }
    
    // 図書をコピー
    func copyBook(book: BookEntity?) {
//        self.copiedBook = book
        self.clipboard = book
        self.bookCommand = .Copy
    }
    
    // 図書を切り取り
    func cutBook(book: BookEntity?) {
//        self.cutBook = book
        self.bookCommand = .Cut
        self.clipboard = book
    }
    
    func clearClipboard() {
        self.bookCommand = .None
        self.clipboard = nil
    }
    
    
    //
    // MARK: Book Operation
    //
    
    // 図書をペースト
    func pasteBook(folder: FolderEntity?)->TTErrorCode {
        if self.clipboard == nil {
            return TTErrorCode.FailedToPasteBook
        }
        
        Log(NSString(format: "source book:%@", self.clipboard!))
        var retCode: TTErrorCode?
        switch self.bookCommand {
        case .Copy:
            // フォルダへのコピー
            if folder != nil {
                retCode = self.moveBookToFolder(self.clipboard!, folder: folder!, copyFlg: true)
            // 本棚へのコピー
            } else {
                retCode = self.moveBookToShelf(self.clipboard!, copyFlg: true)
            }
            
        case .Cut:
            // フォルダへの移動
            if folder != nil {
                retCode = self.moveBookToFolder(self.clipboard!, folder: folder!, copyFlg: false)
            // 本棚への移動
            } else {
                retCode = self.moveBookToShelf(self.clipboard!, copyFlg: false)
            }
            
        default:
            retCode = .FailedToPasteBook
            break
        }
        return retCode!
    }
    
    func moveBookToFolder(fromBook: BookEntity, folder: FolderEntity, copyFlg: Bool)->TTErrorCode {
        
        // 重複チェック
        var booksInFolder: [BookEntity]? = self.getBooksInFolder(folder.folder_id)
        if booksInFolder != nil {
            for book: BookEntity in booksInFolder! {
                if book.book_id == fromBook.book_id {
                    return .DuplicateBook
                }
            }
        }
        
        if copyFlg {
            let newBookEntity: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
            newBookEntity.folder_id = folder.folder_id
            newBookEntity.book_id = DataManager.createUUID()
            newBookEntity.title = fromBook.title
            newBookEntity.language = fromBook.language
            newBookEntity.sort_num = 1
            // ToDo
            newBookEntity.filename = fromBook.filename
            newBookEntity.trace()
            
            if booksInFolder != nil {
                booksInFolder!.insert(newBookEntity, atIndex: 0)
            }
            
        } else {
            fromBook.folder_id = folder.folder_id
            fromBook.sort_num = 1
            fromBook.trace()
            
            // 移動元の表示オブジェクトがあれば消す
            let shelfObject: ShelfObjectEntity? = self.getShelfObjectById(ShelfObjectTypes.Book.rawValue, targetId: fromBook.book_id)
            if shelfObject != nil {
                shelfObject!.trace()
                self.dataManager.remove(shelfObject!)
            }

            if booksInFolder != nil {
                booksInFolder!.insert(fromBook, atIndex: 0)
            }
        }
        
        // 並べ替え
        if booksInFolder!.count > 1 {
            return self.refreshSort(booksInFolder!)
        }
        
        return self.dataManager.save()
    }
    
    func moveBookToShelf(fromBook: BookEntity, copyFlg: Bool)->TTErrorCode {
        
        // 重複チェック
        var shelfObjects: [ShelfObjectEntity]? = self.getShelfObjectList()
        if shelfObjects != nil {
            for shelfObject: ShelfObjectEntity in shelfObjects! {
                if shelfObject.type == ShelfObjectTypes.Book.rawValue && shelfObject.target_id == fromBook.book_id {
                    return .DuplicateBook
                }
            }
        }
        
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        if copyFlg {
            
            let newBookEntity: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
            newBookEntity.book_id = DataManager.createUUID()
            newBookEntity.folder_id = SystemFolderID.Root.rawValue
            newBookEntity.title = fromBook.title
            newBookEntity.language = fromBook.language
            newBookEntity.sort_num = 1
            // ToDo
            newBookEntity.filename = fromBook.filename
            newBookEntity.trace()
            
            // 表示オブジェクトとして登録
            newShelfObject.type = ShelfObjectTypes.Book.rawValue
            newShelfObject.target_id = fromBook.book_id
            newShelfObject.name = fromBook.title
            newShelfObject.sort_num = 1
            newShelfObject.create_time = NSDate()

        } else {
            fromBook.folder_id = SystemFolderID.Root.rawValue
            fromBook.sort_num = 1
            fromBook.trace()
            
            newShelfObject.type = ShelfObjectTypes.Book.rawValue
            newShelfObject.target_id = fromBook.book_id
            newShelfObject.name = fromBook.title
            newShelfObject.sort_num = 1
            newShelfObject.create_time = NSDate()
        }
        newShelfObject.trace()
        
        // 並べ替え
        if shelfObjects != nil {
            shelfObjects!.insert(newShelfObject, atIndex: 1)
            return self.refreshSort(shelfObjects!)
        }
        
        return self.dataManager.save()
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