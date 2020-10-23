//
//  ContentView.swift
//  CloudMinder
//
//  Created by Dana Basken on 8/25/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    @State var nodeName: String = ""
    @State var nodes: [AppDelegate.Node] = []
    @State var currentVersion: String = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
    @State var availableVersion: String = ""
    @State var owner: AppDelegate!

    var body: some View {

        VStack(alignment: .leading) {

            Text("CloudMinder v\(currentVersion) ©2020 by Dana Basken").padding(.all)

            VStack(alignment: .leading) {
                Text("GCP Node Name").font(.callout).bold()
                TextField("", text: self.$nodeName,
                          onCommit: {
                            let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
                            userDefaults!.set(self.nodeName, forKey: "nodeName")
                          }
                )
            }.padding(.all)

            VStack(alignment: .leading) {
                ForEach(nodes, id:\.self) { node in
                    Text("\(node.name!): \(node.status!)")
                }
            }.padding(.all)

            Divider()
            
            HStack {
                Button(action: {
                    for node in self.nodes {
                        owner.exec(execPath: "\(NSHomeDirectory())/google-cloud-sdk/bin/gcloud", arguments: "compute", "instances", "start", "--project=noumena-dev", "--zone=us-central1-a", node.name!)
                    }
                }, label: {
                    Text("Start All")
                }).frame(maxWidth: .infinity, maxHeight: .infinity)
                Button(action: {
                    for node in self.nodes {
                        owner.exec(execPath: "\(NSHomeDirectory())/google-cloud-sdk/bin/gcloud", arguments: "compute", "instances", "stop", "--project=noumena-dev", "--zone=us-central1-a", node.name!)
                    }
                }, label: {
                    Text("Stop All")
                }).frame(maxWidth: .infinity, maxHeight: .infinity)
            }.padding(.all)

            if (currentVersion != availableVersion && availableVersion != "") {
                Divider()
                Text("new version available: v\(availableVersion)").padding(.all)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
