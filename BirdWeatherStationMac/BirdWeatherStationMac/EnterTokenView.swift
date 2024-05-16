//
//  ContentView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 27.03.24.
//

import SwiftUI

struct EnterTokenView: View {
    
    @AppStorage("Connected", store: .standard) var connected : Bool = false
    @AppStorage("PUCToken", store: .standard) var pucToken : String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Enter your PUC token to start querying the server")
                TextField("Auth token", text: $pucToken)
                    .frame(width: 200)
                Button("Test token") {
                    Task {
                        _ = await BirdWeatherRestBridge().testStation()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
