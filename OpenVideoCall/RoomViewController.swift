//
//  RoomViewController.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 2/20/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa
import Quartz.ImageKit

protocol RoomVCDelegate: class {
    func roomVCNeedClose(roomVC: RoomViewController)
}

class RoomViewController: NSViewController {
    
    //MARK: IBOutlet
    @IBOutlet weak var roomNameLabel: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var buttonContainerView: NSView!
    @IBOutlet weak var messageTableContainerView: NSView!
    
    @IBOutlet weak var muteVideoButton: NSButton!
    @IBOutlet weak var muteAudioButton: NSButton!
    
    @IBOutlet weak var screenSharingButton: NSButton!
    @IBOutlet weak var windowListView: IKImageBrowserView!
    
    @IBOutlet weak var filterButton: NSButton!
    
    @IBOutlet weak var messageButton: NSButton!
    @IBOutlet weak var messageInputerView: NSView!
    @IBOutlet weak var messageTextField: NSTextField!
    
    //MARK: public var
    var roomName: String!
    var encryptionSecret: String?
    var encryptionType: EncryptionType!
    var videoProfile: AgoraRtcVideoProfile!
    var delegate: RoomVCDelegate?
    
    //MARK: hide & show
    private var shouldHideFlowViews = false {
        didSet {
            buttonContainerView?.hidden = shouldHideFlowViews
            messageTableContainerView?.hidden = shouldHideFlowViews
            roomNameLabel?.hidden = shouldHideFlowViews
            
            if screenSharingStatus == .list {
                screenSharingStatus = .none
            }
            
            if shouldHideFlowViews {
                messageTextField?.resignFirstResponder()
                messageInputerView?.hidden = true
            } else {
                buttonContainerView?.hidden = false
                if isInputing {
                    messageTextField?.becomeFirstResponder()
                    messageInputerView?.hidden = false
                }
            }
        }
    }
    private var shouldCompressSelfView = false {
        didSet {
            updateSelfViewVisiable()
        }
    }
    
    //MARK: engine & session
    var agoraKit: AgoraRtcEngineKit!
    private var videoSessions = [VideoSession]() {
        didSet {
            updateInterfaceWithSessions(videoSessions)
        }
    }
    private var doubleClickEnabled = false
    private var doubleClickFullSession: VideoSession? {
        didSet {
            if videoSessions.count >= 3 && doubleClickFullSession != oldValue {
                updateInterfaceWithSessions(videoSessions)
            }
        }
    }
    private let videoViewLayout = VideoViewLayout()
    private var dataChannelId: Int = -1
    
    //MARK: mute
    private var audioMuted = false {
        didSet {
            muteAudioButton?.image = NSImage(named: audioMuted ? "btn_mute_blue" : "btn_mute")
            agoraKit.muteLocalAudioStream(audioMuted)
        }
    }
    private var videoMuted = false {
        didSet {
            muteVideoButton?.image = NSImage(named: videoMuted ? "btn_video" : "btn_voice")
            
            agoraKit.muteLocalVideoStream(videoMuted)
            setVideoMuted(videoMuted, forUid: 0)
            
            updateSelfViewVisiable()
        }
    }
    
    //MARK: screen sharing
    enum ScreenSharingStatus {
        case none, list, sharing
        
        func nextStatus() -> ScreenSharingStatus {
            switch self {
            case .none: return .list
            case .list: return .none
            case .sharing: return .none
            }
        }
    }
    private var screenSharingStatus = ScreenSharingStatus.none {
        didSet {
            screenSharingButton?.image = NSImage(named: (screenSharingStatus == .sharing) ? "btn_screen_sharing_blue" : "btn_screen_sharing")
            
            if oldValue == .sharing {
                stopShareWindow()
            }
            
            showWindowList(screenSharingStatus == .list)
        }
    }
    private var windows = WindowList()
    
    //MARK: filter
    private var isFiltering = false {
        didSet {
            guard let agoraKit = agoraKit else {
                return
            }
            
            if isFiltering {
                AGVideoPreProcessing.registerVideoPreprocessing(agoraKit)
                filterButton?.image = NSImage(named: "btn_filter_blue")
            } else {
                AGVideoPreProcessing.deregisterVideoPreprocessing(agoraKit)
                filterButton?.image = NSImage(named: "btn_filter")
            }
        }
    }
    
