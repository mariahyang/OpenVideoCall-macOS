//
//  VideoViewLayout.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 3/24/16.
//  Copyright © 2016 Agora. All rights reserved.
//


import Cocoa
import WebKit

class VideoViewLayout {
    
    static let ViewEdgeInset: CGFloat = 1
    
    private var MaxPeerCount = 4
    private var layoutConstraints = [NSLayoutConstraint]()
    
    var selfView: VideoView?
    var selfSize: CGSize?
    var targetSize = CGSizeZero
    
    var videoViews = [VideoView]()
    var fullView: VideoView?
    var containerView: NSView?
    private var scrollView = NSScrollView()
    
    private let Multiplier: CGFloat = 0.99999
    private let ViewInset = VideoViewLayout.ViewEdgeInset
    
    private var allViews: [VideoView] {
        get {
            var allViews = [VideoView]()
            allViews.appendContentsOf(videoViews)
            if let selfView = selfView {
                allViews.append(selfView)
            }
            return allViews
        }
    }
    
    init() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    #if os(OSX)
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
    #endif
    }
    
    func layoutVideoViews() {
        guard let selfView = selfView, let containerView = containerView else {
            return
        }
        
        selfView.removeFromSuperview()
        for view in videoViews {
            view.removeFromSuperview()
        }
        scrollView.removeFromSuperview()
        
        NSLayoutConstraint.deactivateConstraints(layoutConstraints)
        layoutConstraints.removeAll()
        
        switch videoViews.count {
        case 0:
            //单人全屏
            let fullViewLayouts = layoutFullSessionView(selfView, inContainerView: containerView)
            layoutConstraints.appendContentsOf(fullViewLayouts)
            
        case 1:
            //双人对方全屏
            let peerView = videoViews.first!
            let fullViewLayouts = layoutFullSessionView(peerView, inContainerView: containerView)
            layoutConstraints.appendContentsOf(fullViewLayouts)
            
            //自己右上角
            let cornerViewLayouts = layoutCornerSessionView(selfView, inContainerView: containerView)
            layoutConstraints.appendContentsOf(cornerViewLayouts)
            
        default:
            if let fullView = fullView {
                //一拖三形式
                //全屏
                let fullViewLayouts = layoutFullSessionView(fullView, inContainerView: containerView)
                layoutConstraints.appendContentsOf(fullViewLayouts)
                
                //其他人左上角顺序排列，自己在最右
                var smallViews = [VideoView]()
                let smallCount = min(videoViews.count, MaxPeerCount)
                var index = 0
                repeat {
                    let view: VideoView
                    if index >= videoViews.count {
                        view = selfView
                    } else {
                        view = videoViews[index]
                    }
                    if view != fullView {
                        smallViews.append(view)
                    }
                    index += 1
                } while smallViews.count < smallCount
                
                let smallViewLayouts = layoutSmallSessionViews(smallViews, inContainerView: containerView)
                layoutConstraints.appendContentsOf(smallViewLayouts)
                
            } else {
                //等分屏，最多5*5
                let layouts = layoutEqualSessionViews(allViews, inContainerView: containerView)
                layoutConstraints.appendContentsOf(layouts)
            }
        }
        
        NSLayoutConstraint.activateConstraints(layoutConstraints)
    }
    
    func reponseViewIndexOfLocation(location: CGPoint) -> Int? {
        guard let selfView = selfView, let containerView = containerView where fullView == nil else {
            return nil
        }
        
        var allViews = [VideoView]()
        allViews.append(selfView)
        allViews.appendContentsOf(videoViews)
        
        for (index, view) in allViews.enumerate() {
            if let superview = view.superview where superview == containerView && view.frame.contains(location) {
                return index
            }
        }
        
        return nil
    }
}

