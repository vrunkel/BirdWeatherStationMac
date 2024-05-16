//
//  AllDetectionsMapSheet.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 05.04.24.
//

import SwiftUI
import MapKit

struct AllDetectionsMapSheet: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var detections: Array<Detection>
    
    @State private var detectionPins: Array<DetectionsPin>?
    
    @State private var position: MapCameraPosition =  .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.009), distance: 0))
       
    var body: some View {
        Map(position: $position) {
            if let detectionPins = detectionPins {
                ForEach(detectionPins) { aPin in
                    Annotation(coordinate: aPin.coordinate, content: {
                        Circle()
                            .foregroundStyle(aPin.color)
                            .frame(width: 20)
                    }, label: {
                        Text(aPin.label)
                    })
                }
            }
        }
        .mapStyle(.hybrid())
        .mapControls() {
            MapScaleView()
            MapZoomStepper()
        }
        .onAppear() {
            if detections.count > 0 {
                detectionPins = Array()
                for detection in detections {
                    detectionPins?.append(DetectionsPin(coordinate: CLLocationCoordinate2D(latitude: detection.lat, longitude: detection.lon), color: detection.species?.color ?? .red, label: detection.species?.commonName ?? "---"))
                }
                
                let minLat = detectionPins!.min { $0.coordinate.latitude < $1.coordinate.latitude }!.coordinate.latitude
                let maxLat = detectionPins!.min { $0.coordinate.latitude > $1.coordinate.latitude }!.coordinate.latitude
                let minLon = detectionPins!.min { $0.coordinate.longitude < $1.coordinate.longitude }!.coordinate.longitude
                let maxLon = detectionPins!.min { $0.coordinate.longitude > $1.coordinate.longitude }!.coordinate.longitude
                
                let middleLat = maxLat - minLat
                let middleLon = maxLon - minLon
                
                let distance = CLLocation(latitude: minLat, longitude: minLon).distance(from: CLLocation(latitude: maxLat, longitude: maxLon))
                
                position = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: minLat + middleLat * 0.5, longitude: minLon + middleLon * 0.5), distance: distance*3))
            }
        }
    }
}