    //MARK: text message
    private var chatMessageVC: ChatMessageViewController?
    private var isInputing = false {
        didSet {
            if isInputing {
                messageTextField?.becomeFirstResponder()
            } else {
                messageTextField?.resignFirstResponder()
            }
            messageInputerView?.hidden = !isInputing
            messageButton?.image = NSImage(named: isInputing ? "btn_message_blue" : "btn_message")
        }
    }
    
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        roomNameLabel.stringValue = roomName
        
        messageInputerView.wantsLayer = true
        messageInputerView.layer?.backgroundColor = NSColor(hex: 0x000000, alpha: 0.75).CGColor
        messageInputerView.layer?.cornerRadius = 2
        
        setupWindowListView()
        loadAgoraKit()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        configStyleOfWindow(view.window!)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let segueId = segue.identifier where !segueId.isEmpty else {
            return
        }
        
        switch segueId {
        case "videoVCToDevicesVC":
            let devicesVC = segue.destinationController as! DevicesViewController
            devicesVC.agoraKit = agoraKit
            devicesVC.couldTest = false
        case "VideoVCEmbedChatMessageVC":
            chatMessageVC = segue.destinationController as? ChatMessageViewController
        default:
            break
        }
    }
    
    //MARK: - user action
    @IBAction func doMessageClicked(sender: NSButton) {
        isInputing = !isInputing
    }
    
    @IBAction func doSettingsClicked(sender: NSButton) {
        performSegueWithIdentifier("videoVCToDevicesVC", sender: nil)
    }
    
    @IBAction func doMuteVideoClicked(sender: NSButton) {
        videoMuted = !videoMuted
    }
    
    @IBAction func doMuteAudioClicked(sender: NSButton) {
        audioMuted = !audioMuted
    }
    
    @IBAction func doShareScreenClicked(sender: NSButton) {
        screenSharingStatus = screenSharingStatus.nextStatus()
    }
    
    @IBAction func doFilterClicked(sender: NSButton) {
        isFiltering = !isFiltering
    }
    
    @IBAction func doMessageInput(sender: NSTextField) {
        let text = sender.stringValue
        if !text.isEmpty {
            sendText(text)
            sender.stringValue = ""
        }
    }
    
    @IBAction func doCloseClicked(sender: NSButton) {
        leaveChannel()
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if theEvent.clickCount == 1 {
            shouldHideFlowViews = !shouldHideFlowViews
        } else if theEvent.clickCount == 2 && doubleClickEnabled {
            if doubleClickFullSession == nil {
                //将双击到的session全屏
                if let clickedIndex = videoViewLayout.reponseViewIndexOfLocation(theEvent.locationInWindow) {
                    doubleClickFullSession = videoSessions[clickedIndex]
                }
            } else {
                doubleClickFullSession = nil
            }
        }
    }
}

//MARK: - private
private extension RoomViewController {
    func configStyleOfWindow(window: NSWindow) {
        window.styleMask |= NSFullSizeContentViewWindowMask | NSMiniaturizableWindowMask
        window.delegate = self
        window.collectionBehavior = [.FullScreenPrimary]
        
        window.minSize = CGSizeMake(960, 600)
        window.maxSize = CGSizeMake(CGFloat(FLT_MAX), CGFloat(FLT_MAX))
    }
    
    func updateInterfaceWithSessions(sessions: [VideoSession]) {
        guard !sessions.isEmpty else {
            return
        }
        
        let selfSession = sessions.first!
        videoViewLayout.selfView = selfSession.hostingView
        videoViewLayout.selfSize = selfSession.size
        var peerVideoViews = [VideoView]()
        for i in 1..<sessions.count {
            peerVideoViews.append(sessions[i].hostingView)
        }
        videoViewLayout.videoViews = peerVideoViews
        videoViewLayout.fullView = doubleClickFullSession?.hostingView
        videoViewLayout.containerView = containerView
        
        videoViewLayout.layoutVideoViews()
        
        updateSelfViewVisiable()
        
        //只有三人及以上时才能切换布局形式
        if sessions.count >= 3 {
            doubleClickEnabled = true
        } else {
            doubleClickEnabled = false
            doubleClickFullSession = nil
        }
        
        SessionMediaInfoCenter.updateInfoViewOfSessions(sessions, fullSession: doubleClickFullSession, isShowingWhiteboard: false)
    }
    
