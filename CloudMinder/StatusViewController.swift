//
//  StatusViewController.swift
//  CloudMinder
//
//  Created by Dana Basken on 11/15/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import Cocoa

@available(OSX 11.0, *)
class StatusViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var statusTable: NSTableView!
    
    var nodes: [AppDelegate.Node] = []
    var statuses: [AppDelegate.NodeStatus] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        statusTable.delegate = self
        statusTable.dataSource = self
    }
    
    func setNodes(nodes: [AppDelegate.Node]) {
        self.nodes = nodes
        statusTable.reloadData()
    }
    
    func setNodeStatuses(statuses: [AppDelegate.NodeStatus]) {
        if (statuses.count > 0) {
            self.statuses = statuses
            statusTable.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.nodes.count
    }
        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let node = self.nodes[row]
        let nodeStatus = self.statuses.first(where: { $0.node == node })

        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "node") {

            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nodecell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = node.name ?? "???"
            return cellView

        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "status") {

            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "statuscell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = node.status ?? "???"
            return cellView

        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "state") {

            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "statecell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            var state = nodeStatus?.state ?? "<updating>"
            if (state == "ERROR") {
                cellView.textField?.textColor = NSColor.red
                state = nodeStatus?.error ?? "ERROR"
            } else {
                cellView.textField?.textColor = NSColor.white
            }
            cellView.textField?.stringValue = state
            return cellView

        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "uptime") {

            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "uptimecell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = String(format: "%3.1f hours", nodeStatus?.uptimeHours ?? 0.0)
            return cellView

        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "load") {

            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "loadcell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = String(format: "%3.1f%%", nodeStatus?.loadPercent ?? 0.0)
            return cellView

        }

        return nil
    }
}
