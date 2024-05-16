//
//  DetectionDetailView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 31.03.24.
//

import SwiftUI
import MapKit
import CachedAsyncImage

struct DetectionDetailView: View {
    
    @State var detection: Detection
    @State var sonoImage: CGImage?
    @State var tempFlacFile: TemporaryFileURL?
    
    @State var showSoundscape: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                if detection.species != nil {
                    CachedAsyncImage(
                        url: detection.species!.imageURL,
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
                            .strokeBorder(detection.species!.color, lineWidth: 2, antialiased: true)
                    )
                    VStack(alignment: .leading) {
                        Text(detection.species!.commonName)
                            .font(.headline)
                            .bold()
                        Text(detection.species!.scientificName)
                            .font(.subheadline)
                            .italic()
                        Text("id \(detection.species!.id)")
                            .font(.footnote)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        if detection.soundscape?.url != nil {
                            Button(action: {
                                self.showSoundscape.toggle()
                            }, label: {
                                Text("Show soundscape")
                            })
                            Text("\(detection.soundscape?.start_time ?? 0) - \(detection.soundscape?.end_time ?? 0)")
                                .font(.footnote)
                        } else {
                            Text("No soundscape url")
                        }
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("filterDetectionsBySpecies"), object: detection.species?.id)
                        }, label: {
                            Image(systemName: "bird")
                            Text("Filter by species")
                        })
                        
                    }
                    .frame(width: 180)
                }
            }
            SingleDetectionMapView(position: .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: detection.lat, longitude: detection.lon), distance: 500)),detectionPin: DetectionsPin(coordinate: CLLocationCoordinate2D(latitude: detection.lat, longitude: detection.lon), color: detection.species?.color ?? .red, label: detection.species?.commonName ?? "---"))
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showSoundscape) { print("dismissed") } content: {
            if detection.soundscape?.url != nil {
                SoundscapeSheet(soundStart: detection.soundscape?.start_time, soundEnd: detection.soundscape?.end_time, soundscapeURL: detection.soundscape!.url!)
            }
        }
    }
    
}

#Preview {
    
    let detectionjson: Dictionary<String, Any> =
    [
        "id": 57299468,
        "station_id": 349,
        "timestamp": "2022-11-21T19:01:46.000-05:00",
        "lat": 39.3634,
        "lon": -84.2269,
        "confidence": 0.7595082,
        "probability": 0.215,
        "score": 7.30435925453706,
        "certainty": "almost_certain",
        "algorithm": "alpha",
        "metadata": ""
        ]
    let detection = Detection(json: detectionjson)!
    return DetectionDetailView(detection: detection)
}
