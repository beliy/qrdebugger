//
//  ContentView.swift
//  QRDebugger
//
//  Created by Alexey Belousov on 11.03.2021.
//

import SwiftUI

struct ContentView: View {

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Apple")) {
                    NavigationLink(destination: CameraView(engine: .avfoundation)) {
                        Text("AVFoundation")
                    }

                    NavigationLink(destination: CameraView(engine: .vision)) {
                        Text("Vision")
                    }
                }
                Section(header: Text("Google")) {
                    NavigationLink(destination: CameraView(engine: .mlkit)) {
                        Text("ML Kit")
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)
                .listStyle(GroupedListStyle())
                .navigationTitle("Frameworks")
        }.accentColor(colorScheme == .dark ? .white : .black)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
