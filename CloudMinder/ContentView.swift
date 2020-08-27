//
//  ContentView.swift
//  CloudMinder
//
//  Created by Dana Basken on 8/25/20.
//  Copyright © 2020 Dana Basken. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    @State var address: String = ""
    @State var port: Int = 0

    var body: some View {
        VStack(alignment: .leading) {

            Text("CloudMinder v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String) ©2020 by Dana Basken").padding(.all)

            VStack(alignment: .leading) {
                Text("DataProc IP").font(.callout).bold()
                TextField("", text: self.$address)
            }.padding(.all)
            
            VStack(alignment: .leading) {
                Text("API Port").font(.callout).bold()
                TextField("", text: .constant(String(self.port)))
            }.padding(.all)

            Button(action: {
                let userDefaults = UserDefaults(suiteName: "CloudMinder.settings")
                userDefaults!.set(self.address, forKey: "ipAddress")
                userDefaults!.set(self.port, forKey: "port")
            }, label: {
                Text("Save")
            }).padding(.all).frame(maxWidth: .infinity, maxHeight: .infinity)

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
