//
//  AdvancedPrefernceViewController.swift
//  CloudMinder
//
//  Created by Dana Basken on 11/15/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import Cocoa
import Preferences

@available(OSX 11.0, *)
class AdvancedPreferenceViewController: NSViewController, PreferencePane {

    let preferencePaneIdentifier = Preferences.PaneIdentifier.advanced
    let preferencePaneTitle = "Advanced"
    let toolbarItemIcon = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "Advanced preferences")!

    override var nibName: NSNib.Name? { "AdvancedPreferenceViewController" }

    @IBOutlet weak var gcloudPathTextField: NSTextField!
    @IBOutlet weak var gcloudValidPathImageCell: NSImageCell!
    
    var timer: Timer!
    let fileManager = FileManager.default

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
    }
    
    func showValidPathIcon(name: String) {
        DispatchQueue.main.async {
            self.gcloudValidPathImageCell.image = NSImage(named: name)
        }
    }
    
    override func viewWillAppear() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            var isDir : ObjCBool = false
            if (FileManager.default.fileExists(atPath: self.gcloudPathTextField.stringValue, isDirectory: &isDir)) {
                if (isDir.boolValue) {
                    self.showValidPathIcon(name: "IconError")
                } else {
                    if (FileManager.default.isExecutableFile(atPath: self.gcloudPathTextField.stringValue)) {
                        self.showValidPathIcon(name: "IconGreen")
                    } else {
                        self.showValidPathIcon(name: "IconError")
                    }
                }
            } else {
                self.showValidPathIcon(name: "IconError")
            }
        }
    }

    override func viewWillDisappear() {
        gcloudPathAction(self)
        timer.invalidate()
    }

    @IBAction func gcloudPathAction(_ sender: Any) {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(gcloudPathTextField.stringValue, forKey: "gcloudPath")
    }

    func loadSettings() {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        if (userDefaults!.value(forKey: "gcloudPath") != nil) {
            gcloudPathTextField.stringValue = userDefaults!.string(forKey: "gcloudPath")!
        }
    }

}