//MARK: - layouts
private extension VideoViewLayout {
    //全屏布局
    func layoutFullSessionView(view: NSView, inContainerView containerView: NSView) -> [NSLayoutConstraint] {
        containerView.addSubview(view)
        var layouts = [NSLayoutConstraint]()
        
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(\(-ViewInset))-[view]-(\(-ViewInset))-|", options: [], metrics: nil, views: ["view": view])
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(-ViewInset))-[view]-(\(-ViewInset))-|", options: [], metrics: nil, views: ["view": view])
        layouts.appendContentsOf(constraintsH)
        layouts.appendContentsOf(constraintsV)
        
        return layouts
    }
    
    //右上角布局
    func layoutCornerSessionView(view: NSView, inContainerView containerView: NSView) -> [NSLayoutConstraint] {
        containerView.addSubview(view)
        var layouts = [NSLayoutConstraint]()
        
        containerView.addSubview(view)
        let right = NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: containerView, attribute: .Right, multiplier: Multiplier, constant: -5)
        let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: containerView, attribute: .Top, multiplier: Multiplier, constant: 64)
        let width = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: containerView, attribute: .Width, multiplier: 0.249999, constant: 0)
        
        let ratioValue: CGFloat
        if let selfSize = selfSize where selfSize.width > 0 && selfSize.height > 0 {
            ratioValue = selfSize.width / selfSize.height
        } else if targetSize.width > 0 && targetSize.height > 0 {
            ratioValue = targetSize.width / targetSize.height
        } else {
            ratioValue = CGRectGetWidth(containerView.bounds) / CGRectGetHeight(containerView.bounds)
        }
        let ratio = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: selfView, attribute: .Height, multiplier: ratioValue, constant: 0)
        layouts.appendContentsOf([right, top, width, ratio])
        
        return layouts
    }
    
    //小屏滚动布局: 竖屏从左上开始向右排，横屏从右上开始，向下排
    func layoutSmallSessionViews(smallViews: [NSView], inContainerView containerView: NSView) -> [NSLayoutConstraint] {
        let ratio: CGFloat
        if targetSize.width > 0 && targetSize.height > 0 {
            ratio = targetSize.width / targetSize.height
        } else {
            ratio = CGRectGetWidth(containerView.bounds) / CGRectGetHeight(containerView.bounds)
        }

        scrollView.verticalScrollElasticity = .None
        scrollView.verticalScrollElasticity = .Automatic
        
        var layouts = [NSLayoutConstraint]()
        var lastView: NSView?
        
        let scrollContainerView = NSView()
        scrollContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = scrollContainerView
        
        let scrollContainerH: [NSLayoutConstraint]
        let scrollContainerV: [NSLayoutConstraint]
        
        scrollContainerH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]", options: [], metrics: nil, views: ["view": scrollContainerView])
        scrollContainerV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: ["view": scrollContainerView])
        
        layouts.appendContentsOf(scrollContainerH)
        layouts.appendContentsOf(scrollContainerV)
        
        let itemSpace: CGFloat = 12
        
        for view in smallViews {
            if view == fullView {
                continue
            }
            
            scrollContainerView.addSubview(view)
            let viewWidth: NSLayoutConstraint
            
            viewWidth = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: containerView, attribute: .Width, multiplier: 0.249999, constant: 0)
            
            let viewRatio = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: ratio, constant: 0)
            let viewTop: NSLayoutConstraint
            let viewLeft: NSLayoutConstraint
            
            viewTop = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: scrollContainerView, attribute: .Top, multiplier: 1, constant: 0)
            if let lastView = lastView {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Right, multiplier: 1, constant: itemSpace)
            } else {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: scrollContainerView, attribute: .Left, multiplier: 1, constant: itemSpace)
            }
            
            layouts.appendContentsOf([viewWidth, viewRatio, viewLeft, viewTop])
            lastView = view
        }
        
        let lastViewRight = NSLayoutConstraint(item: lastView!, attribute: .Right, relatedBy: .Equal, toItem: scrollContainerView, attribute: .Right, multiplier: 1, constant: 0)
        let lastViewBottom = NSLayoutConstraint(item: lastView!, attribute: .Bottom, relatedBy: .Equal, toItem: scrollContainerView, attribute: .Bottom, multiplier: 1, constant: 0)
        layouts.appendContentsOf([lastViewRight, lastViewBottom])
        
        containerView.addSubview(scrollView)
        
        let scrollConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": scrollView])
        let scrollHeight = NSLayoutConstraint(item: scrollView, attribute: .Height, relatedBy: .Equal, toItem: lastView!, attribute: .Height, multiplier: 1, constant: 0)
        let scrollTop = NSLayoutConstraint(item: scrollView, attribute: .Top, relatedBy: .Equal, toItem: containerView, attribute: .Top, multiplier: 1, constant: 64)
        layouts.appendContentsOf(scrollConstraintsH)
        layouts.appendContentsOf([scrollHeight, scrollTop])
        
        return layouts
    }
    
    //等分屏布局
    func layoutEqualSessionViews(allViews: [NSView], inContainerView containerView: NSView) -> [NSLayoutConstraint] {
        
        var layouts = [NSLayoutConstraint]()
        let rowsPerScreen = CollectionIndexModel.rowsPerScreenWithTotalCount(allViews.count)
        
        for (index, view) in allViews.enumerate() {
            if index > MaxPeerCount {
                break
            }
            containerView.addSubview(view)
            
            let viewTop: NSLayoutConstraint
            if let topIndex = CollectionIndexModel.topIndexOfIndex(index, rowsPerScreen: rowsPerScreen) {
                viewTop = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: allViews[topIndex], attribute: .Bottom, multiplier: Multiplier, constant: 0)
            } else {
                viewTop = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: containerView, attribute: .Top, multiplier: Multiplier, constant: -ViewInset)
            }
            
            let viewLeft: NSLayoutConstraint
            if let leftIndex = CollectionIndexModel.leftIndexOfIndex(index, rowsPerScreen: rowsPerScreen) {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: allViews[leftIndex], attribute: .Right, multiplier: Multiplier, constant: 0)
            } else {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: containerView, attribute: .Left, multiplier: Multiplier, constant: -ViewInset)
            }
            
            layouts.appendContentsOf([viewLeft, viewTop])
            
            if index > 0 {
                let viewWidth = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: allViews[0], attribute: .Width, multiplier: Multiplier, constant: 0)
                let viewHeight = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: allViews[0], attribute: .Height, multiplier: Multiplier, constant: 0)
                layouts.appendContentsOf([viewWidth, viewHeight])
            }
        }
        
        let multiplier = 1 / CGFloat(rowsPerScreen)
        let rightViewIndex = rowsPerScreen - 1
        if allViews.count > rightViewIndex {
            let viewRight = NSLayoutConstraint(item: allViews[rightViewIndex], attribute: .Right, relatedBy: .Equal, toItem: containerView, attribute: .Right, multiplier: Multiplier, constant: ViewInset)
            layouts.append(viewRight)
        } else {
            let viewWidth = NSLayoutConstraint(item: allViews[0], attribute: .Width, relatedBy: .Equal, toItem: containerView, attribute: .Width, multiplier: multiplier, constant: 0)
            layouts.append(viewWidth)
        }
        
        let bottomViewIndex = rowsPerScreen * (rowsPerScreen - 1)
        if allViews.count > bottomViewIndex {
            let viewBottom = NSLayoutConstraint(item: allViews[bottomViewIndex], attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: Multiplier, constant: ViewInset)
            layouts.append(viewBottom)
        } else {
            let viewHeight = NSLayoutConstraint(item: allViews[0], attribute: .Height, relatedBy: .Equal, toItem: containerView, attribute: .Height, multiplier: multiplier, constant: 0)
            layouts.append(viewHeight)
        }
        
        return layouts
    }
}
