//
//  SpeciesLocalizer.swift
//  BirdWeatherStationMac
//
//  Created by Volker Runkel on 16.05.24.
//

import SwiftUI

class SpeciesLocalizer: ObservableObject {
    
    @AppStorage("LocalizationCSVBookmark", store: .standard) var csvURLBookmark: Data?
    
    static let shared = SpeciesLocalizer()
    @Published var translationDict: Dictionary<String,String>?
    
    private init() {
        updateTranslationDict()
    }
    
    func updateTranslationDict() {
        guard let data = csvURLBookmark else {
            return
        }
        var isStale = false
        guard let newURL = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return
        }
        var translateDict = Dictionary<String,String>()
        if newURL.startAccessingSecurityScopedResource() {
            if let speciesRaw = try? String(contentsOf: newURL) {
                
                var fieldSep = ";"
                if speciesRaw.countInstances(of: ",") > speciesRaw.countInstances(of: ";") {
                    fieldSep = ","
                } else if speciesRaw.countInstances(of: "\t") > speciesRaw.countInstances(of: ";") {
                    fieldSep = "\t"
                }
                
                for aLine in speciesRaw.components(separatedBy: .newlines) {
                    if aLine.count < 2 {
                        continue
                    }
                    
                    let lineFields = aLine.components(separatedBy: fieldSep)
                    if lineFields.count > 1 {
                        let germanName = lineFields[0]
                        let scienceName = lineFields[1]
                        if germanName.count > 1 && scienceName.count > 1 {
                            translateDict.updateValue(germanName, forKey: scienceName)
                        }
                    }
                }
            }
            if !translateDict.isEmpty {
                self.translationDict = translateDict
            } else {
                self.translationDict = nil
            }
        }
        newURL.stopAccessingSecurityScopedResource()
    }
    
    func translateSpecies(scientificName: String?) -> String? {
        if translationDict == nil || scientificName == nil {
            return nil
        }
        return translationDict![scientificName!]
    }
}
