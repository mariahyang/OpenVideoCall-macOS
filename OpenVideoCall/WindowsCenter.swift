//
//  WindowsCenter.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 6/14/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa
import CoreGraphics

class Window {
    private(set) var id: CGWindowID = 0
    private(set) var name: String!
    private(set) var image: NSImage!
    
    init?(windowDic: NSDictionary) {
        var bounds = CGRect()
        let windowBounds = windowDic[Window.convertCFString(kCGWindowBounds)] as! CFDictionary
        CGRectMakeWithDictionaryRepresentation(windowBounds, &bounds)
        if CGRectGetWidth(bounds) < 100 || CGRectGetHeight(bounds) < 100 {
            return nil
        }
        
        let idNumber = windowDic[Window.convertCFString(kCGWindowNumber)] as! CFNumber
        let id = Window.convertCFNumber(idNumber)
        var name: String?
        if let ownerName = windowDic[Window.convertCFString(kCGWindowOwnerName)] {
            let cfName = ownerName as! CFString
            name = Window.convertCFString(cfName)
        }
        if let name = name where name == "Dock" {
            return nil
        }
        
        let image = Window.imageOfWindow(id)
        
        self.id = id
        self.name = name ?? "Unknown"
        self.image = image
    }
    
    private init() {}
    
    static func fullScreenWindow() -> Window {
        let window = Window()
        window.name = "Full Screen"
        window.image = imageOfFullScreen()
        return window
    }
    
    private static func imageOfWindow(windowId: CGWindowID) -> NSImage {
        if let screenShot = CGWindowListCreateImage(CGRectNull, .OptionIncludingWindow, CGWindowID(windowId), .Default) {
            let bitmapRep = NSBitmapImageRep(CGImage: screenShot)
            let image = NSImage()
            image.addRepresentation(bitmapRep)
            return image
        } else {
            return NSImage()
        }
    }
    
    private static func imageOfFullScreen() -> NSImage {
        if let screenShot = CGWindowListCreateImage(CGRectInfinite, .OptionOnScreenOnly, CGWindowID(0), .Default) {
            let bitmapRep = NSBitmapImageRep(CGImage: screenShot)
            let image = NSImage()
            image.addRepresentation(bitmapRep)
            return image
        } else {
            return NSImage()
        }
    }
}

class WindowList {
    var items = [ImageBrowserItem]()
    private var list = [Window]() {
        didSet {
            var items = [ImageBrowserItem]()
            for window in list {
                items.append(ImageBrowserItem(window: window))
            }
            self.items = items
        }
    }
    
    func getList() {
        var list = [Window]()
        list.append(Window.fullScreenWindow())
        
        if let windowDicCFArray = CGWindowListCopyWindowInfo([.OptionOnScreenOnly, .ExcludeDesktopElements], 0) {
            let windowDicList = windowDicCFArray as NSArray
            
            for windowElement in windowDicList {
                let windowDic = windowElement
                if let windowDic = windowDic as? NSDictionary {
                    if let window = Window(windowDic: windowDic) {
                        list.append(window)
                    }
                }
                
            }
        }
        
        self.list = list
    }
}

private extension Window {
    class func convertCFString(cfString: CFString) -> String {
        let string = cfString as NSString
        return string as String
        
    }
    
    class func convertCFNumber(cfNumber: CFNumber) -> CGWindowID {
        let number = cfNumber as NSNumber
        return number.unsignedIntValue
    }
}
