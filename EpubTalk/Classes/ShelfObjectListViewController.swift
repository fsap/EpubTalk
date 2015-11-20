//
//  ShelfObjectListViewController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/05.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

protocol ShelfObjectListViewDelegate {
    func needRedraw(view: UIView, message: String)
}

class ShelfObjectListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BookServiceDelegate, LoadingViewDelegate {
    
    struct Const {
        static let kBookListViewLineHeight :CGFloat = 64.0
    }

    @IBOutlet weak var ShelfObjectListTableView: UITableView!
    @IBOutlet weak var createFolderButton: UIButton!
    
    let bookService: TTBookService = TTBookService.sharedInstance
    var shelfObjectList :[ShelfObjectEntity] = []
//    var manager: DataManager = DataManager.sharedInstance
    var alertController: TTAlertController = TTAlertController(nibName: nil, bundle: nil)
    let createFolderViewController: CreateFolderViewController = CreateFolderViewController(nibName: nil, bundle: nil)
    let purchaseConfirmViewController: PurchaseConfirmViewController = PurchaseConfirmViewController(nibName: nil, bundle: nil)
    var loadingView: LoadingView?
    var delegate: ShelfObjectListViewDelegate?
    
    
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
        self.ShelfObjectListTableView.delegate = self
        // create folder
        self.createFolderButton.setTitle(NSLocalizedString("new_folder_button", comment: ""), forState: .Normal)
        
        // ロード中だったらローディング画面へ
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.loadingFlg {
            self.startLoading()
        }
        
        self.bookService.delegate = self
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.shelfObjectList = bookService.getShelfObjectList()
        self.reload()
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        LogM("Lotation")
        self.delegate?.needRedraw(self.parentViewController!.view, message: NSLocalizedString("msg_loading", comment: ""))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 編集モードへの切り替え
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.ShelfObjectListTableView?.setEditing(editing, animated: animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        Log(NSString(format: "--- segue id :%@ sender:%@", segue.identifier!, sender))
        if segue.identifier == "bookListView" {
//            let folder: FolderEntity = sender as! FolderEntity
            let folderId: String = sender as! String
            let folder: FolderEntity = self.bookService.getFolderById(folderId)!
            let bookListViewController: BookListViewController = segue.destinationViewController as! BookListViewController
            bookListViewController.folder = folder
        }
    }
    
    //
    // MARK: Private
    //
    
    // help
    func leftBarButtonTapped(button: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: NSLocalizedString("link_help", comment: ""))!)
    }
    
    // 再読み込み
    private func reload()->Void {
        self.ShelfObjectListTableView.reloadData()
    }
    
    // ローディング中の処理
    private func startLoading()->Void {
        LogM("start loading")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView = LoadingView(parentView: self.parentViewController!.view, message: NSLocalizedString("msg_loading", comment: ""))
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
    
    // メッセージダイアログ
    private func showMessageDialog(message: String, didOk:(()->Void)?)->Void {
        alertController.show(
            self,
            title: NSLocalizedString("dialog_title_notice", comment: ""),
            message: message, actionOk: {() -> Void in
                if didOk != nil {
                    didOk!()
                }
        })
    }
    
    // エラーダイアログ
    private func showErrorDialog(errorCode: TTErrorCode, didOk:(()->Void)?)->Void {
        alertController.show(
            self,
            title: NSLocalizedString("dialog_title_error", comment: ""),
            message: TTError.getErrorMessage(errorCode), actionOk: {() -> Void in
                if didOk != nil {
                    didOk!()
                }
        })
    }
    
    // フォルダ名入力ダイアログ
    private func showCreateFolderDialog() {
        self.createFolderViewController.show(
            self,
            actionOk: { (inputText) -> Void in
                self.createFolder(inputText)
            },
            actionCancel: {() -> Void in})
    }
    
    // 課金確認ダイアログ
    private func showPurchaseDialog() {
        self.purchaseConfirmViewController.show(self,
            actionPurchase: { () -> Void in
                
            }, actionRestore: { () -> Void in
                //
            }, actionCancel: nil)
    }
    
    // フォルダ作成
    private func createFolder(newFolderName: String?) {
        let ret = self.bookService.createFolder(newFolderName!)
        if ret == TTErrorCode.Normal {
            // ToDo: ダイアログいるか確認
            self.showMessageDialog(NSLocalizedString("dialog_msg_folder_created", comment: ""), didOk: {() -> Void in
                self.shelfObjectList = self.bookService.getShelfObjectList()
                self.ShelfObjectListTableView.reloadData()
            })
            
        } else {
            self.showErrorDialog(ret, didOk: nil)
        }
    }
    
    // 図書削除
    private func deleteBook(shelfObject: ShelfObjectEntity)->TTErrorCode {
        let book: BookEntity = self.bookService.getBookById(shelfObject.target_id)!
        var result: TTErrorCode = self.bookService.deleteBook(book)
        if result != TTErrorCode.Normal {
            return result
        }
        
        result = self.bookService.deleteShelfObject(shelfObject)
        return result
    }
    
    // フォルダ削除
    private func deleteFolder(shelfObject: ShelfObjectEntity)->TTErrorCode {
        let folder: FolderEntity = self.bookService.getFolderById(shelfObject.target_id)!
        var result: TTErrorCode = self.bookService.deleteFolder(folder)
        if result != TTErrorCode.Normal {
            return result
        }

        result = self.bookService.deleteShelfObject(shelfObject)
        return result
    }
    
    
    //
    // MARK: IBAction
    //
    @IBAction func createNewFolderTapped(sender: AnyObject) {
        LogM("Create New Folder.")
        self.showCreateFolderDialog()
    }
    
    @IBAction func purchaseButtonTapped(sender: AnyObject) {
        LogM("Purchase Button.")
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
        return shelfObjectList.count
    }
    
    // 行の高さ
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Const.kBookListViewLineHeight
    }
    
    // セルの設定
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        let shelfObject = shelfObjectList[indexPath.row]
        cell.textLabel?.text = shelfObject.name
        if shelfObject.type == ShelfObjectTypes.Folder.rawValue {
            cell.detailTextLabel?.text = "(フォルダ)"
        }

        return cell
    }
    
    // セルが選択された
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let shelfObject: ShelfObjectEntity = self.shelfObjectList[indexPath.row]
        Log(NSString(format: "--- selected shelf object. title:%@ target_id:%@", shelfObject.name, shelfObject.target_id))
        
        if shelfObject.type == ShelfObjectTypes.Folder.rawValue {
            self.performSegueWithIdentifier("bookListView", sender: shelfObject.target_id)
        }
        