    func fetchSessionOfUid(uid: UInt) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSessionOfUid(uid: UInt) -> VideoSession {
        if let fetchedSession = fetchSessionOfUid(uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
    
    func setVideoMuted(muted: Bool, forUid uid: UInt) {
        fetchSessionOfUid(uid)?.isVideoMuted = muted
    }
    
    func updateSelfViewVisiable() {
        guard let selfView = videoSessions.first?.hostingView else {
            return
        }
        
        if videoSessions.count == 2 {
            selfView.hidden = (videoMuted || shouldCompressSelfView)
            
        } else {
            selfView.hidden = false
        }
    }
    
    func setupWindowListView() {
        windowListView.setContentResizingMask(Int(NSAutoresizingMaskOptions.ViewWidthSizable.rawValue))
        windowListView.setValue(NSColor(white: 0, alpha: 0.75), forKey:IKImageBrowserBackgroundColorKey)
        
        let oldAttributres = windowListView.valueForKey(IKImageBrowserCellsTitleAttributesKey) as! NSDictionary
        let attributres = oldAttributres.mutableCopy() as! NSMutableDictionary
        attributres.setObject(NSColor.whiteColor(), forKey: NSForegroundColorAttributeName)
        windowListView.setValue(attributres, forKey:IKImageBrowserCellsTitleAttributesKey)
    }
    
    func showWindowList(shouldShow: Bool) {
        if shouldShow {
            windows.getList()
            windowListView?.reloadData()
            windowListView?.hidden = false
        } else {
            windowListView?.hidden = true
        }
    }
    
    //MARK: - alert
    func alertEngineString(string: String) {
        alertString("Engine: \(string)")
    }
    
    func alertAppString(string: String) {
        alertString("App: \(string)")
    }
    
    func alertString(string: String) {
        guard !string.isEmpty else {
            return
        }
        chatMessageVC?.appendAlert(string)
    }
}

//MARK: - agora media kit
private extension RoomViewController {
    func loadAgoraKit() {
        agoraKit = AgoraRtcEngineKit.sharedEngineWithAppId(KeyCenter.AppId, delegate: self)
        
        agoraKit.enableVideo()
        agoraKit.setChannelProfile(.ChannelProfile_Free)
        agoraKit.setVideoProfile(videoProfile)
        
        addLocalSession()
        agoraKit.startPreview()
        
        if let encryptionType = encryptionType, let encryptionSecret = encryptionSecret where !encryptionSecret.isEmpty {
            agoraKit.setEncryptionMode(encryptionType.modeString())
            agoraKit.setEncryptionSecret(encryptionSecret)
        }
        let code = agoraKit.joinChannelByKey(nil, channelName: roomName, info: nil, uid: 0, joinSuccess: nil)
        if code != 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.alertEngineString("Join channel failed: \(code)")
            })
        }
        
        agoraKit.createDataStream(&dataChannelId, reliable: true, ordered: true)
    }
    
    private func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
        agoraKit.setupLocalVideo(localSession.canvas)
        if let mediaInfo = MediaInfo(videoProfile: videoProfile) {
            localSession.mediaInfo = mediaInfo
        }
    }
    
    func leaveChannel() {
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        isFiltering = false
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        
        delegate?.roomVCNeedClose(self)
    }
    
    //MARK: - screen sharing
    func startShareWindow(window: Window) {
        let windowId = window.id
        agoraKit?.startScreenCapture(UInt(windowId))
        videoSessions.first?.hostingView.switchToScreenShare(windowId == 0 || window.name == "Agora Video Call" || window.name == "Full Screen")
    }
    
    func stopShareWindow() {
        agoraKit?.stopScreenCapture()
        videoSessions.first?.hostingView.switchToScreenShare(false)
    }
    
    //MARK: - data channel
    func sendText(text: String) {
        if dataChannelId > 0, let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            agoraKit.sendStreamMessage(dataChannelId, data: data)
            chatMessageVC?.appendChat(text, fromUid: 0)
        }
    }
}

