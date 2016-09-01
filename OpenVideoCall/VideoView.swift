//
//  VideoView.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 2/14/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

class VideoView: NSView {
    
    private(set) var videoView: NSView!
    private var screenShareImageView: NSView?
    
    private var infoView: NSView!
    private var infoLabel: NSTextField!
    
    var isVideoMuted = false {
        didSet {
            videoView?.hidden = isVideoMuted || isScreenSharing
        }
    }
    private var isScreenSharing = false {
        didSet {
            removeScreenShareImageView()
            
            if isScreenSharing {
                addScreenShareImageView()
            }
            
            videoView.hidden = isVideoMuted || isScreenSharing
        }
    }
    var shouldShowInfos = false {
        didSet {
            infoView.hidden = !shouldShowInfos
        }
    }
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        addVideoView()
        addInfoView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VideoView {
    func switchToScreenShare(isScreenShare: Bool) {
        isScreenSharing = isScreenShare
    }
}

extension VideoView {
    func updateInfo(info: MediaInfo) {
        infoLabel?.stringValue = info.description()
    }
}

private extension VideoView {
    func addVideoView() {
        videoView = NSView()
        videoView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(videoView)
        
        let inset = VideoViewLayout.ViewEdgeInset
        let videoViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(\(inset))-[video]-(\(inset))-|", options: [], metrics: nil, views: ["video": videoView])
        let videoViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(inset))-[video]-(\(inset))-|", options: [], metrics: nil, views: ["video": videoView])
        NSLayoutConstraint.activateConstraints(videoViewH + videoViewV)
    }
    
    func addInfoView() {
        infoView = NSView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.hidden = true
        
        addSubview(infoView)
        let infoViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[info]|", options: [], metrics: nil, views: ["info": infoView])
        let infoViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[info(==135)]", options: [], metrics: nil, views: ["info": infoView])
        infoView.lowerContentCompressionResistancePriority()
        NSLayoutConstraint.activateConstraints(infoViewH + infoViewV)
        
        func createInfoLabel() -> NSTextField {
            let label = NSTextField()
            label.translatesAutoresizingMaskIntoConstraints = false
            
            label.stringValue = " "
            let shadow = NSShadow()
            shadow.shadowOffset = NSSize(width: 0, height: 1)
            shadow.shadowColor = NSColor.blackColor()
            label.shadow = shadow
            label.maximumNumberOfLines = 0
            
            label.editable = false
            label.bezeled = false
            label.drawsBackground = false
            
            label.font = NSFont.systemFontOfSize(12)
            label.textColor = NSColor.whiteColor()
            
            return label
        }
        
        infoLabel = createInfoLabel()
        infoView.addSubview(infoLabel)
        
        let top: CGFloat = 16
        let left: CGFloat = 8
        
        let labelV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(top))-[info]", options: [], metrics: nil, views: ["info": infoLabel])
        let labelH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(\(left))-[info]", options: [], metrics: nil, views: ["info": infoLabel])
        infoLabel.lowerContentCompressionResistancePriority()
        NSLayoutConstraint.activateConstraints(labelV)
        NSLayoutConstraint.activateConstraints(labelH)
    }
    
    //MARK: - screen share
    private func addScreenShareImageView() {
        let imageView = NSImageView(frame: CGRectMake(0, 0, 144, 144))
        imageView.image = NSImage(named: "icon_sharing_desktop")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        let avatarH = NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let avatarV = NSLayoutConstraint(item: imageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        let avatarRatio = NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: imageView, attribute: .Height, multiplier: 1, constant: 0)
        let avatarLeft = NSLayoutConstraint(item: imageView, attribute: .Left, relatedBy: .GreaterThanOrEqual, toItem: self, attribute: .Left, multiplier: 1, constant: 10)
        let avatarTop = NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: self, attribute: .Top, multiplier: 1, constant: 10)
        imageView.lowerContentCompressionResistancePriority()
        NSLayoutConstraint.activateConstraints([avatarH, avatarV, avatarRatio, avatarLeft, avatarTop])
        
        screenShareImageView = imageView
    }
    
    private func removeScreenShareImageView() {
        if let imageView = screenShareImageView {
            imageView.removeFromSuperview()
            self.screenShareImageView = nil
        }
    }
}

private extension NSView {
    func lowerContentCompressionResistancePriority() {
        setContentCompressionResistancePriority(200, forOrientation: .Horizontal)
        setContentCompressionResistancePriority(200, forOrientation: .Vertical)
    }
}
