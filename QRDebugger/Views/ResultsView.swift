//
//  ResultsView.swift
//  QRDebugger
//
//  Created by Alexey Belousov on 22.03.2021.
//

import SwiftUI

struct ResultsView: View {

    @Environment(\.presentationMode) var presentationMode

    public let string: String

    var body: some View {
        VStack {
            TextEditor(text: .constant(string))

            Button(action: dismiss) {
                Text("Dismiss")
            }
        }.padding()
    }

    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(string: "Hello, world!")
            .preferredColorScheme(.dark)
    }
}
