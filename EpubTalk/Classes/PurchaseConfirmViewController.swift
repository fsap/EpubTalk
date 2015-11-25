//
//  PurchaseConfirmViewController.swift
//  EpubTalk
//
//  Created by Fujiwara on 2015/07/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

enum PurchaseButtonIndex: Int {
    case Purchase = 1,
    Restore
}

class PurchaseConfirmViewController : UIViewController, UIAlertViewDelegate {

    var actionPurchaseBlock: (()->Void)
    var actionRestoreBlock: (()->Void)
    var actionCancelBlock: (()->Void)
    var alertView: UIAlertView
    
    required init?(coder aDecoder: NSCoder) {
        self.actionPurchaseBlock = {}
        self.actionRestoreBlock = {}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.actionPurchaseBlock = {}
        self.actionRestoreBlock = {}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // メッセージダイアログ
    func show(parentViewController: UIViewController?, actionPurchase: (()->Void), actionRestore: (()->Void), actionCancel: (()->Void)?) {

        self.alertView = UIAlertView(
            title: "",
            message: NSLocalizedString("dialog_msg_confirm_purchase", comment: ""),
            delegate: self,
            cancelButtonTitle: NSLocalizedString("dialog_cancel", comment: ""),
            otherButtonTitles: NSLocalizedString("dialog_purchase", comment: ""), NSLocalizedString("dialog_restore", comment: "")
        )
        self.alertView.alertViewStyle = .Default
        self.alertView.show()
        self.actionPurchaseBlock = actionPurchase
        self.actionRestoreBlock = actionRestore
        if actionCancel != nil {
            self.actionCancelBlock = actionCancel!
        }
    }

    
    //
    // MARK: UIAlertViewDelegate
    //
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        Log(NSString(format: "click button action.[%d]", buttonIndex))
        switch buttonIndex {
        case PurchaseButtonIndex.Purchase.rawValue:
            // Purchase
            self.actionPurchaseBlock()
            return
            
        case PurchaseButtonIndex.Restore.rawValue:
            // Restore
            self.actionRestoreBlock()
            return
            
        default:
            // Canceled
            self.actionCancelBlock()
        }
    }
}
