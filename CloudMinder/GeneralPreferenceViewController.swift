//
//  GeneralPreferenceViewController.swift
//  CloudMinder
//
//  Created by Dana Basken on 11/15/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import Cocoa
import Preferences

@available(OSX 11.0, *)
final class GeneralPreferenceViewController: NSViewController, PreferencePane {

    let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    let preferencePaneTitle = "General"
    let toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General preferences")!

    override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }

    @IBOutlet weak var projectTextField: NSTextField!
    @IBOutlet weak var zoneTextField: NSTextField!
    @IBOutlet weak var prefixTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
    }
    
    override func viewWillDisappear() {
        projectAction(self)
        zoneAction(self)
        prefixAction(self)
    }
    
    @IBAction func projectAction(_ sender: Any) {
        print("projectAction")
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(projectTextField.stringValue, forKey: "project")
    }

    @IBAction func zoneAction(_ sender: Any) {
        print("zoneAction")
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(zoneTextField.stringValue, forKey: "zone")
    }
    
    @IBAction func prefixAction(_ sender: Any) {
        print("prefixAction")
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(prefixTextField.stringValue, forKey: "nodeName")
    }
    
    func loadSettings() {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        if (userDefaults!.value(forKey: "project") != nil) {
            projectTextField.stringValue = userDefaults!.string(forKey: "project")!
        }
        if (userDefaults!.value(forKey: "zone") != nil) {
            zoneTextField.stringValue = userDefaults!.string(forKey: "zone")!
        }
        if (userDefaults!.value(forKey: "nodeName") != nil) {
            prefixTextField.stringValue = userDefaults!.string(forKey: "nodeName")!
        }
    }
    
}
