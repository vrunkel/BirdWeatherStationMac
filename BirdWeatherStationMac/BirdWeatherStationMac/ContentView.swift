//
//  ContentView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 27.03.24.
//

import SwiftUI

struct ContentView: View {
    
    enum DataSelector: Int, Equatable, CaseIterable {
        case species = 0
        case detections
    }
    
    @AppStorage("Connected", store: .standard) var connected : Bool = false
    @AppStorage("DisplayedData", store: .standard) var displayedData: DataSelector = .species // 0 = species, 1 = detections
    
    @State var showSettingsPopover: Bool = false
    
    @State var stationStatus: StationStatus?
        
    var body: some View {
            VStack(spacing: 0) {
                NavigationSplitView {
                    VStack(alignment: .leading) {
                        Picker("", selection: $displayedData) {
                            Text("Species").tag(DataSelector.species)
                            Text("Detections").tag(DataSelector.detections)
                        }
                        .pickerStyle(.segmented)
                        //.padding(.top, 10)
                        .padding(.trailing, 10)
                        Divider()
                        if displayedData == .species {
                            SpeciesListView()
                        } else {
                            DetectionsListView()
                        }
                    }
                    .padding()
                    Spacer()
                } detail: {
                    NavigationStack {
                        Text("Map and Details")
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("export"), object: nil)
                        }, label: {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        })
                    }
                    ToolbarItem {
                        Button(action: {showSettingsPopover.toggle()}, label: {
                            Label("Settings", systemImage: "gearshape")
                        })
                        .popover(isPresented: $showSettingsPopover, content: {
                            SettingsView()
                        })
                    }
                }
                /*Divider()
                HStack {
                    Text("Filter setup")
                    Button("Delete token") {
                        connected = false
                    }
                }
                .padding()*/
            }
            .onAppear() {
                Task {
                    stationStatus = await BirdWeatherRestBridge().testStation()
                }
            }
    }
}

#Preview {
    ContentView()
}
