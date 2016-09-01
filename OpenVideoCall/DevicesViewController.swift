//
//  DevicesViewController.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 6/2/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

let DeviceListChangeNotificationKey = "io.agora.deviceListChangeNotification"
let VolumeChangeNotificationKey = "io.agora.volumeChangeNotification"

class DevicesViewController: NSViewController {
    
    @IBOutlet weak var inputDevicePopUpButton: NSPopUpButton!
    @IBOutlet weak var inputDeviceVolSlider: NSSlider!
    @IBOutlet weak var intputDeviceTestButton: NSButton!
    @IBOutlet weak var inputDeviceVolLevelIndicator: NSLevelIndicator!
    
    @IBOutlet weak var outputDevicePopUpButton: NSPopUpButton!
    @IBOutlet weak var outputDeviceVolSlider: NSSlider!
    @IBOutlet weak var outputDeviceTestButton: NSButton!
    
    @IBOutlet weak var cameraPopUpButton: NSPopUpButton!
    @IBOutlet weak var cameraTestButton: NSButton!
    @IBOutlet weak var cameraPreviewView: NSView!
    
    var agoraKit: AgoraRtcEngineKit!
    var couldTest = true
    
    private var recordingDeviceId: String?
    private var recordingDevices = [AgoraRtcDeviceInfo]()
    private var playoutDeviceId: String?
    private var playoutDevices = [AgoraRtcDeviceInfo]()
    private var captureDeviceId: String?
    private var captureDevices = [AgoraRtcDeviceInfo]()
    
    private var isInputTesting = false {
        didSet {
            configButton(intputDeviceTestButton, isTesting: isInputTesting)
            if isInputTesting {
                agoraKit?.startRecordingDeviceTest(200)
            } else {
                agoraKit?.stopRecordingDeviceTest()
            }
            inputDeviceVolLevelIndicator?.hidden = !isInputTesting
        }
    }
    private var isOutputTesting = false {
        didSet {
            configButton(outputDeviceTestButton, isTesting: isOutputTesting)
            if isOutputTesting {
                if let path = NSBundle.mainBundle().pathForResource("test", ofType: "wav") {
                    agoraKit?.startPlaybackDeviceTest(path)
                }
            } else {
                agoraKit?.stopPlaybackDeviceTest()
            }
        }
    }
    private var isCameraputTesting = false {
        didSet {
            configButton(cameraTestButton, isTesting: isCameraputTesting)
            if isCameraputTesting {
                if let view = cameraPreviewView {
                    agoraKit?.startCaptureDeviceTest(view)
                }
            } else {
                agoraKit?.stopCaptureDeviceTest()
            }
        }
    }
    private var deviceVolume = 0 {
        didSet {
            inputDeviceVolLevelIndicator?.integerValue = deviceVolume
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        cameraPreviewView.wantsLayer = true
        cameraPreviewView.layer?.backgroundColor = NSColor.blackColor().CGColor
        
        configButtonStyle()
        loadDevices()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        configStyleOfWindow(view.window!)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if couldTest {
            if isInputTesting {
                isInputTesting = false
            }
            if isOutputTesting {
                isOutputTesting = false
            }
            if isCameraputTesting {
                isCameraputTesting = false
            }
        }
    }
    
    @IBAction func doInputDeviceChanged(sender: NSPopUpButton) {
        if isInputTesting {
            isInputTesting = false
        }
        let deviceId = recordingDevices[sender.indexOfSelectedItem].deviceId
        agoraKit.setDevice(.DeviceType_Audio_Recording, deviceId: deviceId)
    }
    
    @IBAction func doInputDeviceTestClicked(sender: NSButton) {
        isInputTesting = !isInputTesting
    }
    
    @IBAction func doInputVolSliderChanged(sender: NSSlider) {
        let vol = sender.intValue
        agoraKit.setDeviceVolume(.DeviceType_Audio_Recording, volume: vol)
    }
    
    @IBAction func doOutputDeviceChanged(sender: NSPopUpButton) {
        if isOutputTesting {
            isOutputTesting = false
        }
        let deviceId = playoutDevices[sender.indexOfSelectedItem].deviceId
        agoraKit.setDevice(.DeviceType_Audio_Playout, deviceId: deviceId)
    }
    
    @IBAction func doOutputDeviceTestClicked(sender: NSButton) {
        isOutputTesting = !isOutputTesting
    }
    
    @IBAction func doOutputVolSliderChanged(sender: NSSlider) {
        let vol = sender.intValue
        agoraKit.setDeviceVolume(.DeviceType_Audio_Playout, volume: vol)
    }
    
    @IBAction func doCameraChanged(sender: NSPopUpButton) {
        if isCameraputTesting {
            isCameraputTesting = false
        }
        let deviceId = captureDevices[sender.indexOfSelectedItem].deviceId
        agoraKit.setDevice(.DeviceType_Video_Capture, deviceId: deviceId)
    }
    
    @IBAction func doCameraTestClicked(sender: NSButton) {
        isCameraputTesting = !isCameraputTesting
    }
}

private extension DevicesViewController {
    func configStyleOfWindow(window: NSWindow) {
        window.styleMask |= NSFullSizeContentViewWindowMask
        window.titlebarAppearsTransparent = true
        window.movableByWindowBackground = true
        
        window.minSize = CGSizeMake(600, 600)
        window.maxSize = CGSizeMake(600, 600)
    }
    
