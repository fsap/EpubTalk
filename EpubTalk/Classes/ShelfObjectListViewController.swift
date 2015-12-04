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
//        static let kKeyValueObserverPath: String = "ChangeShelfObjectList"
        static let kBookListViewLineHeight :CGFloat = 64.0
    }

    // Property
    @IBOutlet weak var ShelfObjectListTableView: UITableView!
    @IBOutlet weak var createFolderButton: UIButton!
    @IBOutlet weak var pasteButton: UIButton!;
    @IBOutlet weak var purchaseButton: UIButton!;
    var shelfObjectList :[ShelfObjectEntity] = []
    var loadingView: LoadingView?
    var delegate: ShelfObjectListViewDelegate?

    // Service
    let bookService: BookService = BookService.sharedInstance
    let purchaseService: PurchaseService = PurchaseService.sharedInstance
    // Alert View
    var alertController: TTAlertController = TTAlertController(nibName: nil, bundle: nil)
    let createFolderViewController: CreateFolderViewController = CreateFolderViewController(nibName: nil, bundle: nil)
    let purchaseConfirmViewController: PurchaseConfirmViewController = PurchaseConfirmViewController(nibName: nil, bundle: nil)
    
    
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
        self.createFolderButton.accessibilityLabel = NSLocalizedString("new_folder_button", comment: "")
        // paste
        self.pasteButton.setTitle(NSLocalizedString("paste_button", comment: ""), forState: .Normal)
        self.pasteButton.accessibilityLabel = NSLocalizedString("paste_button", comment: "")
        // purchase
        self.purchaseButton.setTitle(NSLocalizedString("purchase_button", comment: ""), forState: .Normal)
        self.purchaseButton.accessibilityLabel = NSLocalizedString("purchase_button", comment: "")
        
        // ロード中だったらローディング画面へ
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.loadingFlg {
            self.startLoadingImport()
        }
        
        self.bookService.delegate = self
        
