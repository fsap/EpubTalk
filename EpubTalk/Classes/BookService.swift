//
//  BookService.swift
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
class BookService {
    
    var fileManager: FileManager = FileManager.sharedInstance
    var dataManager: DataManager = DataManager.sharedInstance
    
    var delegate: BookServiceDelegate?
    
    var bookCommand: BookCommand
    var clipboard: ShelfObjectEntity?
    
    private var keepLoading: Bool
    
    class var sharedInstance : BookService {
        struct Static {
            static let instance : BookService = BookService()
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
    // MARK: File Operation
    //
    
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
    func getRootShelfObjects()->[ShelfObjectEntity] {
        let predicate: NSPredicate = NSPredicate(format: "folder_id = %@", SystemFolderID.Root.rawValue)
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: true)
        let results: [ShelfObjectEntity]? = self.dataManager.find(
            DataManager.Const.kShelfObjectEntityName,
            condition: predicate,
            sort: [sortDescriptor],
            limit: nil
        ) as! [ShelfObjectEntity]?

        if results == nil {
            return []
        }
        Log(NSString(format: "results:%@", results!))
        return results!
    }
    
    // オブジェクト一覧を取得
    func getShelfObjectsByFolder(type: ShelfObjectTypes, folderId: String)->[ShelfObjectEntity] {
        // validation
        let ret: TTErrorCode = Validator.validateId(folderId)
        if ret != .Normal {
            Log(NSString(format: "Invalid id:%@", folderId))
            return []
        }
        
        let predicate: NSPredicate = NSPredicate(format: "type = %@ AND folder_id = %@", type.rawValue, folderId)
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: true)
        let results: [ShelfObjectEntity]? = self.dataManager.find(
            DataManager.Const.kShelfObjectEntityName,
            condition: predicate,
            sort: [sortDescriptor],
            limit: nil
            ) as! [ShelfObjectEntity]?
        
        if results == nil {
            return []
        }
        Log(NSString(format: "results:%@", results!))
        return results!
    }
    
    // オブジェクトをIDで検索
    func getShelfObjectsByObjectId(type: ShelfObjectTypes, objectId: String)->[ShelfObjectEntity]? {
        // validation
        let ret: TTErrorCode = Validator.validateId(objectId)
        if ret != .Normal {
            return []
        }

        let predicate: NSPredicate = NSPredicate(format: "type = %@ AND object_id = %@", type.rawValue, objectId)
        let results: [ShelfObjectEntity]? = self.dataManager.find(
            DataManager.Const.kShelfObjectEntityName,
            condition: predicate,
            sort: nil,
            limit: nil
            ) as! [ShelfObjectEntity]?
        
        if results == nil {
            return []
        }
        Log(NSString(format: "results:%@", results!))
        return results!
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
    
    
    // MARK: Create
    
    // 図書を作成
    func saveBook(epub: Epub, saveFileUrl: NSURL)->TTErrorCode {
        // 表示オブジェクトの並び順更新
        for shelfObject in self.getRootShelfObjects() {
            let sort: Int = shelfObject.sort_num.integerValue
            shelfObject.sort_num = sort+1
            shelfObject.trace()
        }
        
        // 図書本体の登録
        let book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
        book.book_id = DataManager.createUUID()
//        book.folder_id = SystemFolderID.Root.rawValue
        book.title = epub.metadata.title
        book.language = epub.metadata.language
        book.filename = saveFileUrl.URLByDeletingPathExtension!.lastPathComponent!
//        book.sort_num = nil
        book.trace()
        
        // 表示オブジェクトとして登録
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Book.rawValue
        newShelfObject.folder_id = SystemFolderID.Root.rawValue
        newShelfObject.object_id = book.book_id
        newShelfObject.name = book.title
        newShelfObject.sort_num = 1
        newShelfObject.create_time = NSDate()
        newShelfObject.trace()
        
        return self.dataManager.save()
    }
    
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
        newShelfObject.folder_id = SystemFolderID.Root.rawValue
        newShelfObject.object_id = newFolder.folder_id
        newShelfObject.name = newFolder.name
        newShelfObject.sort_num = self.getRootShelfObjects().count + 1
        newShelfObject.create_time = NSDate()
        newShelfObject.trace()
        
        return self.dataManager.save()
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
        let shelfObjects: [ShelfObjectEntity] = self.getShelfObjectsByObjectId(ShelfObjectTypes.Folder, objectId: folderId)!
        for shelfObject: ShelfObjectEntity in shelfObjects {
            shelfObject.name = folderName!
            shelfObject.trace()
        }
        
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
        
        var ret: TTErrorCode
        switch shelfObject.type {
            // フォルダ削除
        case ShelfObjectTypes.Folder.rawValue:
            ret = self.deleteFolder(shelfObject)
            break
            
            // 図書削除
        case ShelfObjectTypes.Book.rawValue:
            ret = self.deleteBook(shelfObject)
            break
            
        default:
            ret = .InternalError
            break
        }
        
        if ret != .Normal {
            return ret
        }
        return self.dataManager.save()
    }
    