    func configButtonStyle() {
        configButton(intputDeviceTestButton, isTesting: false)
        configButton(outputDeviceTestButton, isTesting: false)
        configButton(cameraTestButton, isTesting: false)
        
        intputDeviceTestButton.hidden = !couldTest
        outputDeviceTestButton.hidden = !couldTest
        cameraTestButton.hidden = !couldTest
    }
    
    func configButton(button: NSButton, isTesting: Bool) {
        button.title = isTesting ? "Stop Test" : "Test"
    }
}

//MARK: - device list
private extension DevicesViewController {
    func loadDevices() {
        loadDevice(.DeviceType_Audio_Playout)
        loadDevice(.DeviceType_Audio_Recording)
        loadDevice(.DeviceType_Video_Capture)
        
        NSNotificationCenter.defaultCenter().addObserverForName(DeviceListChangeNotificationKey, object: nil, queue: nil) { [weak self] (notify) in
            if let obj = notify.object as? NSNumber, let type = AgoraRtcDeviceType(rawValue: obj.integerValue) {
                self?.loadDevice(type)
            }
        }
        
        if couldTest {
            NSNotificationCenter.defaultCenter().addObserverForName(VolumeChangeNotificationKey, object: nil, queue: nil, usingBlock: { [weak self] (notify) in
                if let obj = notify.object as? NSNumber {
                    self?.deviceVolume = obj.integerValue
                }
            })
        }
    }
    
    func loadDevice(type: AgoraRtcDeviceType) {
        guard let devices = agoraKit.enumerateDevices(type) as NSArray as? [AgoraRtcDeviceInfo] else {
            return
        }
        
        let deviceId = agoraKit.getDeviceId(type)
        switch type {
        case .DeviceType_Audio_Recording:
            recordingDevices = devices
            recordingDeviceId = deviceId
            updatePopUpButton(inputDevicePopUpButton, withValue: deviceId, inValueList: devices)
        case .DeviceType_Audio_Playout:
            playoutDevices = devices
            playoutDeviceId = deviceId
            updatePopUpButton(outputDevicePopUpButton, withValue: deviceId, inValueList: devices)
        case .DeviceType_Video_Capture:
            captureDevices = devices
            captureDeviceId = deviceId
            updatePopUpButton(cameraPopUpButton, withValue: deviceId, inValueList: devices)
        default:
            break
        }
        
        updateVolumeOfDevice(type)
    }
    
    func updatePopUpButton(button: NSPopUpButton, withValue value: String?, inValueList list: [AgoraRtcDeviceInfo]) {
        button.removeAllItems()
        button.addItemsWithTitles(list.map({ (info) -> String in
            return info.deviceName
        }))
        
        let deviceIds = list.map { (info) -> String in
            return info.deviceId
        }
        if let value = value, let index = deviceIds.indexOf(value) {
            button.selectItemAtIndex(index)
        }
    }
    
    func updateVolumeOfDevice(type: AgoraRtcDeviceType) {
        switch type {
        case .DeviceType_Audio_Recording:
            let vol = agoraKit.getDeviceVolume(type)
            inputDeviceVolSlider.intValue = vol
        case .DeviceType_Audio_Playout:
            let vol = agoraKit.getDeviceVolume(type)
            outputDeviceVolSlider.intValue = vol
        default:
            return
        }
    }
}
