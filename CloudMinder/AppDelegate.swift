//
//  AppDelegate.swift
//  CloudMinder
//
//  Created by Dana Basken on 8/25/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import Foundation
import UserNotifications

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }
}

import Cocoa
import SwiftUI

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
        let uptimeHours: Double?
        let loadPercent: Double?
    }

    var window: NSWindow!
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var timer: Timer!
    var center: UNUserNotificationCenter!
    var lastNotification: Date!
    var contentView: ContentView!

    var nodeName = ""
    var port = 2112
    var nodes: [Node] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        refreshConfiguration()
        setUpMenuButton()
        setUpNotifications()
        startTimer()
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
        if (userDefaults != nil) {
            let configIpAddress = userDefaults!.string(forKey: "ipAddress")
            if (configIpAddress == nil) {
                userDefaults!.set(nodeName, forKey: "nodeName")
                userDefaults!.synchronize()
            }
            nodeName = userDefaults!.string(forKey: "nodeName") ?? nodeName
        }
    }

    func getNodes(name: String) -> [Node] {
        let response = exec(execPath: "\(NSHomeDirectory())/google-cloud-sdk/bin/gcloud", arguments: "compute", "instances", "list", "--project=noumena-dev", "--format=json(name,status,networkInterfaces[].networkIP)")
        do {
            return try JSONDecoder().decode([Node].self, from: Data(response.utf8)).filter { ($0.name?.starts(with: name))! }
        } catch let error {
            print(error)
        }
        return []
    }

    func setUpNodes() {
        nodes = getNodes(name: nodeName)
        if (contentView != nil) {
            contentView.nodes = nodes
        }
        print(nodes)
    }
    
    func setUpMenuButton() {
        contentView = ContentView(nodeName: nodeName, nodes: nodes)
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 50)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
             button.image = NSImage(named: "IconOff")
             button.action = #selector(togglePopover(_:))
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

    @objc func togglePopover(_ sender: AnyObject?) {
         if let button = self.statusBarItem.button {
              if self.popover.isShown {
                   self.popover.performClose(sender)
              } else {
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    self.popover.contentViewController?.view.window?.becomeKey()
              }
         }
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
    
    func showActivityIcon(percent: Double) {
        DispatchQueue.main.async {
            let level = Int(percent) / 10
            print("activity level: \(level)")
            switch (level) {
            case 0:
                self.statusBarItem.button!.image = NSImage(named: "CloudIdle")
                break
            case 1:
                self.statusBarItem.button!.image = NSImage(named: "CloudOne")
                break
            case 2:
                self.statusBarItem.button!.image = NSImage(named: "CloudTwo")
                break
            case 3:
                self.statusBarItem.button!.image = NSImage(named: "CloudThree")
                break
            case 4:
                self.statusBarItem.button!.image = NSImage(named: "CloudFour")
                break
            case 5:
                self.statusBarItem.button!.image = NSImage(named: "CloudFive")
                break
            default:
                self.statusBarItem.button!.image = NSImage(named: "CloudSix")
                break
            }
        }
    }
    
    func showNotification(message: String, node: Node) {
        let now = Date()
        if (lastNotification != nil) {
            let difference = now.timeIntervalSince(lastNotification)
            if (difference < 3600.0) {
                return
            }
        }
        let content = UNMutableNotificationContent()
        content.title = "CloudMinder"
        content.body = message
        content.userInfo = ["address": node.networkInterfaces?.first?.networkIP as Any]
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default
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
                    if (uptimeHours >= 1.0 && loadPercent < 1.0) {
                        state = "UNDERUTILIZED"
                    }
                    if (uptimeHours >= 8) {
                        state = "LONG_RUNNING"
                    }
                    completion(NodeStatus(node: node, state: state, uptimeHours: uptimeHours, loadPercent: loadPercent))
                } else {
                    completion(NodeStatus(node: node, state: "ERROR", uptimeHours: 0.0, loadPercent: 0.0))
                }
            } else {
                completion(NodeStatus(node: node, state: "ERROR", uptimeHours: 0.0, loadPercent: 0.0))
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

    func startTimer() {
        // update the IP addresses every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { timer in self.setUpNodes() }
        // check to see if the nodes are up and underutilized every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            self.refreshConfiguration()
            self.getNodeStatuses { statuses in
                var overallState = "IDLE"
                print("\(statuses)")
                for status in statuses {
                    if (status.state == "UNDERUTILIZED") {
                        self.showNotification(message: "Node \(status.node?.name ?? "<unknown>") is not being utilized, consider shutting it down.", node: status.node!)
                    }
                    if (status.state == "LONG_RUNNING") {
                        self.showNotification(message: "Node \(status.node?.name ?? "<unknown>") has been up for \(Int(status.uptimeHours!)) hours, consider shutting it down.", node: status.node!)
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