    // フォルダを削除
    private func deleteFolder(shelfObject: ShelfObjectEntity)->TTErrorCode {
        // フォルダ内オブジェクト
        let bookObjects: [ShelfObjectEntity] = self.getShelfObjectsByFolder(.Book, folderId: shelfObject.object_id)
        if bookObjects.count > 0 {
            // 中身が空でなければ消せない
            return TTErrorCode.CannotDeleteFolder
        }
        
        // フォルダを削除
        let folder: FolderEntity = self.getFolderById(shelfObject.object_id)!
        let result: TTErrorCode = self.dataManager.remove(folder)
        if result != .Normal {
            return result
        }
        
        return self.dataManager.remove(shelfObject)
    }
    
    // 図書を削除
    private func deleteBook(shelfObject: ShelfObjectEntity)->TTErrorCode {
        // 複数ある場合はエイリアス削除のみ
        let bookObjects: [ShelfObjectEntity] = self.getShelfObjectsByObjectId(.Book, objectId: shelfObject.object_id)!
        if bookObjects.count > 1 {
            return self.dataManager.remove(shelfObject)
        }
        
        // 図書本体を削除
        let book: BookEntity = self.getBookById(shelfObject.object_id)!
        
        // ファイルから削除する
        var result: TTErrorCode = self.fileManager.removeFile(FileManager.getImportDir(book.filename).path!)
        if result != TTErrorCode.Normal {
            return result
        }

        // DBからも削除
        result = self.dataManager.remove(book)
        if result != TTErrorCode.Normal {
            return result
        }
        
        return self.dataManager.remove(shelfObject)
    }
    

    //
    // MARK: Book Operation
    //
    
    // オブジェクトをコピー
    func copyObject(object: ShelfObjectEntity?) {
        self.clipboard = object
        self.bookCommand = .Copy
    }
    
    // オブジェクトを切り取り
    func cutObject(object: ShelfObjectEntity?) {
        self.clipboard = object
        self.bookCommand = .Cut
    }

    // クリップボードをクリア
    func clearClipboard() {
        self.bookCommand = .None
        self.clipboard = nil
    }
    
    // 図書をペースト
    func pasteBook(folderId: String)->TTErrorCode {
        if self.clipboard == nil {
            return TTErrorCode.FailedToPasteBook
        }
        
        Log(NSString(format: "source book:%@", self.clipboard!))
        var ret: TTErrorCode?
        switch self.bookCommand {
        case .Copy:
            ret = self.moveBookToFolder(self.clipboard!, folderId: folderId, copyFlg: true)
            break
            
        case .Cut:
            ret = self.moveBookToFolder(self.clipboard!, folderId: folderId, copyFlg: false)
            break
            
        default:
            ret = .FailedToPasteBook
            break
        }
        return ret!
    }
    
    func moveBookToFolder(fromObject: ShelfObjectEntity, folderId: String, copyFlg: Bool)->TTErrorCode {
        
        // 重複チェック
        var objectsInFolder: [ShelfObjectEntity] = self.getShelfObjectsByFolder(.Book, folderId: folderId)
        for object: ShelfObjectEntity in objectsInFolder {
            if object.object_id == fromObject.object_id {
                return .DuplicateBook
            }
        }
        
        let newShelfObject: ShelfObjectEntity = self.dataManager.getEntity(DataManager.Const.kShelfObjectEntityName) as! ShelfObjectEntity
        newShelfObject.type = ShelfObjectTypes.Book.rawValue
        newShelfObject.folder_id = folderId
        newShelfObject.object_id = fromObject.object_id
        newShelfObject.name = fromObject.name
        newShelfObject.sort_num = 1
        newShelfObject.create_time = NSDate()
        newShelfObject.trace()
        
        objectsInFolder.insert(newShelfObject, atIndex: 0)

        // 移動
        if !copyFlg {
            // 移動元の表示オブジェクトを消す
            self.dataManager.remove(fromObject)
        }
        
        // 並べ替え
        if objectsInFolder.count > 1 {
            return self.refreshSort(objectsInFolder)
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