//
//  CameraView.swift
//  QRDebugger
//
//  Created by Alexey Belousov on 11.03.2021.
//

import AudioToolbox
import Combine
import SwiftUI

extension String: Identifiable {
    public var id: String { self }
}

struct CameraView: View {

    public enum Engine {
        case avfoundation, vision, mlkit
    }

    @State var resultsString: String? = nil

    public let engine: Engine

    var body: some View {
        #if targetEnvironment(simulator)
        Text("You're running in the simulator, which means the camera isn't available.")
            .multilineTextAlignment(.center)
            .padding()
        #else
        switch engine {
        case .avfoundation:
            AVFoundationViewController()
                .onOutputMetadata { string in
                    guard resultsString == nil else { return }

                    resultsString = string
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                .sheet(item: $resultsString) { value in
                    ResultsView(string: value)
                }
                .navigationTitle("AVFoundation")

        case .vision:
            VisionViewController()
                .onOutputMetadata { string in
                    guard resultsString == nil else { return }

                    resultsString = string
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                .sheet(item: $resultsString) { value in
                    ResultsView(string: value)
                }
                .navigationTitle("Vision")

        case .mlkit:
            MLKitViewController()
                .onOutputMetadata { string in
                    guard resultsString == nil else { return }

                    resultsString = string
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                .sheet(item: $resultsString) { value in
                    ResultsView(string: value)
                }
                .navigationTitle("ML Kit")
        }


        #endif
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(engine: .avfoundation)
    }
}
