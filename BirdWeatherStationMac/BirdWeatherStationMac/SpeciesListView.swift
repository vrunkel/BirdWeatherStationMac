//
//  SpeciesListView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 28.03.24.
//

import SwiftUI
import CachedAsyncImage
import UniformTypeIdentifiers

struct SpeciesListView: View {
    
    @AppStorage("SamplePeriod", store: .standard) var samplePeriod : Period = .week
    @AppStorage("SortSpeciesListBy", store: .standard) var sortSpeciesList : String = "top"
    @AppStorage("SortSpeciesListOrder", store: .standard) var sortSpeciesOrder : String = "desc"
    @AppStorage("ShowSpeciesImage", store: .standard) var showSpeciesImage : Bool = false
    @AppStorage("SpeciesResultsLimit", store: .standard) var limit: Int = 10
    @AppStorage("SpeciesSinceDate", store: .standard) var sinceDate: Date = Date(rawValue: Date().rawValue) ?? Date()
    
    @State var stationStatus: StationStatus?
    
    @State var species: Array<Species> = [Species]()
    @State var selection: Species?
    
    @State private var loading: Bool = false
    
    @State private var showSettings: Bool = false
    @State private var showSinceDate: Bool = false
    
    @State var page: Int = 1
    
    var body: some View {
        if stationStatus != nil {
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                if showSinceDate {
                    Text("data since: species \(stationStatus!.species) - detections \(stationStatus!.detections)")
                } else {
                    Text("\(samplePeriod.rawValue): species \(stationStatus!.species) - detections \(stationStatus!.detections)")
                }
                
                Button(action: {
                    if showSinceDate {
                        filterSpecies()
                    } else {
                        Task {
                            await loadData()
                        }
                    }
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                })
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            .font(.footnote)
            .padding(.bottom, 5)
        }
        List(selection: $selection) {
            ForEach(Array(species.enumerated()), id: \.1) { (index,species) in
                NavigationLink(destination: SpeciesDetailsView(species: species)) {
                    HStack {
                        if showSpeciesImage {
                            CachedAsyncImage(
                                url: species.thumbnailURL,
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 48, maxHeight: 48)
                                        .clipShape(Circle())
                                },
                                placeholder: {
                                    ProgressView()
                                }
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(species.color, lineWidth: 2, antialiased: true)
                            )
                        }
                        else {
                            Image(systemName: "bird")
                                .resizable()
                                .frame(width: 38, height: 48)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(species.commonName)
                            Text(species.scientificName)
                                .controlSize(.small)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("\(species.detections.total)")
                                .controlSize(.small)
                                .foregroundColor(.secondary)
                        }
                    }
                    .overlay(alignment: .leading) {
                        Text("#\((index+1)+((page-1)*limit))")
                            .foregroundColor(.gray)
                            .controlSize(.small)
                            .offset(x: -16, y: -23)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay{
            if species.isEmpty && !loading {
                ContentUnavailableView("No species", systemImage: "bird.circle", description: Text("Change sample period"))
            } else if species.isEmpty && loading {
                VStack {
                    Text("Querying server")
                    ProgressView()
                }
            }
        }
        .task(id: "\(samplePeriod) \(page) \(limit) \(sortSpeciesList)") {
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("export"))) { _ in
                    exportSpecies()
                }
        HStack {
            Spacer()
            if (stationStatus?.species ?? Int.max) > limit {
                if species.count == limit {
                    if page > 1 {
                        Button("Previous") {
                            page -= 1
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                    Button("Next") {
                        page += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else if page > 1 {
                    Button("Previous") {
                        page -= 1
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        Button(action: {
            showSettings.toggle()
            if !showSettings {
                Task {
                    await loadData()
                }
            }
        }, label: {
            Image(systemName: "gearshape")
            Text("Species list settings")
        })
        .buttonStyle(.borderless)
        if showSettings {
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
            Picker("Sort order", selection: $sortSpeciesOrder) {
                Text("descending")
                    .tag("desc")
                Text("ascending")
                    .tag("asc")
            }
            .frame(width: 200)
            HStack {
                Text("Limit")
                TextField("Limit", value: $limit, formatter: NumberFormatter(), prompt: Text("Limit"))
                    .frame(width: 30)
            }
        }
        
        Button(action: {
            showSinceDate.toggle()
            if !showSinceDate {
                Task {
                    await loadData()
                }
            }
        }, label: {
            Image(systemName: "calendar")
            Text("Show since date")
        })
            .buttonStyle(.borderless)
        if showSinceDate {
            VStack{
                HStack {
                    DatePicker("Since", selection: $sinceDate)
                        .labelsHidden()
                }
                if sinceDate != Date() {
                    HStack {
                        Button(action: {filterSpecies()}, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filter")
                        })
                        Button(action: {
                            Task {
                                await deactivateFilter()
                            }
                            }, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Deactivate")
                        })
                    }
                }
            }
        }
    }
    
    private func loadData() async {
        loading = true
        self.stationStatus = await BirdWeatherRestBridge().testStation(period: samplePeriod)
        if let species = await BirdWeatherRestBridge().speciesList(period: samplePeriod, limit: limit, page: page, sortBy: sortSpeciesList, order: sortSpeciesOrder) {
            self.species = species
        }
        loading = false
    }
    
    private func filterSpecies() {
        let from = sinceDate.ISO8601Format(.iso8601(timeZone: TimeZone.current, includingFractionalSeconds: true))
        Task {
            loading = true
            species.removeAll()
            page = 1
            self.stationStatus = await BirdWeatherRestBridge().testStation(period: samplePeriod, since: from)
            if let species = await BirdWeatherRestBridge().speciesList(period: samplePeriod, since: from, limit: limit, page: page, sortBy: sortSpeciesList, order: sortSpeciesOrder){
                self.species = species
            } else {
                self.species = Array()
            }
            loading = false
        }
    }
    
    private func deactivateFilter() async {
        showSinceDate.toggle()
        loading = true
        species.removeAll()
        loading = false
        page = 1
    }
    
    private func exportSpecies() {
        var csvString = "species common, species scientific, total detections"
        for aSpecies in species {
            csvString += "\n"
            csvString += "\(aSpecies.commonName),\(aSpecies.scientificName), \(aSpecies.detections.total)"
        }
        let sp = NSSavePanel()
        sp.allowedContentTypes = [UTType(filenameExtension: "csv", conformingTo: .delimitedText) ?? .delimitedText]
        if sp.runModal() == .OK, let url = sp.url {
            do {
                try csvString.write(to: url, atomically: true, encoding: .utf8)
            }
            catch let error {
                NSApp.presentError(error)
            }
        }
    }
}

#Preview {
    SpeciesListView(samplePeriod: .day)
}
