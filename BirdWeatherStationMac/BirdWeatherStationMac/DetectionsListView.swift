//
//  DetectionsListView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 28.03.24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DetectionsListView: View {
    
    @AppStorage("DetectionsResultsLimit", store: .standard) var limit: Int = 10
    @AppStorage("DetectionsFromDate", store: .standard) var fromDate: Date = Date(rawValue: Date().rawValue) ?? Date()
    @AppStorage("DetectionsToDate", store: .standard)  var toDate: Date = Date(rawValue: Date().rawValue) ?? Date()
    @AppStorage("SortDetectionListOrder", store: .standard) var sortOrder : String = "desc"
        
    @State var detections: Array<Detection> = [Detection]()
    @State var selection: Detection?
    
    @State private var loading: Bool = false
    
    @State var cursor: Int = -1
    @State var firstCursor: Int?
    @State var lastCursor: Int?
    
    @State private var showSettings: Bool = false
    @State private var showDateRange: Bool = false
    @State private var showSpeciesLimit: Bool = false
    @State private var filterSpeciesId: String = ""
    @State private var showMapSheet: Bool = false
    
    var body: some View {
        if !detections.isEmpty {
            HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                Text("\(detections.count) Detections")
                Button(action: {
                    Task {
                        await loadData()
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
            ForEach(detections, id: \.self) { detection in
                NavigationLink(destination: DetectionDetailView(detection: detection)) {
                VStack(alignment: .leading) {
                        Text("\(detection.timestamp, format: .dateTime)")
                        HStack() {
                            Text(detection.species?.commonName ?? "---")
                            Text("\(detection.lat, format: .number.precision(.fractionLength(3)))°, \(detection.lon, format:  .number.precision(.fractionLength(3)))°")
                        }
                        .font(.footnote)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay{
            if detections.isEmpty && !loading {
                ContentUnavailableView("No detections", systemImage: "bird.circle", description: Text("Change sample period"))
            } else if detections.isEmpty && loading {
                VStack {
                    Text("Querying server")
                    ProgressView()
                }
            }
        }
        .task(id: "\(limit) \(cursor)") {
            if showSpeciesLimit {
                loading = true
                if let detections = await BirdWeatherRestBridge().detectionList(limit: limit, cursor: ( cursor > 0 ? cursor: -1), species_id: Int(filterSpeciesId), order: sortOrder) {
                    self.detections.append(contentsOf: detections)
                    if lastCursor != nil {
                        self.firstCursor = detections.first?.id
                    }
                    self.lastCursor = detections.last?.id
                }
                loading = false
                return
            }
            loading = true
            if let detections = await BirdWeatherRestBridge().detectionList(limit: limit, cursor: ( cursor > 0 ? cursor: -1) ,species_id: nil, order: sortOrder) {
                self.detections.append(contentsOf: detections)
                if lastCursor != nil {
                    self.firstCursor = self.detections.first?.id
                }
                self.lastCursor = detections.last?.id
            }
            loading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("export"))) { _ in
                    exportDetections()
                }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("filterDetectionsBySpecies"))) { notif in
            if let id = notif.object {
                self.showSpeciesLimit = true
                self.filterSpeciesId = "\(id)"
                self.filterSpecies()
            }
        }
        HStack {
            // sort order decides +/-
            // how to get cursor right when moving back ?
            if firstCursor != nil {
                Button("Reset") {
                    showDateRange = false
                    showSpeciesLimit = false
                    filterSpeciesId = ""
                    detections.removeAll()
                    lastCursor = nil
                    firstCursor = nil
                    cursor = -1
                }
                .buttonStyle(.borderedProminent)
            }
            if lastCursor != nil {
                Spacer()
                Button("Load more") {
                    cursor = self.lastCursor ?? cursor
                }
                .buttonStyle(.borderedProminent)
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
            Text("Detection list settings")
        })
        .buttonStyle(.borderless)
        if showSettings {
            Picker("Sort order", selection: $sortOrder) {
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
        
        Button(action: {showDateRange.toggle()}, label: {
            Image(systemName: "calendar")
            Text("Filter by date range")
        })
            .buttonStyle(.borderless)
        if showDateRange {
            VStack{
                HStack {
                    DatePicker("From", selection: $fromDate)
                        .labelsHidden()
                    DatePicker("To", selection: $toDate)
                        .labelsHidden()
                }
                if fromDate != toDate {
                    HStack {
                        Button(action: {filterDetections()}, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filter")
                        })
                        Button(action: {
                            showDateRange.toggle()
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
        
        Button(action: {
            showSpeciesLimit.toggle()
            if !showSpeciesLimit {
                filterSpeciesId = ""
                Task {
                    await deactivateFilter()
                }
            }
        }, label: {
            Image(systemName: "bird")
            Text("Filter by species")
        })
            .buttonStyle(.borderless)
        if showSpeciesLimit {
            VStack{
                HStack {
                    TextField("species id", text: $filterSpeciesId)
                }
                if !filterSpeciesId.isEmpty {
                    Button(action: {filterSpecies()}, label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                    })
                }
            }
        }
        
        Button(action: {showMapSheet.toggle()}, label: {
            Image(systemName: "map.fill")
            Text("Show detections map")
        })
        .buttonStyle(.borderless)
        .sheet(isPresented: $showMapSheet) {
            AllDetectionsMapSheet(detections: $detections)
                .frame(width:900, height:600)
        }
        Button(action: {buildSpeciesList()}, label: {
            Image(systemName: "square.and.arrow.up.circle.fill")
            Text("Export species list")
        })
        .buttonStyle(.borderless)
    }
    
    private func filterDetections() {
        let from = fromDate.ISO8601Format(.iso8601(timeZone: TimeZone.current, includingFractionalSeconds: true))
        let to = toDate.ISO8601Format(.iso8601(timeZone: TimeZone.current, includingFractionalSeconds: true))
        Task {
            loading = true
            detections.removeAll()
            if let detections = await BirdWeatherRestBridge().detectionList(limit: limit, from: from, to: to, species_id: nil, order: sortOrder) {
                self.detections = detections
                if lastCursor != nil {
                    self.firstCursor = detections.first?.id
                }
                self.lastCursor = detections.last?.id
            } else {
                self.detections = Array()
            }
            loading = false
        }
    }
    
    private func deactivateFilter() async {
        firstCursor = nil
        lastCursor = nil
        cursor = -1
        
        Task {
            await loadData()
        }
        
    }
    
    private func loadData() async {
        loading = true
        detections.removeAll()
        if let detections = await BirdWeatherRestBridge().detectionList(limit: limit, cursor: ( cursor > 0 ? cursor: -1) ,species_id: nil, order: sortOrder) {
            self.detections = detections
            if lastCursor != nil {
                self.firstCursor = detections.first?.id
            }
            self.lastCursor = detections.last?.id
        }
        loading = false
    }
    
    private func filterSpecies() {
        Task {
            loading = true
            detections.removeAll()
            if let detections = await BirdWeatherRestBridge().detectionList(limit: limit, species_id: Int(filterSpeciesId), order: sortOrder) {
                self.detections = detections
                if lastCursor != nil {
                    self.firstCursor = detections.first?.id
                }
                self.lastCursor = detections.last?.id
            } else {
                self.detections = Array()
            }
            loading = false
        }
    }
    
    private func exportDetections() {
        var csvString = "id, station, species common name, species scientific name, latitude, longitude, confidence, probabilty, score, certainty, algorithm"
        for aDetection in detections {
            csvString += "\n"
            csvString += "\(aDetection.id),\(aDetection.station_id),\(aDetection.species?.commonName ?? "---"),\(aDetection.species?.scientificName ?? "---"),\(aDetection.lon),\(aDetection.lat),\(aDetection.confidence),\(aDetection.probability),\(aDetection.score),\(aDetection.certainity),\(aDetection.algorithm)"
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
    
    private func buildSpeciesList() {
        let species = detections.compactMap { detection in
            (detection.species)
        }
        var csvString = "species common name, species scientific name"
        for aSpecies in Set(species).sorted(by: { $0.commonName < $1.commonName }) {
            csvString += "\n"
            csvString += "\(aSpecies.commonName),\(aSpecies.scientificName)"
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
    DetectionsListView()
}
