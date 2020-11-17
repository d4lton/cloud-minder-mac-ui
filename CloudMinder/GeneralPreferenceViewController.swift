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

    @IBOutlet weak var projectPopUpButton: NSPopUpButton!
    @IBOutlet weak var prefixTextField: NSTextField!
    @IBOutlet weak var zonePopUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpZoneButton()
        setUpProjectButton()
        loadSettings()
    }
    
    override func viewWillDisappear() {
        projectPopUpAction(self)
        zonePopUpAction(self)
        prefixAction(self)
    }
    
    func setUpZoneButton() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.zones.forEach { zone in
            zonePopUpButton.addItem(withTitle: zone.name!)
        }
    }
    
    func setUpProjectButton() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.projects.forEach { project in
            projectPopUpButton.addItem(withTitle: project.projectId!)
        }
    }
    
    @IBAction func projectPopUpAction(_ sender: Any) {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(projectPopUpButton.selectedItem!.title, forKey: "project")
    }

    @IBAction func zonePopUpAction(_ sender: Any) {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(zonePopUpButton.selectedItem!.title, forKey: "zone")
    }
    
    @IBAction func prefixAction(_ sender: Any) {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        userDefaults!.set(prefixTextField.stringValue, forKey: "nodeName")
    }
    
    func loadSettings() {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        if (userDefaults!.value(forKey: "project") != nil) {
            projectPopUpButton.selectItem(withTitle: userDefaults!.string(forKey: "project")!)
        }
        if (userDefaults!.value(forKey: "zone") != nil) {
            zonePopUpButton.selectItem(withTitle: userDefaults!.string(forKey: "zone")!)
        }
        if (userDefaults!.value(forKey: "nodeName") != nil) {
            prefixTextField.stringValue = userDefaults!.string(forKey: "nodeName")!
        }
    }
    
}
