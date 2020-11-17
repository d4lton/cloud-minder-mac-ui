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
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")

    override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }

    @IBOutlet weak var projectPopUpButton: NSPopUpButton!
    @IBOutlet weak var prefixTextField: NSTextField!
    @IBOutlet weak var zonePopUpButton: NSPopUpButton!
    @IBOutlet weak var checkVersionButton: NSButton!
    
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
        checkVersionAction(self)
    }
    
    func setUpZoneButton() {
        appDelegate.zones.forEach { zone in
            zonePopUpButton.addItem(withTitle: zone.name!)
        }
    }
    
    func setUpProjectButton() {
        appDelegate.projects.forEach { project in
            projectPopUpButton.addItem(withTitle: project.projectId!)
        }
    }
    
    @IBAction func projectPopUpAction(_ sender: Any) {
        userDefaults!.set(projectPopUpButton.selectedItem!.title, forKey: "project")
    }

    @IBAction func zonePopUpAction(_ sender: Any) {
        userDefaults!.set(zonePopUpButton.selectedItem!.title, forKey: "zone")
    }
    
    @IBAction func prefixAction(_ sender: Any) {
        userDefaults!.set(prefixTextField.stringValue, forKey: "nodeName")
    }

    @IBAction func checkVersionAction(_ sender: Any) {
        let value = checkVersionButton.state == .on ? true : false
        userDefaults!.set(value, forKey: "checkVersion")
    }

    func loadSettings() {
        if (userDefaults!.value(forKey: "project") != nil) {
            projectPopUpButton.selectItem(withTitle: userDefaults!.string(forKey: "project")!)
        }
        if (userDefaults!.value(forKey: "zone") != nil) {
            zonePopUpButton.selectItem(withTitle: userDefaults!.string(forKey: "zone")!)
        }
        if (userDefaults!.value(forKey: "nodeName") != nil) {
            prefixTextField.stringValue = userDefaults!.string(forKey: "nodeName")!
        }
        if (userDefaults!.value(forKey: "checkVersion") != nil) {
            checkVersionButton.state = (userDefaults!.bool(forKey: "checkVersion")) ? .on : .off
        }
    }
    
}
