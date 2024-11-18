//
//  BirdWeatherRestBridge.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 27.03.24.
//

import Foundation
import SwiftUI

/*
 
    Bilder-Caching (Thumbs und Co ändern sich vmtl. selten/nicht)
 
 */

enum Period: String, Equatable, CaseIterable {
    case day
    case week
    case month
    case all
    
    func toLocalizedString() -> String {
         let value: String

           switch self {
           case .day:
             value = String(localized: "day_period")
           case .week:
             value = String(localized: "week_period")
           case .month:
             value = String(localized: "month_period")
           case .all:
             value = String(localized: "all_period")
           }
        
           return value
      }
    
}

struct StationStatus {
    var success: Bool
    var detections: Int
    var species: Int
}

struct Species: Identifiable, Hashable, Equatable {
    
    static func == (lhs: Species, rhs: Species) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: Int
    var commonName: String
    var scientificName: String
    var color: Color
    var imageURL: URL?
    var thumbnailURL: URL?
    var detections: DetectionTypes
    var latestDetectionAt: Date?
    
    init?(json: [String: Any]) {
        let speciesLoc = SpeciesLocalizer.shared
        guard let id = json["id"] as? Int,
              let commonName = speciesLoc.translateSpecies(scientificName: json["scientificName"] as? String) ?? json["commonName"] as? String,
              let scientificName = json["scientificName"] as? String,
              let color = json["color"] as? String,
              let imageURL = json["imageUrl"] as? String,
              let thumbnailURL = json["thumbnailUrl"] as? String
        else {
                  return nil
              }
        
        let detections = json["detections"] as? Dictionary<String, Any>
        let latestDetectionAt = json["latestDetectionAt"] as? String ?? ""
        
        self.id  = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.color = Color(hex: color)
        self.imageURL = URL(string: imageURL)
        self.thumbnailURL = URL(string: thumbnailURL)
        if detections != nil {
            self.detections = DetectionTypes(total: detections!["total"] as? Int ?? 0, almostCertain: detections!["almostCertain"] as? Int ?? 0, veryLikely: detections!["veryLikely"] as? Int ?? 0, uncertain: detections!["uncertain"] as? Int ?? 0, unlikely: detections!["unlikely"] as? Int ?? 0)
        } else {
            self.detections = DetectionTypes(total: 0, almostCertain: 0, veryLikely: 0, uncertain: 0, unlikely: 0)
        }
        self.latestDetectionAt = latestDetectionAt.toDate(.isoDateTimeMilliSec) ?? Date()
    }
    
}

struct SpeciesExtendend: Identifiable, Hashable, Equatable {
    
    static func == (lhs: SpeciesExtendend, rhs: SpeciesExtendend) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: Int
    var commonName: String
    var scientificName: String
    var color: Color
    var imageURL: URL?
    var thumbnailURL: URL?
    var wikipediaUrl: URL?
    var wikipediaSummary: String
    var alpha: String
    var alpha6: String
    var ebirdCode: String
    var ebirdURL: URL?
    var imageCredit: String
    var imageCreditHtml: String
    var imageLicense: String
    var imageLicenseUrl: URL?
    
    
    init?(json: [String: Any]) {
        guard let id = json["id"] as? Int,
              let commonName = json["commonName"] as? String,
              let scientificName = json["scientificName"] as? String,
              let color = json["color"] as? String,
              let imageURL = json["imageUrl"] as? String,
              let thumbnailURL = json["thumbnailUrl"] as? String
        else {
                  return nil
              }
        
        
        let wikipediaUrl = json["wikipediaUrl"] as? String  ?? ""
        let wikipediaSummary = json["wikipediaSummary"] as? String ?? ""
        let ebirdCode = json["ebirdCode"] as? String ?? ""
        let ebirdURL = json["ebirdUrl"] as? String ?? ""
        let imageCredit = json["imageCredit"] as? String ?? ""
        let imageCreditHtml = json["imageCreditHtml"] as? String ?? ""
        let imageLicense = json["imageLicense"] as? String ?? ""
        let imageLicenseUrl = json["imageLicenseUrl"] as? String ?? ""
        
        self.id  = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.color = Color(hex: color)
        self.imageURL = URL(string: imageURL)
        self.thumbnailURL = URL(string: thumbnailURL)
        self.wikipediaUrl = URL(string: wikipediaUrl)
        self.wikipediaSummary = wikipediaSummary
        
        let alpha = (json["alpha"] as? String) ?? ""
        let alpha6 = json["alpha6"] as? String ?? ""
        self.alpha = alpha
        self.alpha6 = alpha6
        self.ebirdCode = ebirdCode
        self.ebirdURL = URL(string: ebirdURL)
        self.imageCredit = imageCredit
        self.imageCreditHtml = imageCreditHtml
        self.imageLicense = imageLicense
        self.imageLicenseUrl = URL(string: imageLicenseUrl)
    }
    
}

struct Detection: Identifiable, Hashable, Equatable {
    
    var id: Int
    var station_id: Int
    var timestamp: Date
    var species: Species?
    var lat: Double
    var lon: Double
    var confidence: Double
    var probability: Double
    var score: Double
    var certainity: String
    var algorithm: String
    var metadata: String?
    var soundscape: Soundscape?
    
