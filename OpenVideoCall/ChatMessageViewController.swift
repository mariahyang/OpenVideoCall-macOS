//
//  ChatMessageViewController.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 16/8/15.
//  Copyright © 2016年 Agora. All rights reserved.
//

import Cocoa

class ChatMessageViewController: NSViewController {
    
    @IBOutlet weak var messageTableView: NSTableView!
    
    private var messageList = [Message]()
    
    func appendChat(text: String, fromUid uid: Int64) {
        let message = Message(text: text, type: .Chat)
        appendMessage(message)
    }
    
    func appendAlert(text: String) {
        let message = Message(text: text, type: .Alert)
        appendMessage(message)
    }
}

private extension ChatMessageViewController {
    func appendMessage(message: Message) {
        messageList.append(message)
        
        var deleted: Message?
        if messageList.count > 20 {
            deleted = messageList.removeFirst()
        }
        
        updateMessageTableWithDeletedMesage(deleted)
    }
    
    func updateMessageTableWithDeletedMesage(deleted: Message?) {
        guard let tableView = messageTableView else {
            return
        }
        
        if deleted != nil {
            tableView.removeRowsAtIndexes(NSIndexSet(index: 0), withAnimation: .EffectNone)
        }
        
        let lastRow = messageList.count - 1
        tableView.insertRowsAtIndexes(NSIndexSet(index: lastRow), withAnimation: .EffectNone)
        tableView.scrollRowToVisible(lastRow)
    }
}

extension ChatMessageViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return messageList.count
    }
}

extension ChatMessageViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("messageCell", owner: self) as! ChatMessageCellView
        let message = messageList[row]
        cell.setMessage(message)
        return cell
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let defaultHeight: CGFloat = 24
        let string: NSString = messageList[row].text
        
        let column = tableView.tableColumns.first!
        let width = column.width - 24
        let textRect = string.boundingRectWithSize(NSMakeSize(width, 0), options: [.UsesLineFragmentOrigin], attributes: [NSFontAttributeName: NSFont.systemFontOfSize(12)])
        
        var textHeight = CGRectGetHeight(textRect) + 6
        
        if textHeight < defaultHeight {
            textHeight = defaultHeight;
        }
        return textHeight;
    }
}
