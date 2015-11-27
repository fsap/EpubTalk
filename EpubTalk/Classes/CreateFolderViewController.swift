//
//  CreateFolderViewController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

class CreateFolderViewController : UIViewController, UIAlertViewDelegate {

    var actionOkBlock: ((inputText: String?)->Void)
    var actionCancelBlock: (()->Void)
    var alertView: UIAlertView
    
    required init?(coder aDecoder: NSCoder) {
        self.actionOkBlock = {_ in (inputText: "")}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.actionOkBlock = {_ in (inputText: "")}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // フォルダ作成ダイアログ(OK, Cancelボタン)
    func showCreate(parentViewController: UIViewController?, actionOk: ((inputText: String?)->Void), actionCancel: (()->Void)?) {

        // Fallback on earlier versions
        self.alertView = UIAlertView(
            title: NSLocalizedString("dialog_title_create_folder", comment: ""),
            message: NSLocalizedString("dialog_msg_create_new_folder", comment: ""),
            delegate: self,
            cancelButtonTitle: NSLocalizedString("dialog_cancel", comment: ""),
            otherButtonTitles: NSLocalizedString("dialog_create", comment: "")
        )
        self.alertView.alertViewStyle = .PlainTextInput
        self.alertView.show()
        self.actionOkBlock = actionOk
        if actionCancel != nil {
            self.actionCancelBlock = actionCancel!
        }
    }

    // フォルダ編集ダイアログ(OK, Cancelボタン)
    func showEdit(parentViewController: UIViewController?, name: String, actionOk: ((inputText: String?)->Void), actionCancel: (()->Void)?) {
        
        // Fallback on earlier versions
        self.alertView = UIAlertView(
            title: NSLocalizedString("dialog_title_edit_folder", comment: ""),
            message: NSLocalizedString("dialog_msg_edit_folder", comment: ""),
            delegate: self,
            cancelButtonTitle: NSLocalizedString("dialog_cancel", comment: ""),
            otherButtonTitles: NSLocalizedString("dialog_edit", comment: "")
        )
        self.alertView.alertViewStyle = .PlainTextInput
        self.alertView.textFieldAtIndex(0)!.text = name
        self.alertView.show()
        self.actionOkBlock = actionOk
        if actionCancel != nil {
            self.actionCancelBlock = actionCancel!
        }
    }

    
    //
    // MARK: UIAlertViewDelegate
    //
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        Log(NSString(format: "click button action.[%d]", buttonIndex))
        if buttonIndex == alertView.cancelButtonIndex {
            // Canceled
            self.actionCancelBlock()
        } else {
            // OK
            let inputText: String? = alertView.textFieldAtIndex(0)?.text
            self.actionOkBlock(inputText: inputText)
        }
    }
}
