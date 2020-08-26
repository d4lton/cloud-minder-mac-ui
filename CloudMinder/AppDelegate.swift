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

    var window: NSWindow!
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var timer: Timer!
    var center: UNUserNotificationCenter!
    var lastNotification: Date!
    var contentView: ContentView!

    var ipAddress = "localhost"
    var port = 2112

    func applicationDidFinishLaunching(_ aNotification: Notification) {
                
        let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
        
        if (userDefaults != nil) {
            let configIpAddress = userDefaults!.string(forKey: "ipAddress")
            print("configIpAddress: \(configIpAddress)")
            if (configIpAddress == nil) {
                userDefaults!.set(ipAddress, forKey: "ipAddress")
                userDefaults!.set(port, forKey: "port")
                userDefaults!.synchronize()
            }
            ipAddress = userDefaults!.string(forKey: "ipAddress") ?? ipAddress
            port = userDefaults!.integer(forKey: "port") != 0 ? userDefaults!.integer(forKey: "port") : port
        }
        print("settings ipAddress: \(ipAddress) : \(port)")

        setUpMenuButton()
        setUpNotifications()
        startTimer()
    }
    
    func setUpMenuButton() {
        contentView = ContentView(address: ipAddress, port: port)
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
        let show = UNNotificationAction(identifier: "show", title: "Later", options: .foreground)
        let category = UNNotificationCategory(identifier: "alarm", actions: [show], intentIdentifiers: [])
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
    
    func showNotification(message: String) {
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
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        self.center.add(request)
        lastNotification = now
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            print("contentView.address: \(self.contentView.address)")
            let url = URL(string: "http://\(self.contentView.address):\(self.contentView.port)/status")
            let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                if error != nil {
                    self.showOffIcon()
                } else {
                    DispatchQueue.main.async {
                        self.showNormalIcon()
                    }
                    let status = String(data: data!, encoding: .utf8)?.convertToDictionary()
                    print("\(status)")
                    if (status != nil) {
                        let hostname = status!["hostname"] as! String
                        let hours = status!["uptime"] as! Double / 3600.0
                        let loadpercent = status!["loadpercent"] as! Double
                        print("up hours: \(hours), loadpercent: \(loadpercent)")
                        var alert = false
                        var message = ""
                        if (hours >= 1.0 && loadpercent < 1.0) {
                            alert = true
                            message = "Node \(hostname) is not being utilized, consider shutting it down."
                        }
                        if (hours >= 8) {
                            alert = true
                            message = "Node \(hostname) has been up for \(hours) hours, consider shutting it down."
                        }
                        if (alert) {
                            self.showNotification(message: message)
                        }
                    } else {
                        self.showErrorIcon()
                    }
                }
            }
            task.resume()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let customData = userInfo["customData"] as? String {
            print("Custom data received: \(customData)")
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                print("user clicked 'Close'")
            case "show":
                print("user clicked 'Later'")
                break
            default:
                break
            }
        }
        completionHandler()
    }

}

