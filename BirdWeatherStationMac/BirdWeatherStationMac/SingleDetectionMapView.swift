//
//  SingleDetectionMapView.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 31.03.24.
//

import SwiftUI
import MapKit

struct DetectionsPin: Identifiable {
    var coordinate: CLLocationCoordinate2D
    var color: Color
    var label: String
    let id = UUID()
}

struct SingleDetectionMapView: View {
    
    
    @State var position: MapCameraPosition =  .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.009), distance: 0))
    
    @State var detectionPin: DetectionsPin
    
    var body: some View {
        Map(position: $position) {
            Annotation(coordinate: detectionPin.coordinate, content: {
                    Circle()
                    .foregroundStyle(detectionPin.color)
                        .frame(width: 20)
            }, label: {
                Text(detectionPin.label)
            })
        }
            .mapStyle(.hybrid())
    }
}
