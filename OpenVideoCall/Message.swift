//
//  Message.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 16/8/19.
//  Copyright © 2016年 Agora. All rights reserved.
//

import Foundation

enum MessageType {
    case Chat, Alert
    
    func color() -> NSColor {
        switch self {
        case .Chat: return NSColor(hex: 0x444444, alpha: 0.6)
        case .Alert: return NSColor(hex: 0xff3c32, alpha: 0.6)
        }
    }
}

struct Message {
    var text: String!
    var type: MessageType = .Chat
    
    init(text: String, type: MessageType) {
        self.text = text
        self.type = type
    }
}
    