//MARK: - agora media kit delegate
extension RoomViewController: AgoraRtcEngineDelegate {
    func rtcEngineConnectionDidInterrupted(engine: AgoraRtcEngineKit!) {
        alertEngineString("Connection Interrupted")
    }
    
    func rtcEngineConnectionDidLost(engine: AgoraRtcEngineKit!) {
        alertEngineString("Connection Lost")
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, didOccurError errorCode: AgoraRtcErrorCode) {
        alertEngineString("errorCode \(errorCode.rawValue)")
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        let userSession = videoSessionOfUid(uid)
        let sie = size.fixedSize()
        userSession.size = sie
        userSession.updateMediaInfo(resolution: size)
        agoraKit.setupRemoteVideo(userSession.canvas)
    }
    
    // first local video frame
    func rtcEngine(engine: AgoraRtcEngineKit!, firstLocalVideoFrameWithSize size: CGSize, elapsed: Int) {
        if let selfSession = videoSessions.first {
            let fixedSize = size.fixedSize()
            selfSession.size = fixedSize
            updateInterfaceWithSessions(videoSessions)
        }
    }
    
    // user offline
    func rtcEngine(engine: AgoraRtcEngineKit!, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerate() {
            if session.uid == uid {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.removeAtIndex(indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            if let doubleClickFullSession = doubleClickFullSession where doubleClickFullSession == deletedSession {
                self.doubleClickFullSession = nil
            }
        }
    }
    
    // video muted
    func rtcEngine(engine: AgoraRtcEngineKit!, didVideoMuted muted: Bool, byUid uid: UInt) {
        setVideoMuted(muted, forUid: uid)
    }
    
    //remote stat
    func rtcEngine(engine: AgoraRtcEngineKit!, remoteVideoStats stats: AgoraRtcRemoteVideoStats!) {
        if let stats = stats, let session = fetchSessionOfUid(stats.uid) {
            session.updateMediaInfo(resolution: CGSizeMake(CGFloat(stats.width), CGFloat(stats.height)), bitRate: Int(stats.receivedBitrate), fps: Int(stats.receivedFrameRate))
        }
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, device deviceId: String!, type deviceType: AgoraRtcDeviceType, stateChanged state: Int) {
        NSNotificationCenter.defaultCenter().postNotificationName(DeviceListChangeNotificationKey, object: NSNumber(integer: deviceType.rawValue))
    }
    
    //data channel
    func rtcEngine(engine: AgoraRtcEngineKit!, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: NSData!) {
        guard let data = data, let string = String(data: data, encoding: NSUTF8StringEncoding) where !string.isEmpty else {
            return
        }
        chatMessageVC?.appendChat(string, fromUid: Int64(uid))
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
        chatMessageVC?.appendAlert("Data channel error: \(error)")
    }
}

//MARK: - IKImageView
extension RoomViewController {
    override func numberOfItemsInImageBrowser(aBrowser: IKImageBrowserView!) -> Int {
        return windows.items.count
    }
    
    override func imageBrowser(aBrowser: IKImageBrowserView!, itemAtIndex index: Int) -> AnyObject! {
        let item = windows.items[index]
        return item
    }
    
    override func imageBrowser(aBrowser: IKImageBrowserView!, cellWasDoubleClickedAtIndex index: Int) {
        guard let selected = aBrowser.selectionIndexes() else {
            return
        }
        
        let index = selected.firstIndex
        guard index < windows.items.count else {
            return
        }
        
        let window = windows.items[index].window
        startShareWindow(window)
        screenSharingStatus = .sharing
    }
}

//MARK: - window
extension RoomViewController: NSWindowDelegate {
    func windowShouldClose(sender: AnyObject) -> Bool {
        leaveChannel()
        return false
    }
}
