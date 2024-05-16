//
//  BirdWeatherStationApp.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 27.03.24.
//

import SwiftUI

@main
struct BirdWeatherStationApp: App {
    
    @AppStorage("Connected", store: .standard) var connected : Bool = false
    @AppStorage("PUCToken", store: .standard) var pucToken : String = ""
    
    var body: some Scene {
        WindowGroup {
            if !connected {
                EnterTokenView()
            } else {
                ContentView()
            }
        }
    }
}
