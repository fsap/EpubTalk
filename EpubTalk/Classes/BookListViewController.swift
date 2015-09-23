//
//  BookListViewController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/05.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

protocol BookListViewDelegate {
    func needRedraw(view: UIView)
}

class BookListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BookServiceDelegate, LoadingViewDelegate {
    
    struct Const {
        static let kBookListViewLineHeight :CGFloat = 64.0
    }

    @IBOutlet weak var bookListTableView: UITableView!
    
    var bookList :[BookEntity] = []
    var manager: DataManager = DataManager.sharedInstance
    var alertController: TTAlertController = TTAlertController(nibName: nil, bundle: nil)
    var loadingView: LoadingView?
    var delegate: BookListViewDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LogM("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
        // title
        self.navigationItem.title = NSLocalizedString("page_title_book_list", comment: "")
        self.navigationItem.accessibilityLabel = NSLocalizedString("page_title_book_list", comment: "")
        // help
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("button_title_help", comment: ""),
            style: .Plain,
            target: self,
            action: "leftBarButtonTapped:"
        )
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("button_title_help", comment: "")
        // edit
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.bookListTableView.delegate = self
        
        // ロード中だったらローディング画面へ
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.loadingFlg {
            self.startLoading()
        }
        
        var bookService = TTBookService.sharedInstance
        bookService.delegate = self
        
        self.bookList = bookService.getBookList()
//        if self.bookList.count == 0 {
//            self.createBooks()
//            self.bookList = TTBookService.sharedInstance.getBookList()
//        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        LogM("Lotation")
        self.delegate?.needRedraw(self.parentViewController!.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 編集モードへの切り替え
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.bookListTableView?.setEditing(editing, animated: animated)
    }
    
    //
    // MARK: Private
    //
    
    // help
    func leftBarButtonTapped(button: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: NSLocalizedString("link_help", comment: ""))!)
    }
    
    // 並び順をリフレッシュする
    private func refreshSort()->Void {
        for (index, book: BookEntity) in enumerate(self.bookList) {
            // 降順で並べるため
            book.sort_num = self.bookList.count - index
            self.manager.save()
        }
        self.bookListTableView.reloadData()
    }
    
    // ローディング中の処理
    private func startLoading()->Void {
        LogM("start loading")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView = LoadingView(parentView: self.parentViewController!.view)
            self.loadingView?.delegate = self
            self.delegate = self.loadingView
            self.loadingView?.start()
        })
    }
    
    // ローディング中のサウンド停止
    private func stopLoading()->Void {
        LogM("stop loading")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView?.stop()
        })
    }
    
    // test
    private func createBooks()->Void {
        
        for (var i=0; i<5; i++) {
            var book: BookEntity = self.manager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
            book.title = NSString(format: "title_%d", i) as String
            book.sort_num = i
            manager.save()
        }
    }
        
    
    //
    // MARK: UITableViewDelegate
    //
    
    // セクションの数
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        LogM("sections:[1]")
        return 1
    }
    
    // セクションあたり行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookList.count
    }
    
    // 行の高さ
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Const.kBookListViewLineHeight
    }
    
    // セルの設定
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        let book = bookList[indexPath.row]
        cell.textLabel?.text = book.title

        return cell
    }
    
    // セルが選択された
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let book: BookEntity = self.bookList[indexPath.row]
        Log(NSString(format: "--- selected book. title:%@ file:%@", book.title, book.filename))
        
        // Debug
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let attr = fileManager.attributesOfItemAtPath(NSString(format: "%@/%@.tdv", FileManager.getImportDir().stringByAppendingPathComponent(book.filename), book.filename) as String, error: nil)
        Log(NSString(format: "--- selected book. file:%@ attr:%@", book.filename, attr!))
    }
    
    // 編集可否の設定
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 編集時のスタイル
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        if (self.editing) {
            return .Delete
        }
        return .None
    }
    
    // 編集の確定タイミングで呼ばれる
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            // 確認を取る
            self.alertController.show(self,
                title: NSLocalizedString("dialog_title_notice", comment: ""),
                message: NSLocalizedString("dialog_msg_delete", comment: ""),
                actionOk: { () -> Void in
                    let book: BookEntity = self.bookList[indexPath.row]
                    var result: TTErrorCode = TTBookService.sharedInstance.deleteBook(book)
                    if result == TTErrorCode.Normal {
                        self.bookList.removeAtIndex(indexPath.row)
                        self.bookListTableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                        self.refreshSort()
                    } else {
                        self.alertController.show(self,
                            title: NSLocalizedString("dialog_title_error", comment: ""),
                            message: TTError.getErrorMessage(result), actionOk: { () -> Void in})
                    }
            }, actionCancel:nil)
            return
        default:
            return
        }
    }
    
    // 移動可否の設定
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 移動の確定タイミングで呼ばれる
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {

        var sourceBook: BookEntity = self.bookList[sourceIndexPath.row]
        self.bookList.removeAtIndex(sourceIndexPath.row)
        self.bookList.insert(sourceBook, atIndex: destinationIndexPath.row)
        self.refreshSort()
    }
    
    
    //
    // MARK: BookServiceDelegate
    //
    
    func importStarted() {
        LogM("import started.")
        
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.startLoading()
//        })
    }
    
    func importCompleted() {
        LogM("import completed.")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.stopLoading()
            self.view.backgroundColor = UIColor.whiteColor()
            self.bookList = TTBookService.sharedInstance.getBookList()
            self.bookListTableView.reloadData()
        })
    }
    
    func importFailed() {
        LogM("import failed.")
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.stopLoading()
//        })
    }
    
    //
    // MARK: LoadingViewDelegate
    //
    func cancelLoad() {
        var bookService: TTBookService = TTBookService.sharedInstance
        bookService.cancelImport()
    }
}