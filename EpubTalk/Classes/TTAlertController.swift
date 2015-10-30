//
//  TTAlertController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

class TTAlertController : UIViewController, UIAlertViewDelegate {

    var actionOkBlock: (()->Void)
    var actionCancelBlock: (()->Void)
    var alertView: UIAlertView
    
    required init?(coder aDecoder: NSCoder) {
        self.actionOkBlock = {}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.actionOkBlock = {}
        self.actionCancelBlock = {}
        self.alertView = UIAlertView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // メッセージダイアログ(OKボタンのみ)
    func show(parentViewController: UIViewController?, title: String, message: String, actionOk: (()->Void))->Void {
        if #available(iOS 8.0, *) {
            if objc_getClass("UIAlertController") != nil {
                let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                if parentViewController != nil {
                    let alertAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                        actionOk()
                    })
                    alertController.addAction(alertAction)
                    let viewController = parentViewController!
                    viewController.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        } else {
            // Fallback on earlier versions
            self.alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "OK")
            self.alertView.show()
            self.actionOkBlock = actionOk
        }
    }

    // メッセージダイアログ(OK, Cancelボタン)
    func show(parentViewController: UIViewController?, title: String, message: String, actionOk: (()->Void), actionCancel: (()->Void)?) {
        if #available(iOS 8.0, *) {
            if objc_getClass("UIAlertController") != nil {
                let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                if parentViewController != nil {
                    let alertOkAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                        actionOk()
                    })
                    let alertCancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) -> Void in
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                        if actionCancel != nil {
                            actionCancel!()
                        }
                    })
                    alertController.addAction(alertOkAction)
                    alertController.addAction(alertCancelAction)
                    let viewController = parentViewController!
                    viewController.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        } else {
            // Fallback on earlier versions
            self.alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "OK")
            self.alertView.show()
            self.actionOkBlock = actionOk
        }
    }

    
    //
    // MARK: UIAlertViewDelegate
    //
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        Log(NSString(format: "click button action.[%d]", buttonIndex))
        if buttonIndex == alertView.cancelButtonIndex {
            // Canceled
            self.actionOkBlock()
        } else {
            // OK
            self.actionOkBlock()
        }
    }
}
