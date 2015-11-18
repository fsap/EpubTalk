//
//  LodingView.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

protocol LoadingViewDelegate {
    func cancelLoad()
}

class LoadingView: UIView, ShelfObjectListViewDelegate {
    
    var delegate: LoadingViewDelegate?
    
    private var activityIndicator: UIActivityIndicatorView
    private var sound_source: dispatch_source_t?

    
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView()
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(parentView: UIView, message:String) {
        self.init(frame: parentView.frame)
        
        createView(parentView, message: message)
    }
    
    private func createView(parentView: UIView, message: String) {
        
        //
        // ローディングViewの生成
        //
        self.frame = parentView.frame
        self.backgroundColor = UIColor.grayColor()
//        self.isAccessibilityElement = true
//        self.accessibilityLabel = NSLocalizedString("msg_loading", comment: "")
//        self.accessibilityFrame = self.frame
        
        // mask
        let maskView: UIView = UIView(frame: parentView.frame)
        maskView.backgroundColor = UIColor.grayColor()
        maskView.isAccessibilityElement = true
        maskView.accessibilityLabel = NSLocalizedString("msg_loading", comment: "")
        maskView.accessibilityFrame = self.frame
        
        // メッセージラベル
        let msgView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let msgLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        msgView.center = parentView.center
        msgView.backgroundColor = UIColor.clearColor()
        msgLabel.textColor = UIColor.whiteColor()
        msgLabel.textAlignment = .Center
        msgLabel.text = message
//        msgLabel.text = NSLocalizedString("msg_loading", comment: "")
        msgLabel.sizeToFit()
        msgLabel.center = CGPoint(x: msgView.frame.size.width / 2, y: msgView.frame.size.height / 2)
        
        // インジケーター
        activityIndicator.frame = CGRectMake(0, 0, 50, 50)
        activityIndicator.center = CGPoint(x: msgView.frame.size.width / 2, y: msgLabel.frame.origin.y + msgLabel.frame.size.height + 20)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        
        // 中止ボタン
        let cancelBtn: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        cancelBtn.backgroundColor = UIColor.whiteColor()
        cancelBtn.addTarget(self, action: "cancelBtnTapped", forControlEvents: UIControlEvents.TouchUpInside)
        cancelBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
        cancelBtn.setTitle(NSLocalizedString("button_title_cancel_loading", comment: ""), forState: .Normal)
        cancelBtn.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        cancelBtn.setTitle(NSLocalizedString("button_title_canceling", comment: ""), forState: .Highlighted)
        cancelBtn.layer.masksToBounds = true
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.center.x = parentView.center.x
        cancelBtn.frame.origin.y = (parentView.frame.size.height / 4) * 3
        cancelBtn.isAccessibilityElement = true
        cancelBtn.accessibilityLabel = cancelBtn.titleLabel?.text
        cancelBtn.accessibilityFrame = cancelBtn.frame
        
        msgView.addSubview(msgLabel)
        msgView.addSubview(activityIndicator)
        
        self.addSubview(maskView)
        self.addSubview(msgView)
        self.addSubview(cancelBtn)
        
        parentView.addSubview(self)
    }
    
    private func clearView() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }
    
    func cancelBtnTapped() {
        LogM("Cancel")
        for view in self.subviews {
            if view.isKindOfClass(UIButton) {
                (view as! UIButton).setTitle(NSLocalizedString("button_title_canceling", comment: ""), forState: .Normal)
                (view as! UIButton).enabled = false
            }
        }
        self.delegate?.cancelLoad()
    }
    
    func start() {
        if activityIndicator.isAnimating() {
            return
        }
            
        activityIndicator.startAnimating()
        
        /*
        サウンド再生
        */
        let queue = dispatch_queue_create("book_loading", nil)
        sound_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        // キャンセルハンドラ
        dispatch_source_set_cancel_handler(sound_source!, { () -> Void in
            if self.sound_source != nil {
                self.sound_source = nil;
            }
        })
        
        // タイマー
        dispatch_source_set_timer(
            sound_source!,
            dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)),
            2 * NSEC_PER_SEC,
            0)
        
        dispatch_source_set_event_handler(sound_source!, { () -> Void in
            // システムサウンドを鳴らす
            LogM("sound...")
            AudioServicesPlaySystemSound(1104)
        })
        
        dispatch_resume(sound_source!);
        
    }
    
    func stop() {
        activityIndicator.stopAnimating()
        
        if sound_source != nil {
            dispatch_source_cancel(sound_source!)
        }
        self.removeFromSuperview()
    }
    
    //
    // MARK: ShelfObjectListViewDelegate
    //
    func needRedraw(view: UIView, message: String) {
        Log(NSString(format: "view x:%f y:%f", view.frame.size.width, view.frame.size.height))
        // ローディング中の画面回転対応
        if activityIndicator.isAnimating() {
            self.clearView()
            createView(view, message: message)
        }
    }
    
    override func accessibilityActivate() -> Bool {
        return true
    }
    
}