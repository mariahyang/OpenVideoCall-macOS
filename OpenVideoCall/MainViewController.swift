//
//  MainViewController.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 2/20/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet weak var roomInputTextField: NSTextField!
    @IBOutlet weak var encryptionTextField: NSTextField!
    @IBOutlet weak var encryptionPopUpButton: NSPopUpButton!
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var joinButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    
    var videoProfile = AgoraRtcVideoProfile.defaultProfile()
    private var agoraKit: AgoraRtcEngineKit!
    private var encryptionType = EncryptionType.xts128
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        loadAgoraKit()
        loadEncryptionItems()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        roomInputTextField.becomeFirstResponder()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let segueId = segue.identifier where !segueId.isEmpty else {
            return
        }
        
        if segueId == "roomVCToSettingsVC" {
            let settingsVC = segue.destinationController as! SettingsViewController
            settingsVC.videoProfile = videoProfile
            settingsVC.delegate = self
        } else if segueId == "roomNameVCToVideoVC" {
            let videoVC = segue.destinationController as! RoomViewController
            if let sender = sender as? String {
                videoVC.roomName = sender
            }
            videoVC.encryptionSecret = encryptionTextField.stringValue
            videoVC.encryptionType = encryptionType
            videoVC.videoProfile = videoProfile
            videoVC.delegate = self
        } else if segueId == "roomVCToDevicesVC" {
            let devicesVC = segue.destinationController as! DevicesViewController
            devicesVC.agoraKit = agoraKit
            devicesVC.couldTest = true
        }
    }
    
    //MARK: - user actions
    @IBAction func doEncryptionChanged(sender: NSPopUpButton) {
        encryptionType = EncryptionType.allValue[sender.indexOfSelectedItem]
    }
    
    @IBAction func doTestClicked(sender: NSButton) {
        performSegueWithIdentifier("roomVCToDevicesVC", sender: nil)
    }
    
    @IBAction func doJoinClicked(sender: NSButton) {
        enterRoomWithName(roomInputTextField.stringValue)
    }
    
    @IBAction func doSettingsClicked(sender: NSButton) {
        performSegueWithIdentifier("roomVCToSettingsVC", sender: nil)
    }
}

private extension MainViewController {
    func loadAgoraKit() {
        agoraKit = AgoraRtcEngineKit.sharedEngineWithAppId(KeyCenter.AppId, delegate: self)
        agoraKit.enableVideo()
    }
    
    func loadEncryptionItems() {
        encryptionPopUpButton.addItemsWithTitles(EncryptionType.allValue.map { type -> String in
            return type.description()
        })
        encryptionPopUpButton.selectItemWithTitle(encryptionType.description())
    }
    
    func enterRoomWithName(roomName: String?) {
        guard let roomName = roomName where !roomName.isEmpty else {
            return
        }
        
        performSegueWithIdentifier("roomNameVCToVideoVC", sender: roomName)
    }
}

extension MainViewController: SettingsVCDelegate {
    func settingsVC(settingsVC: SettingsViewController, closeWithProfile profile: AgoraRtcVideoProfile) {
        videoProfile = profile
        settingsVC.view.window?.contentViewController = self
    }
}

extension MainViewController: RoomVCDelegate {
    func roomVCNeedClose(roomVC: RoomViewController) {
        guard let window = roomVC.view.window else {
            return
        }
        
        if window.styleMask & NSFullScreenWindowMask == NSFullScreenWindowMask {
            window.toggleFullScreen(nil)
        }
        
        window.styleMask |= NSFullSizeContentViewWindowMask | NSMiniaturizableWindowMask
        window.delegate = nil
        window.collectionBehavior = .Default

        window.contentViewController = self
        
        let size = CGSizeMake(720, 600)
        window.minSize = size
        window.setContentSize(size)
        window.maxSize = size
    }
}

extension MainViewController: AgoraRtcEngineDelegate {
    func rtcEngine(engine: AgoraRtcEngineKit!, reportAudioVolumeIndicationOfSpeakers speakers: [AnyObject]!, totalVolume: Int) {
        NSNotificationCenter.defaultCenter().postNotificationName(VolumeChangeNotificationKey, object: NSNumber(integer: totalVolume))
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, device deviceId: String!, type deviceType: AgoraRtcDeviceType, stateChanged state: Int) {
        NSNotificationCenter.defaultCenter().postNotificationName(DeviceListChangeNotificationKey, object: NSNumber(integer: deviceType.rawValue))
    }
}

//MARK: - text field
extension MainViewController: NSControlTextEditingDelegate {
    override func controlTextDidChange(obj: NSNotification) {
        guard let field = obj.object as? NSTextField else {
            return
        }
        
        let legalString = MediaCharacter.updateToLegalMediaString(field.stringValue)
        field.stringValue = legalString
    }
}