    static func == (lhs: Detection, rhs: Detection) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init?(json: [String: Any]) {
        guard let id = json["id"] as? Int,
              let station_id = json["stationId"] as? Int,
              let timestamp = json["timestamp"] as? String,
              let species = json["species"] as?  Dictionary<String, Any>,
              let lat = json["lat"] as? Double,
              let lon = json["lon"] as? Double,
              let confidence = json["confidence"] as? Double,
              let probability = json["probability"] as? Double,
              let score = json["score"] as? Double,
              let certainity = json["certainty"] as? String,
              let algorithm = json["algorithm"] as? String,
              let soundscape = json["soundscape"] as? Dictionary<String, Any>
        else {
                  return nil
              }
        
        self.id  = id
        self.station_id = station_id
        self.lat = lat
        self.lon = lon
        self.confidence = confidence
        self.probability = probability
        self.score = score
        self.certainity = certainity
        self.algorithm = algorithm
        let metadata = json["metadata"] as? String ?? "---"
        self.metadata = metadata
        self.species = Species(json: species)
        self.soundscape = Soundscape(json: soundscape)
        self.timestamp = timestamp.toDate(.isoDateTimeMilliSec) ?? Date()
    }
}

struct Soundscape: Identifiable, Hashable, Equatable {
    var id: Int
    var start_time: Int?
    var end_time: Int?
    var stationId: Int?
    var duration: Int?
    var filesize: Int?
    var timestamp: Date?
    var mode: String
    var url: URL?
    
    static func == (lhs: Soundscape, rhs: Soundscape) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init?(json: [String: Any]) {
        guard let mode = json["mode"] as? String,
              let url = json["url"] as? String else {
            return nil
        }
        let id = json["id"] as? Int ?? Int.random(in: 0...Int.max)
        let stationId = json["stationId"] as? Int
        let start_time = json["startTime"] as? Int
        let end_time = json["endTime"] as? Int
        let filesize = json["filesize"] as? Int
        let duration = json["duration"] as? Int
        let timestamp = json["timestamp"] as? String
        self.id  = id
        self.stationId = stationId
        self.duration = duration
        self.filesize = filesize
        self.mode = mode
        self.start_time = start_time
        self.end_time = end_time
        self.timestamp = timestamp?.toDate(.isoDateTimeMilliSec) ?? Date()
        self.url = URL(string: url)
    }
}

struct DetectionTypes {
    var total: Int
    var almostCertain: Int
    var veryLikely: Int
    var uncertain: Int
    var unlikely: Int
}

class BirdWeatherRestBridge {
    
    @AppStorage("PUCToken", store: .standard) var pucToken : String = ""
    @AppStorage("Connected", store: .standard) var connected : Bool = false
    
    func testStation(period: Period = .week, since: String = "") async -> StationStatus? {
        
        var urlString = "https://app.birdweather.com/api/v1/stations/" + pucToken + "/stats?period=\(period.rawValue)"
        
        if !since.isEmpty {
            urlString += "&since=\(since)" + TimeZone.current.offsetFromGMT()
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                connected = false
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if (json["success"] as? Bool ?? false) {
                    self.connected = true
                    return StationStatus(success: true, detections: (json["detections"] as? Int) ?? 0 , species: (json["species"] as? Int) ?? 0)
                } else {
                    self.connected = false
                    return nil
                }
            }
            
        }
        catch {
            print(error)
        }
        return nil
    }
    
    func speciesList(period: Period = .week, since: String = "", limit: Int = 30, page: Int = 1, sortBy: String = "top", order: String = "desc") async -> Array<Species>? {
        
        var urlString = "https://app.birdweather.com/api/v1/stations/" + pucToken + "/species?period=\(period.rawValue)"
        
        if !since.isEmpty {
            urlString += "&since=\(since)" + TimeZone.current.offsetFromGMT()
        }
        
        urlString += "&limit=\(limit)&page=\(page)&sort=\(sortBy)&order=\(order)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                connected = false
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if (json["success"] as? Bool ?? false) , let species = json["species"] as? Array<[String : Any]> {
                    var speciesList = Array<Species>()
                    for aSpecies in species {
                        if let newSpecies = Species(json: aSpecies) {
                            speciesList.append(newSpecies)
                        }
                    }
                    return speciesList
                } else {
                    return nil
                }
            }
            
        }
        catch {
            print(error)
        }
        
        return nil
    }
    
    func speciesExtendedInfo(speciesID: Int) async -> SpeciesExtendend? {
        guard let url = URL(string: "https://app.birdweather.com/api/v1/species/\(speciesID)") else {
            return nil
        }
        
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if (json["success"] as? Bool ?? false) , let species = json["species"] as? [String : Any] {
                    if let speciesInfo = SpeciesExtendend(json: species) {
                        return speciesInfo
                    }
                }
            }
            
        }
        catch {
            print(error)
        }
        return nil
    }
    
    func detectionList(limit: Int = 10, cursor: Int = -1, from: String? = nil, to: String? = nil, species_id: Int?, order: String = "desc") async -> Array<Detection>? {
        var urlString = "https://app.birdweather.com/api/v1/stations/" + pucToken + "/detections?limit=\(limit)"
        if cursor != -1 {
            urlString += "&cursor=\(cursor)"
        }
        if from != nil {
            urlString += "&from=\(from!)"
        }
        if to != nil {
            urlString += "&to=\(to!)"
        }
        
        if species_id != nil {
            urlString += "&species_id=\(species_id!)"
        }
        
        urlString += "&order=\(order)"
        
        guard var url = URL(string: urlString) else {
            return nil
        }
        
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                connected = false
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if (json["success"] as? Bool ?? false) , let detections = json["detections"] as? Array<[String : Any]> {
                    var detectionList = Array<Detection>()
                    for aDetection in detections {
                        if let newDetection = Detection(json: aDetection) {
                            detectionList.append(newDetection)
                        }
                    }
                    return detectionList
                } else {
                    return nil
                }
            }
            
        }
        catch {
            print(error)
        }
        
        return nil
    }
    
}