//        // Debug
//        let fileManager: NSFileManager = NSFileManager.defaultManager()
//        let attr = try! fileManager.attributesOfItemAtPath(NSString(format: "%@/%@.tdv", FileManager.getImportDir(book.filename).path!, book.filename) as String)
//        Log(NSString(format: "--- selected book. file:%@ attr:%@", book.filename, attr))
    }
    
    // 編集可否の設定
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 編集時のスタイル(このメソッドを定義するとスワイプで編集メニューが無効になる)
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
/*
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        if (self.editing) {
            let shelfObject: ShelfObjectEntity = self.shelfObjectList[indexPath.row]
            switch shelfObject.type {
            case ShelfObjectTypes.Folder.rawValue:
                return .Insert
            case ShelfObjectTypes.Book.rawValue:
                return .Delete
            default:
                return .None
            }
        }
*/
        return .Delete
    }
    
    
    // 編集アクション
    @available(iOS 8.0, *)
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let shelfObject: ShelfObjectEntity = self.shelfObjectList[indexPath.row]
        var actions: [UITableViewRowAction] = []
        
        // 共通
        let deleteAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_delete", comment: "")) { (action, indexPath) -> Void in
            LogM("delete.")
            var actionOk: (() -> Void) = {}
            if shelfObject.type == ShelfObjectTypes.Book.rawValue {
                actionOk = {
                    let result: TTErrorCode = self.deleteBook(shelfObject)
                    if result == TTErrorCode.Normal {
                        self.shelfObjectList.removeAtIndex(indexPath.row)
                        self.ShelfObjectListTableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                        self.reload()
                    } else {
                        self.alertController.show(self,
                            title: NSLocalizedString("dialog_title_error", comment: ""),
                            message: TTError.getErrorMessage(result), actionOk: { () -> Void in})
                    }
                }
            }
            if shelfObject.type == ShelfObjectTypes.Folder.rawValue {
                actionOk = {
                    let result: TTErrorCode = self.deleteFolder(shelfObject)
                    if result == TTErrorCode.Normal {
                        self.shelfObjectList.removeAtIndex(indexPath.row)
                        self.ShelfObjectListTableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                        self.reload()
                    } else {
                        self.alertController.show(self,
                            title: NSLocalizedString("dialog_title_error", comment: ""),
                            message: TTError.getErrorMessage(result), actionOk: { () -> Void in})
                    }
                }
            }
            
            self.alertController.show(self,
                title: NSLocalizedString("dialog_title_notice", comment: ""),
                message: NSLocalizedString("dialog_msg_delete", comment: ""),
                actionOk: actionOk, actionCancel:nil)
        }
        deleteAction.backgroundColor = UIColor.redColor()
        actions.append(deleteAction)
        
        switch shelfObject.type {
        case ShelfObjectTypes.Folder.rawValue:
            // フォルダ名変更
            let changeTitleAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_change_title", comment: "")) { (action, indexPath) -> Void in
                LogM("change title.")
                self.showCreateFolderDialog()
            }
            changeTitleAction.backgroundColor = UIColor.greenColor()
            actions.append(changeTitleAction)
            break
        case ShelfObjectTypes.Book.rawValue:
            // コピー
            let copyAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_copy", comment: "")) { (action, indexPath) -> Void in
                LogM("copy book.")
                // コピーする
                self.bookService.copyBook(self.bookService.getBookById(shelfObject.target_id)!)
                
                self.showMessageDialog(NSLocalizedString("dialog_msg_copy_done", comment: ""), didOk: nil)
            }
            copyAction.backgroundColor = UIColor.greenColor()
            actions.append(copyAction)
            
            // 切り取り
            let cutAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_cut", comment: "")) { (action, indexPath) -> Void in
                LogM("cut book.")
                // カットする
                self.bookService.copyBook(self.bookService.getBookById(shelfObject.target_id)!)
                
                self.showMessageDialog(NSLocalizedString("dialog_msg_cut_done", comment: ""), didOk: nil)
            }
            cutAction.backgroundColor = UIColor.greenColor()
            actions.append(cutAction)
            break
        default:
            break
        }
        
        return actions
    }
    
    // 編集の確定タイミングで呼ばれる
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
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

        let sourceObj: ShelfObjectEntity = self.shelfObjectList[sourceIndexPath.row]
        self.shelfObjectList.removeAtIndex(sourceIndexPath.row)
        self.shelfObjectList.insert(sourceObj, atIndex: destinationIndexPath.row)
        bookService.refreshSort(self.shelfObjectList)
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
            self.shelfObjectList = TTBookService.sharedInstance.getShelfObjectList()
            self.ShelfObjectListTableView.reloadData()
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
        let bookService: TTBookService = TTBookService.sharedInstance
        bookService.cancelImport()
    }
}