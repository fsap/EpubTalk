//
//  Util.swift
//  TdTalk2Dev
//
//  Created by Fujiwara on 2015/08/05.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

//
// MARK: ログ
//
// デバッグログ出力(DEBUGビルド時のみ)
// formatして出力したい時
func Log(message: NSString,
    file: String = __FILE__,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
#if DEBUG
    let file: NSURL = NSURL(fileURLWithPath: file)
    NSLog("DEBUG:%@:%@(%d) %@", file.lastPathComponent!, function, line, message)
#endif
}

// メッセージのみ
func LogM(message: String,
    file: String = __FILE__,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
#if DEBUG
    let file: NSURL = NSURL(fileURLWithPath: file)
    NSLog("DEBUG:%@:%@(%d) %@", file.lastPathComponent!, function, line, message)
#endif
}

// エラーログ出力
func LogE(message: NSString,
    file: String = __FILE__,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
    let file: NSURL = NSURL(fileURLWithPath: file)
    NSLog("ERR:%@:%@(%d) %@", file.lastPathComponent!, function, line, message)
}

//
// MARK: システム系
//
// iOS8判定
func isOS8()->Bool {
    switch UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch) {
    case .OrderedSame, .OrderedDescending:
        return true;
    case .OrderedAscending:
        return false;
    }
}

// Voice Overが有効か
func isVoiceOverEnabled()->Bool {
    return UIAccessibilityIsVoiceOverRunning()
}
