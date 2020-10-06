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

    var body: some View {
        VStack(alignment: .leading) {

            Text("CloudMinder v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String) ©2020 by Dana Basken").padding(.all)

            VStack(alignment: .leading) {
                Text("GCP Node Name").font(.callout).bold()
                TextField("", text: self.$nodeName)
            }.padding(.all)

            Button(action: {
                let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
                userDefaults!.set(self.nodeName, forKey: "nodeName")
            }, label: {
                Text("Save")
            }).padding(.all).frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()

            VStack(alignment: .leading) {
                ForEach(nodes, id:\.self) { node in
                    Text("\(node.name!): \(node.status!)")
                }
            }.padding(.all)

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
