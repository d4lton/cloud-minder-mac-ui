//
//  AppDelegate.swift
//  CloudMinder
//
//  Created by Dana Basken on 8/25/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import Foundation
import UserNotifications
import Cocoa
import SwiftUI
import Preferences

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }
}

extension Preferences.PaneIdentifier {
    static let general = Self("general")
    static let advanced = Self("advanced")
}

@available(OSX 11.0, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    struct NetworkInterface: Codable, Hashable {
        let networkIP: String?
    }

    struct Node: Codable, Hashable {
        let name: String?
        let status: String?
        let networkInterfaces: [NetworkInterface]?
    }
    
    struct NodeStatus: Codable {
        let node: Node?
        let state: String?
        var error: String = ""
        let uptimeHours: Double?
        let loadPercent: Double?
    }
    
    struct Zone: Codable, Hashable {
        let name: String?
        let status: String?
    }
    
    struct Project: Codable, Hashable {
        let projectId: String?
        let name: String?
    }

    var statusBarItem: NSStatusItem!
    var timer: Timer!
    var center: UNUserNotificationCenter!
    var lastNotification: Date!
    var availableVersion: String = ""
    var menu: NSMenu!
    var statusViewController: StatusViewController!
    var statusWindowStoryboard: NSStoryboard!
    var statusWindowController: NSWindowController!
    
    var nodeName = ""
    var port = 2112
    var project = ""
    var zone = "us-central1-a"
    var nodes: [Node] = []
    var zones: [Zone] = []
    var projects: [Project] = []
    var gcloudPath = "\(NSHomeDirectory())/google-cloud-sdk/bin/gcloud"

    lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: [
            GeneralPreferenceViewController(),
            AdvancedPreferenceViewController()
        ]
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        createStatusWindowController()
        refresh()
        setUpMenuButton()
        setUpNotifications()
        startTimer()
    }
    
    func refresh() {
        print("starting refresh...")
        zones = getZones()
        projects = getProjects()
        refreshConfiguration()
        print("refresh done.")
    }
    
    func createStatusWindowController() {
        statusWindowStoryboard = NSStoryboard(name: NSStoryboard.Name("Status"), bundle: nil)
        statusWindowController = statusWindowStoryboard.instantiateController(withIdentifier: "WindowController") as? NSWindowController
    }
    
    func refreshConfiguration() {
        let originalNodeName = nodeName
        loadSettings()
        if (originalNodeName != nodeName) {
            print("nodeName changed: \(originalNodeName) -> \(nodeName)")
            setUpNodes()
        }
    }

    func loadSettings() {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")

        if (userDefaults?.value(forKey: "nodeName") != nil) {
            nodeName = userDefaults!.string(forKey: "nodeName")!
        } else {
            userDefaults!.set(nodeName, forKey: "nodeName")
        }

        if (userDefaults?.value(forKey: "project") != nil) {
            project = userDefaults!.string(forKey: "project")!
        } else {
            userDefaults!.set(project, forKey: "project")
        }

        if (userDefaults?.value(forKey: "zone") != nil) {
            zone = userDefaults!.string(forKey: "zone")!
        } else {
            userDefaults!.set(zone, forKey: "zone")
        }

        if (userDefaults?.value(forKey: "gcloudPath") != nil) {
            gcloudPath = userDefaults!.string(forKey: "gcloudPath")!
        } else {
            userDefaults!.set(gcloudPath, forKey: "gcloudPath")
        }

        if (userDefaults?.value(forKey: "port") != nil) {
            port = userDefaults!.integer(forKey: "port")
        } else {
            userDefaults!.set(port, forKey: "port")
        }
    }
    
    func getAvailableVersion() {
        let url = URL(string: "https://api.github.com/repos/d4lton/cloud-minder-mac-ui/releases/latest")
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            let status = String(data: data!, encoding: .utf8)?.convertToDictionary()
            self.availableVersion = status!["name"] as! String
        }
        task.resume()
    }
    
    func getZones() -> [Zone] {
        let response = exec(execPath: gcloudPath, arguments: "compute", "zones", "list", "--format=json(name,status)")
        do {
            return try JSONDecoder().decode([Zone].self, from: Data(response.utf8)).filter { $0.status == "UP" }.sorted { $0.name! < $1.name! }
        } catch let error {
            print(error)
        }
        return []
    }
    
    func getProjects() -> [Project] {
        let response = exec(execPath: gcloudPath, arguments: "projects", "list", "--format=json(projectId,name)")
        do {
            return try JSONDecoder().decode([Project].self, from: Data(response.utf8)).sorted { $0.projectId! < $1.projectId! }
        } catch let error {
            print(error)
        }
        return []
    }
    
    func getNodes(name: String) -> [Node] {
        let response = exec(execPath: gcloudPath, arguments: "compute", "instances", "list", "--project=\(project)", "--format=json(name,status,networkInterfaces[].networkIP)")
        do {
            return try JSONDecoder().decode([Node].self, from: Data(response.utf8)).filter { ($0.name?.starts(with: name))! }
        } catch let error {
            print(error)
        }
        return []
    }

    func setUpNodes() {
        nodes = getNodes(name: nodeName)
        getAvailableVersion()
        updateStatusView()
        print(nodes)
    }
    
    func setUpMenuButton() {
        createMenu()
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = statusBarItem.button {
            button.image = NSImage(named: "IconOff")
            statusBarItem.menu = menu
        }
    }

    func createMenu() {
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About CloudMinder", action: #selector(AppDelegate.about(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start All", action: #selector(AppDelegate.startAll(_:)), keyEquivalent: "+"))
        menu.addItem(NSMenuItem(title: "Stop All", action: #selector(AppDelegate.stopAll(_:)), keyEquivalent: "-"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(AppDelegate.settings(_:)), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Status...", action: #selector(AppDelegate.status(_:)), keyEquivalent: ";"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit CloudMinder", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    @objc func about(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    @objc func startAll(_ sender: Any?) {
        self.startStopAll(action: "start")
    }

    @objc func stopAll(_ sender: Any?) {
        self.startStopAll(action: "stop")
    }

    func startStopAll(action: String) {
        let queue = DispatchQueue(label: "com.basken.CloudMinder.startStopQueue")
        for node in nodes {
            queue.async { [self] in
                let result = exec(execPath: gcloudPath, arguments: "compute", "instances", action, "--project=\(project)", "--zone=\(zone)", node.name!)
                print(result)
                if (action == "start") {
                    showNotification(message: "Node \(node.name ?? "<unknown>") has been started.", node: node, immediate: true)
                } else {
                    showNotification(message: "Node \(node.name ?? "<unknown>") has been stopped.", node: node, immediate: true)
                }
            }
        }
    }

    @objc func settings(_ sender: Any?) {
        self.preferencesWindowController.show()
    }

    @objc func status(_ sender: Any?) {
        self.statusWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        self.updateStatusView()
    }
    
    func updateStatusView(statuses: [NodeStatus] = []) {
        let controller = self.statusWindowController.contentViewController as! StatusViewController
        if (controller.isViewLoaded) {
            controller.setNodes(nodes: self.nodes)
            controller.setNodeStatuses(statuses: statuses)
        }
    }

    func setUpNotifications() {
        center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        }
        let poweroff = UNNotificationAction(identifier: "poweroff", title: "Poweroff", options: .foreground)
        let category = UNNotificationCategory(identifier: "alarm", actions: [poweroff], intentIdentifiers: [])
        center.setNotificationCategories([category])
        center.delegate = self
    }
    
    func showNormalIcon() {
        DispatchQueue.main.async {
            self.statusBarItem.button!.image = NSImage(named: "Icon")
        }
    }
    
    func showErrorIcon() {
        DispatchQueue.main.async {
            self.statusBarItem.button!.image = NSImage(named: "IconError")
        }
    }

    func showOffIcon() {
        DispatchQueue.main.async {
            self.statusBarItem.button!.image = NSImage(named: "IconOff")
        }
    }
    
    func showSettingsIcon() {
        DispatchQueue.main.async {
            self.statusBarItem.button!.image = NSImage(named: "IconSettings")
        }
    }

    func showNotification(message: String, node: Node, immediate: Bool = false) {
        let now = Date()
        if (lastNotification != nil && !immediate) {
            let difference = now.timeIntervalSince(lastNotification)
            if (difference < 3600.0) {
                return
            }
        }
        let content = UNMutableNotificationContent()
        content.title = "CloudMinder"
        content.body = message
        content.userInfo = ["address": node.networkInterfaces?.first?.networkIP as Any]
        if (!immediate) {
            content.categoryIdentifier = "alarm"
            content.sound = UNNotificationSound.default
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        self.center.add(request)
        lastNotification = now
    }
    
    func getNodeStatus(node: Node, completion: @escaping (NodeStatus) -> ()) {
        let address = node.networkInterfaces?.first?.networkIP
        let url = URL(string: "http://\(address ?? ""):\(self.port)/status")
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if (error == nil) {
                let status = String(data: data!, encoding: .utf8)?.convertToDictionary()
                if (status != nil) {
                    let uptimeHours = status!["uptime"] as! Double / 3600.0
                    let loadPercent = status!["loadpercent"] as! Double
                    var state = "RUNNING"
                    if (status!["state"] != nil) {
                        state = status!["state"] as! String
                    } else {
                        if (uptimeHours >= 1.0 && loadPercent < 1.0) {
                            state = "IDLE"
                        }
                        if (uptimeHours >= 8) {
                            state = "LONG_RUNNING"
                        }
                    }
                    completion(NodeStatus(node: node, state: state, uptimeHours: uptimeHours, loadPercent: loadPercent))
                } else {
                    completion(NodeStatus(node: node, state: "ERROR", error: "API_ERROR", uptimeHours: 0.0, loadPercent: 0.0))
                }
            } else {
                completion(NodeStatus(node: node, state: "ERROR", error: "NO_API", uptimeHours: 0.0, loadPercent: 0.0))
            }
        }
        task.resume()
    }
    
    func getNodeStatuses(completion: @escaping ([NodeStatus]) -> ()) {
        var results: [NodeStatus] = []
        let group = DispatchGroup()
        for node in nodes {
            group.enter()
            getNodeStatus(node: node) { status in
                results.append(status)
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    func settingsAreValid() -> Bool {
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        if (userDefaults?.string(forKey: "nodeName") == "") {
            return false
        }
        if (userDefaults?.string(forKey: "project") == "") {
            return false
        }
        return true
    }

    func startTimer() {
        // update the IP addresses every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { timer in self.setUpNodes() }
        // check to see if the nodes are up and underutilized every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            self.refreshConfiguration()
            if (self.settingsAreValid()) {
                self.getNodeStatuses { statuses in
                    self.updateStatusView(statuses: statuses)
                    var overallState = "IDLE"
                    print("\(statuses)")
                    for status in statuses {
                        if (status.state == "IDLE") {
                            self.showNotification(message: "Node \(status.node?.name ?? "<unknown>") is not being utilized", node: status.node!)
                        }
                        if (status.state == "LONG_RUNNING") {
                            self.showNotification(message: "Node \(status.node?.name ?? "<unknown>") has been up for \(Int(status.uptimeHours!)) hours", node: status.node!)
                        }
                        if (status.node?.status == "RUNNING") {
                            if (status.state == "ERROR") {
                                overallState = "ERROR"
                            } else {
                                if (overallState != "ERROR") {
                                    overallState = "RUNNING"
                                }
                            }
                        }
                    }
                    switch (overallState) {
                    case "IDLE":
                        self.showOffIcon()
                        break
                    case "ERROR":
                        self.showErrorIcon()
                        break
                    case "RUNNING":
                        self.showNormalIcon()
                        break
                    default:
                        break
                    }
                    print("overall state: \(overallState)")
                }
            } else {
                self.showSettingsIcon()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
    }
    
    func powerOff(address: String) {
        let url = URL(string: "http://\(address):\(port)/poweroff")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        }
        task.resume()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            print("user clicked 'Close'")
            break
        case "poweroff":
            print("user clicked 'Poweroff'")
            powerOff(address: userInfo["address"] as! String)
            break
        default:
            break
        }
        completionHandler()
    }

    func exec(execPath: String, arguments: String...) -> String {
        let process = Process()
        process.launchPath = execPath
        process.arguments = arguments
        let stdout = Pipe()
        process.standardOutput = stdout
        process.launch()
        process.waitUntilExit()
        return String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

}
