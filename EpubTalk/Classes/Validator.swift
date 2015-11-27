//
//  Validator.swift
//  TdTalk2Dev
//
//  Created by Fujiwara on 2015/08/05.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit


class Validator {
    
    struct Const {
        static let kSystemIdMaxLength: Int = 128
        static let kSystemNameMaxLength: Int = 256
    }
    
    
    static func validateId(idString: String?)->TTErrorCode {
        if idString == nil {
            return .InvalidId
        }
        
        if idString!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            return .InvalidId
        }
        
        if idString!.characters.count > Const.kSystemIdMaxLength {
            return .InvalidId
        }
        
        return .Normal
    }
    
    static func validateName(nameString: String?)->TTErrorCode {
        if nameString == nil {
            return .BlankString
        }
        
        if nameString!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            return .BlankString
        }
        
        if nameString!.characters.count > Const.kSystemNameMaxLength {
            return .StringTooLong
        }
        
        return .Normal
    }
}
