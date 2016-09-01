//
//  ChatMessageCellView.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 16/8/15.
//  Copyright © 2016年 Agora. All rights reserved.
//

import Cocoa

class ChatMessageCellView: NSTableCellView {
    @IBOutlet weak var colorView: NSView!
    @IBOutlet weak var messageLabel: NSTextField!
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        colorView?.layer?.cornerRadius = 2
        
        messageLabel?.usesSingleLineMode = false
        messageLabel?.cell?.wraps = true
        messageLabel?.cell?.scrollable = false
    }
    
    func setMessage(message: Message) {
        messageLabel.stringValue = message.text
        
        colorView?.wantsLayer = true
        colorView?.layer?.backgroundColor = message.type.color().CGColor
    }
}
