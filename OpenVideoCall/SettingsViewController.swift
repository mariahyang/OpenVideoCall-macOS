//
//  SettingsViewController.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 2/20/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

protocol SettingsVCDelegate: class {
    func settingsVC(settingsVC: SettingsViewController, closeWithProfile videoProfile: AgoraRtcVideoProfile)
}

class SettingsViewController: NSViewController {

    @IBOutlet weak var profilePopUpButton: NSPopUpButton!
    
    var videoProfile: AgoraRtcVideoProfile!
    var delegate: SettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        loadProfileItems()
    }
    
    @IBAction func doProfileChanged(sender: NSPopUpButton) {
        let profile = AgoraRtcVideoProfile.validProfileList()[sender.indexOfSelectedItem]
        videoProfile = profile
    }
    
    @IBAction func doConfirmClicked(sender: NSButton) {
        delegate?.settingsVC(self, closeWithProfile: videoProfile)
    }
}

private extension SettingsViewController {
    func loadProfileItems() {
        profilePopUpButton.addItemsWithTitles(AgoraRtcVideoProfile.validProfileList().map { (res) -> String in
            return res.description()
        })
        profilePopUpButton.selectItemWithTitle(videoProfile.description())
    }
}
