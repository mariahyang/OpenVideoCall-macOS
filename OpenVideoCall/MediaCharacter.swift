//
//  MediaCharacter.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 16/8/1.
//  Copyright © 2016年 Agora. All rights reserved.
//

import Foundation

struct MediaCharacter {
    
    private static let legalMediaCharacterSet: NSCharacterSet = {
        return NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()+,-:;<=.>?@[]^_`{|}~")
    }()
    
    static func updateToLegalMediaString(string: String) -> String {
        let legalSet = MediaCharacter.legalMediaCharacterSet
        let separatedArray = string.componentsSeparatedByCharactersInSet(legalSet.invertedSet)
        let legalString = separatedArray.joinWithSeparator("")
        return legalString
    }
}