//        self.addObserver(self, forKeyPath: Const.kKeyValueObserverPath, options: .New, context: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.enablePasteButton()
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
    // MARK: --- Private ---
    //
    
    // MARK: UI Operation
    
    // 貼り付けボタンの有効化
    private func enablePasteButton() {
        if self.bookService.clipboard != nil {
            self.pasteButton.hidden = false
        }
    }
    
    // 図書インポート中ローディング開始
    private func startLoadingImport() {
        LogM("start loading")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView = LoadingView(parentView: self.parentViewController!.view, message: NSLocalizedString("msg_loading_import", comment: ""))
            self.loadingView?.delegate = self
            self.delegate = self.loadingView
            self.loadingView?.start()
        })
    }
    
    // 課金処理中ローディング開始
    private func startLoadingPurchase() {
        LogM("start loading")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView = LoadingView(parentView: self.parentViewController!.view, message: NSLocalizedString("msg_loading_purchase", comment: ""))
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
    
    // MARK: Dialog
    
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
    
    // MARK: Action
    
    // help
    func leftBarButtonTapped(button: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: NSLocalizedString("link_help", comment: ""))!)
    }
    
    // フォルダ名入力ダイアログ(新規)
    private func showCreateFolderDialog() {
        self.createFolderViewController.showCreate(
            self,
            actionOk: { (inputText) -> Void in
                self.createFolder(inputText)
            },
            actionCancel: {() -> Void in})
    }
    
    // フォルダ名入力ダイアログ(編集)
    private func showEditFolderDialog(folderId: String, name: String) {
        self.createFolderViewController.showEdit(
            self,
            name: name,
            actionOk: { (inputText) -> Void in
                self.updateFolder(folderId, newFolderName: inputText)
            },
            actionCancel: {() -> Void in})
    }
    
    // 課金確認ダイアログ
    private func showPurchaseDialog() {
        if PurchaseService.getPurchaseStatus() == PurchaseStatus.Purchased {
            self.showMessageDialog(NSLocalizedString("msg_already_purchase", comment: ""), didOk: nil)
            return
        }
        
        self.purchaseConfirmViewController.show(self,
            actionPurchase: { () -> Void in
                self.startLoadingPurchase()
                // 購入処理
                self.purchaseService.startPurchase({ () -> Void in
                    // 購入完了
                    self.showMessageDialog(NSLocalizedString("msg_complete_purchase", comment: ""), didOk: nil)
                    self.stopLoading()
                    }, didFailure: { (errorCode) -> Void in
                        // 購入に失敗またはキャンセル
                        self.showMessageDialog(TTError.getErrorMessage(errorCode), didOk: nil)
                        self.stopLoading()
                })
            }, actionRestore: { () -> Void in
                self.startLoadingPurchase()
                // 復元処理
                self.purchaseService.startRestore({ () -> Void in
                    // リストア完了
                    self.showMessageDialog(NSLocalizedString("msg_complete_restore", comment: ""), didOk: nil)
                    self.stopLoading()
                    }, didFailure: { (errorCode) -> Void in
                        // リストアに失敗またはキャンセル
                        self.showMessageDialog(TTError.getErrorMessage(errorCode), didOk: nil)
                        self.stopLoading()
                })
            }, actionCancel: nil)
    }
    
    // 再読み込み
    private func reload()->Void {
        self.shelfObjectList = self.bookService.getRootShelfObjects()
        self.ShelfObjectListTableView.reloadData()
        self.enablePasteButton()
    }
    
    // MARK: Data Operation
    
    // フォルダ作成
    private func createFolder(newFolderName: String?) {
        let ret = self.bookService.createFolder(newFolderName)
        if ret == TTErrorCode.Normal {
            // ToDo: ダイアログいるか確認
            self.showMessageDialog(NSLocalizedString("dialog_msg_folder_created", comment: ""), didOk: {() -> Void in
                self.reload()
            })
            
        } else {
            self.showErrorDialog(ret, didOk: nil)
        }
    }
    
    // フォルダ更新
    private func updateFolder(folderId: String, newFolderName: String?) {
        let ret = self.bookService.updateFolder(folderId, folderName: newFolderName)
        if ret == TTErrorCode.Normal {
            // ToDo: ダイアログいるか確認
            self.showMessageDialog(NSLocalizedString("dialog_msg_folder_edited", comment: ""), didOk: {() -> Void in
                self.reload()
            })
            
        } else {
            self.showErrorDialog(ret, didOk: nil)
        }
    }
    
    // オブジェクト削除
    private func deleteObject(shelfObject: ShelfObjectEntity)->TTErrorCode {
        return self.bookService.deleteShelfObject(shelfObject)
    }
    
    
    //
    // MARK: IBAction
    //
    @IBAction func createNewFolderTapped(sender: AnyObject) {
        LogM("Create New Folder.")
        self.showCreateFolderDialog()
    }

    @IBAction func paseteBookTapped(sender: AnyObject) {
        LogM("Paste book.")
        let result = self.bookService.pasteBook(SystemFolderID.Root.rawValue)
        if result == TTErrorCode.Normal {
            self.bookService.clearClipboard()
            self.pasteButton.hidden = true
            
            self.reload()
        } else {
            self.showErrorDialog(result, didOk: nil)
        }
    }

    @IBAction func purchaseButtonTapped(sender: AnyObject) {
        LogM("Purchase Button.")
        self.showPurchaseDialog()
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
        Log(NSString(format: "rows[%d]", self.shelfObjectList.count))
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
            cell.detailTextLabel?.text = NSLocalizedString("label_folder", comment: "")
        }

        return cell
    }
    
    // セルが選択された
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let object: ShelfObjectEntity = self.shelfObjectList[indexPath.row]
        Log(NSString(format: "--- selected shelf object. title:%@ type:%@ object_id:%@", object.name, object.type, object.object_id))
        
        // フォルダ選択(フォルダ内図書一覧へ)
        if object.type == ShelfObjectTypes.Folder.rawValue {
            object.trace()
            self.performSegueWithIdentifier("bookListView", sender: object.object_id)
        }
        // 図書を選択(朗読画面へ)
        if object.type == ShelfObjectTypes.Book.rawValue {
            let book: BookEntity = self.bookService.getBookById(object.object_id)!
            book.trace()
        }
    }
    
    // 編集可否の設定
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        Log(NSString(format: "section:%d row:%d", indexPath.section, indexPath.row))
        return true
    }
    
    // 編集時のスタイル(このメソッドを定義するとスワイプで編集メニューが無効になる)
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
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
            
            let actionOk: (() -> Void) = {
                let result: TTErrorCode = self.deleteObject(shelfObject)
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
            
            #if false
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
            
            #endif
            
            tableView.setEditing(false, animated: true)
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
//                let folder: FolderEntity = self.bookService.getFolderById(shelfObject.target_id)!
//                self.showEditFolderDialog(folder.folder_id, name: folder.name)
                self.showEditFolderDialog(shelfObject.object_id, name: shelfObject.name)

                tableView.setEditing(false, animated: true)
            }
            changeTitleAction.backgroundColor = UIColor.greenColor()
            actions.append(changeTitleAction)
            break
        case ShelfObjectTypes.Book.rawValue:
            // コピー
            let copyAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_copy", comment: "")) { (action, indexPath) -> Void in
                LogM("copy book.")
                // コピーする
                self.bookService.copyObject(shelfObject)
                self.enablePasteButton()
                
                tableView.setEditing(false, animated: true)
            }
            copyAction.backgroundColor = UIColor.greenColor()
            actions.append(copyAction)
            
            // 切り取り
            let cutAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_cut", comment: "")) { (action, indexPath) -> Void in
                LogM("cut book.")
                // カットする
                self.bookService.cutObject(shelfObject)
                self.enablePasteButton()
                
                tableView.setEditing(false, animated: true)
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
        
        self.startLoadingImport()
    }
    
    func importCompleted() {
        LogM("import completed.")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.stopLoading()
            self.view.backgroundColor = UIColor.whiteColor()
            self.reload()
        })
    }
    
    func importFailed() {
        LogM("import failed.")
        self.stopLoading()
    }
    
    //
    // MARK: LoadingViewDelegate
    //
    func cancelLoad() {
        let bookService: BookService = BookService.sharedInstance
        bookService.cancelImport()
    }
    
    //
    // MARK: KVO
    //
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        Log(NSString(format: "keyPath:%@", (keyPath != nil) ? keyPath! : "None"))
//        if keyPath != nil && keyPath == Const.kKeyValueObserverPath {
//            self.reload()
//        }
//    }
}