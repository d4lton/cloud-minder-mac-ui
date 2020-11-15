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

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
    }

    override func viewWillDisappear() {
        gcloudPathAction(self)
    }

    @IBAction func gcloudPathAction(_ sender: Any) {
        print("gcloudPathAction")
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
