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

class BookListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Const {
        static let kBookListViewLineHeight :CGFloat = 64.0
    }

    @IBOutlet weak var bookListTableView: UITableView!
    @IBOutlet weak var pasteButton: UIButton!
    
    let bookService: TTBookService = TTBookService.sharedInstance
    var bookList :[BookEntity] = []
    var alertController: TTAlertController = TTAlertController(nibName: nil, bundle: nil)
    var loadingView: LoadingView?
    var delegate: BookListViewDelegate?
    
    var folder: FolderEntity?
    
    
    required init?(coder aDecoder: NSCoder) {
        folder = nil
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LogM("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
        // title
        self.navigationItem.title = folder!.name
        self.navigationItem.accessibilityLabel = folder!.name
        // edit
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.bookListTableView.delegate = self
        // paste
        self.pasteButton.setTitle(NSLocalizedString("paste_button", comment: ""), forState: .Normal)
        self.pasteButton.accessibilityLabel = NSLocalizedString("paste_button", comment: "")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.bookService.clipboard != nil {
            Log(NSString(format: "copied book:%@", self.bookService.clipboard!))
            self.pasteButton.hidden = false
        }
        self.reload()
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
    
    // 再読み込み
    private func reload()->Void {
        self.bookList = bookService.getBooksInFolder(folder!.folder_id)!
        self.bookListTableView.reloadData()
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
    
    
    //
    // MARK: IBAction
    //
    // ペースト
    @IBAction func pasteBookTapped(sender: AnyObject) {
        LogM("Paste book.")
        let result = self.bookService.pasteBook(self.folder!)
        if result == TTErrorCode.Normal {
            self.bookService.clearClipboard()
            self.pasteButton.hidden = true
            
            self.reload()
        } else {
            self.showErrorDialog(result, didOk: nil)
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
        return self.bookList.count
    }
    
    // 行の高さ
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Const.kBookListViewLineHeight
    }
    
    // セルの設定
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        let book = self.bookList[indexPath.row]
        cell.textLabel?.text = book.title

        return cell
    }
    
    // セルが選択された
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let book: BookEntity = self.bookList[indexPath.row]
        Log(NSString(format: "--- selected book. title:%@ file:%@", book.title, book.filename))
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
        let book: BookEntity = self.bookList[indexPath.row]
        var actions: [UITableViewRowAction] = []
        
        // 共通
        let deleteAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_delete", comment: "")) { (action, indexPath) -> Void in
            LogM("delete.")
            let actionOk: (() -> Void) = {
                let result: TTErrorCode = self.bookService.deleteBook(book)
                if result == TTErrorCode.Normal {
                    self.bookList.removeAtIndex(indexPath.row)
                    self.bookListTableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                    self.bookService.refreshSort(self.bookList)
                    self.reload()
                } else {
                    self.alertController.show(self,
                        title: NSLocalizedString("dialog_title_error", comment: ""),
                        message: TTError.getErrorMessage(result), actionOk: { () -> Void in})
                }
            }
            
            self.alertController.show(self,
                title: NSLocalizedString("dialog_title_notice", comment: ""),
                message: NSLocalizedString("dialog_msg_delete", comment: ""),
                actionOk: actionOk, actionCancel:nil)
        }
        deleteAction.backgroundColor = UIColor.redColor()
        actions.append(deleteAction)
        
        // コピー
        let copyAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_copy", comment: "")) { (action, indexPath) -> Void in
            LogM("copy book.")
            // コピーする
            self.bookService.copyBook(book)
            
            tableView.setEditing(false, animated: true)
        }
        copyAction.backgroundColor = UIColor.greenColor()
        actions.append(copyAction)
        
        // 切り取り
        let cutAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("cell_action_titile_cut", comment: "")) { (action, indexPath) -> Void in
            LogM("cut book.")
            // カットする
            self.bookService.cutBook(book)
            
            tableView.setEditing(false, animated: true)
        }
        cutAction.backgroundColor = UIColor.greenColor()
        actions.append(cutAction)
        
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

        let sourceBook: BookEntity = self.bookList[sourceIndexPath.row]
        self.bookList.removeAtIndex(sourceIndexPath.row)
        self.bookList.insert(sourceBook, atIndex: destinationIndexPath.row)
        bookService.refreshSort(self.bookList)
    }
    
}