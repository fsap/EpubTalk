//
//  Util.swift
//  TdTalk2Dev
//
//  Created by Fujiwara on 2015/08/05.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

/*
    ログ
*/
// デバッグログ出力(DEBUGビルド時のみ)
// formatして出力したい時
func Log(message: NSString,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
#if DEBUG
    NSLog("DEBUG:%@(%d) %@", function, line, message)
#endif
}

// メッセージのみ
func LogM(message: String,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
#if DEBUG
    NSLog("DEBUG:%@(%d) %@", function, line, message)
#endif
}

// エラーログ出力
func LogE(message: NSString,
    function: String = __FUNCTION__,
    line: Int = __LINE__)
{
    NSLog("ERR:%@(%d) %@", function, line, message)
}

/*
    システム系
*/
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
