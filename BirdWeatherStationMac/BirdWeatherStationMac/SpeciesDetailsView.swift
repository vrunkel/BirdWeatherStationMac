//
//  SpeciesDetailsView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 29.03.24.
//

import SwiftUI
import CachedAsyncImage

struct SpeciesDetailsView: View {
    
    @State var species: Species
    @State var speciesExtended: SpeciesExtendend?
    @State var lastDetections: Array<Detection>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CachedAsyncImage(
                    url: species.imageURL,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 128, maxHeight: 128)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .overlay(
                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                        .strokeBorder(species.color, lineWidth: 2, antialiased: true)
                )
                VStack(alignment: .leading) {
                    Text(species.commonName)
                        .font(.headline)
                        .bold()
                    Text(species.scientificName)
                        .font(.subheadline)
                        .italic()
                    Text("id \(species.id)")
                        .font(.footnote)
                    Spacer()
                        .frame(height: 20)
                    Text("Total detections \(species.detections.total)")
                        .font(.body)
                    
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Image: " + (speciesExtended?.imageCredit ?? "---"))
                    Text("License: " + (speciesExtended?.imageLicense ?? "---"))
                    Text((speciesExtended?.imageCreditHtml ?? "---"))
                }
                .frame(maxWidth:250)
            }
            Divider()
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            
            Link("Open Wikipedia", destination: speciesExtended?.wikipediaUrl ?? URL(string: "https://wikipedia.com")!)
            Text("Wikipedia: " + (speciesExtended?.wikipediaSummary ?? "---"))
                .lineSpacing(3)
            Link("Open eBird", destination: speciesExtended?.ebirdURL ?? URL(string: "https://ebird.org")!)
            Divider()
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            
                .font(.footnote)
            if lastDetections != nil {
                Text("Last 10 detections")
                Table(lastDetections!) {
                    TableColumn("Timestamp") { value in
                        Text("\(value.timestamp, format: .dateTime)")
                    }
                    TableColumn("Coordinates") { value in
                        Text("\(value.lat, format: .number.precision(.fractionLength(3)))°, \(value.lon, format:  .number.precision(.fractionLength(3)))°")
                    }
                    TableColumn("Score") { value in
                        Text("\(value.score, format: .number.precision(.fractionLength(2)))")
                    }
                    TableColumn("Probability") { value in
                        Text("\(value.probability, format: .percent.precision(.fractionLength(0)))")
                    }
                    TableColumn("Confidence") { value in
                        Text("\(value.confidence, format: .percent.precision(.fractionLength(0)))")
                    }
                    TableColumn("") { value in
                        NavigationLink("Show", destination: DetectionDetailView(detection: value))
                    }
                }
                .font(.footnote)
            }
            Spacer()
        }
        .textSelection(.enabled)
        .padding()
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background(Color.white)
        .task(id: species) {
            if let speciesExt = await BirdWeatherRestBridge().speciesExtendedInfo(speciesID: species.id) {
                self.speciesExtended = speciesExt
            }
            if let detections = await BirdWeatherRestBridge().detectionList(species_id: species.id) {
                self.lastDetections = detections
            }
        }
        /*.onAppear() {
            Task {
                print("There")
                if let speciesExt = await BirdWeatherRestBridge().speciesExtendedInfo(speciesID: species.id) {
                    self.speciesExtended = speciesExt
                }
            }
        }*/
    }
}

#Preview {
    let speciesjson: Dictionary<String,Any> = ["id": 305,
                       "commonName": "Chestnut-backed Chickadee",
                       "scientificName": "Poecile rufescens",
                       "color": "#f8319e",
                       "imageUrl": "https://birdweather.s3.amazonaws.com/species/305/Chestnut-backedChickadee-standard-0ccc6a9522620eb8d8048026bf8d47a4.jpg",
                       "thumbnailUrl": "https://birdweather.s3.amazonaws.com/species/305/Chestnut-backedChickadee-thumbnail-1e6f597546372f2097b4dde0383a95e8.jpg",
                       "detections": [
                         "total": 1112,
                         "almostCertain": 1112,
                         "veryLikely": 0,
                         "uncertain": 0,
                         "unlikely": 0
                       ],
                       "latestDetectionAt": "2022-11-17T16:48:10.986-08:00"
                     ]
    let species = Species(json: speciesjson)!
    return SpeciesDetailsView(species: species).frame(width: 500, height: 500)
}
