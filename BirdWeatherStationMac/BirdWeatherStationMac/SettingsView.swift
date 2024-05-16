//
//  SettingsView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 30.03.24.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    
    @AppStorage("PUCToken", store: .standard) var pucToken : String = ""
    @AppStorage("LocalizationCSV", store: .standard) var csvURL: URL?
    @AppStorage("LocalizationCSVBookmark", store: .standard) var csvURLBookmark: Data?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter your PUC token to start querying the server")
                .bold()
            HStack {
                TextField("Auth token", text: $pucToken)
                    .frame(width: 200)
                Button("Test token") {
                    Task {
                        _ = await BirdWeatherRestBridge().testStation()
                    }
                }
            }
            Divider()
            Text("Localization of species names")
                .bold()
            HStack {
                TextField("no localization file choosen", value: $csvURL, format: .url)
                    .disabled(true)
                Button("Choose csv file") {
                    let oP = NSOpenPanel()
                    oP.allowedContentTypes = [.delimitedText]
                    if oP.runModal() == .OK, let url = oP.url {
                        csvURL = url
                        if let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                            csvURLBookmark = data
                            SpeciesLocalizer.shared.updateTranslationDict()
                        }
                    }
                }
            }
            
            /*Toggle("Show species images in list", isOn: $showSpeciesImage)
            Divider()
            Text("Species list settings")
                .font(.title)
            Picker("Sample period", selection: $samplePeriod) {
                ForEach(Period.allCases, id: \.self) { aPeriod in
                    Text(aPeriod.rawValue)
                        .tag(aPeriod)
                }
            }
            .frame(width: 200)
            Picker("Sort by", selection: $sortSpeciesList) {
                Text("top")
                    .tag("top")
                Text("scientific_name")
                    .tag("scientific_name")
                Text("common_name")
                    .tag("common_name")
            }
            .frame(width: 200)
            HStack {
                Text("Limit")
                TextField("Limit", value: $limit, formatter: NumberFormatter(), prompt: Text("Limit"))
                    .frame(width: 30)
            }*/
        }
        .frame(width: 500)
        .padding()
    }
}

#Preview {
    SettingsView()
}
