//
//  Extensions.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 28.03.24.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}

extension String {
    /// stringToFind must be at least 1 character.
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}

extension String {
    // copied from https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
    
    public enum DateFormatType {
        
        /// The ISO8601 formatted year "yyyy" i.e. 1997
        case isoYear
        
        /// The ISO8601 formatted year and month "yyyy-MM" i.e. 1997-07
        case isoYearMonth
        
        /// The ISO8601 formatted date "yyyy-MM-dd" i.e. 1997-07-16
        case isoDate
        
        /// The ISO8601 formatted date and time "yyyy-MM-dd'T'HH:mmZ" i.e. 1997-07-16T19:20+01:00
        case isoDateTime
        
        /// The ISO8601 formatted date, time and sec "yyyy-MM-dd'T'HH:mm:ssZ" i.e. 1997-07-16T19:20:30+01:00
        case isoDateTimeSec
        
        /// The ISO8601 formatted date, time and millisec "yyyy-MM-dd'T'HH:mm:ss.SSSZ" i.e. 1997-07-16T19:20:30.45+01:00
        case isoDateTimeMilliSec
        
        /// The dotNet formatted date "/Date(%d%d)/" i.e. "/Date(1268123281843)/"
        case dotNet
        
        /// The RSS formatted date "EEE, d MMM yyyy HH:mm:ss ZZZ" i.e. "Fri, 09 Sep 2011 15:26:08 +0200"
        case rss
        
        /// The Alternative RSS formatted date "d MMM yyyy HH:mm:ss ZZZ" i.e. "09 Sep 2011 15:26:08 +0200"
        case altRSS
        
        /// The http header formatted date "EEE, dd MM yyyy HH:mm:ss ZZZ" i.e. "Tue, 15 Nov 1994 12:45:26 GMT"
        case httpHeader
        
        /// A generic standard format date i.e. "EEE MMM dd HH:mm:ss Z yyyy"
        case standard
        
        /// A custom date format string
        case custom(String)
        
        /// The local formatted date and time "yyyy-MM-dd HH:mm:ss" i.e. 1997-07-16 19:20:00
        case localDateTimeSec
        
        /// The local formatted date  "yyyy-MM-dd" i.e. 1997-07-16
        case localDate
        
        /// The local formatted  time "hh:mm a" i.e. 07:20 am
        case localTimeWithNoon
        
        /// The local formatted date and time "yyyyMMddHHmmss" i.e. 19970716192000
        case localPhotoSave
        
        case birthDateFormatOne
        
        case birthDateFormatTwo
        
        ///
        case messageRTetriveFormat
        
        ///
        case emailTimePreview
        
        var stringFormat:String {
            switch self {
                //handle iso Time
            case .birthDateFormatOne: return "dd/MM/YYYY"
            case .birthDateFormatTwo: return "dd-MM-YYYY"
            case .isoYear: return "yyyy"
            case .isoYearMonth: return "yyyy-MM"
            case .isoDate: return "yyyy-MM-dd"
            case .isoDateTime: return "yyyy-MM-dd'T'HH:mmZ"
            case .isoDateTimeSec: return "yyyy-MM-dd'T'HH:mm:ssZ"
            case .isoDateTimeMilliSec: return "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            case .dotNet: return "/Date(%d%f)/"
            case .rss: return "EEE, d MMM yyyy HH:mm:ss ZZZ"
            case .altRSS: return "d MMM yyyy HH:mm:ss ZZZ"
            case .httpHeader: return "EEE, dd MM yyyy HH:mm:ss ZZZ"
            case .standard: return "EEE MMM dd HH:mm:ss Z yyyy"
            case .custom(let customFormat): return customFormat
                
                //handle local Time
            case .localDateTimeSec: return "yyyy-MM-dd HH:mm:ss"
            case .localTimeWithNoon: return "hh:mm a"
            case .localDate: return "yyyy-MM-dd"
            case .localPhotoSave: return "yyyyMMddHHmmss"
            case .messageRTetriveFormat: return "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            case .emailTimePreview: return "dd MMM yyyy, h:mm a"
            }
        }
    }
    
    func toDate(_ format: DateFormatType = .isoDate) -> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.stringFormat
        let date = dateFormatter.date(from: self)
        return date
    }
}

public extension Binding where Value: Equatable {
    init(_ source: Binding<Value>, deselectTo value: Value) {
        self.init(get: { source.wrappedValue },
                  set: { source.wrappedValue = $0 == source.wrappedValue ? value : $0 }
        )
    }
}

extension Binding {
  func withDefault<T>(_ defaultValue: T) -> Binding<T> where Value == Optional<T> {
    return Binding<T>(get: {
      self.wrappedValue ?? defaultValue
    }, set: { newValue in
      self.wrappedValue = newValue
    })
  }
}

extension Date: RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

public protocol ManagedURL {
    var contentURL: URL { get }
    func keepAlive()
}

public extension ManagedURL {
    public func keepAlive() { }
}

extension URL: ManagedURL {
    public var contentURL: URL { return self }
}

public final class TemporaryFileURL: ManagedURL {
    
    public let contentURL: URL
    
    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
    
    deinit {
        DispatchQueue.global(qos: .utility).async { [contentURL = self.contentURL] in
            try? FileManager.default.removeItem(at: contentURL)
        }
    }
}

public struct PixelData {
//        var a:UInt8 = 255
        var r:UInt8 = 0
        var g:UInt8 = 0
        var b:UInt8 = 0
        var a:UInt8 = 255
}

public struct GrayPixel {
    var g:UInt8 = 0
}

public struct RGBAPixel {
    var r:UInt8 = 0
    var g:UInt8 = 0
    var b:UInt8 = 0
    var a:UInt8 = 0
    
    mutating func setRedInverted(value: UInt8) {
        self.r = value
        self.g = 255
        self.b = 255
    }
    
    mutating func setGreenInverted(value: UInt8) {
        self.r = 255
        self.g = value
        self.b = 255
    }
    
    mutating func setBlueInverted(value: UInt8) {
        self.r = 0
        self.g = 0
        self.b = value
    }
    
    mutating func setRed(value: UInt8) {
        self.r = 255
        self.g = value
        self.b = value
    }
    
    mutating func setGreen(value: UInt8) {
        self.r = value
        self.g = 255
        self.b = value
    }
    
    mutating func setBlue(value: UInt8) {
        self.r = value
        self.g = value
        self.b = 255
    }
    
    mutating func setRGB(red: UInt8, green: UInt8, blue: UInt8) {
        self.r = red
        self.g = green
        self.b = blue
    }
}

struct FFTSettings {
    var fftSize: Int
    var overlap: Float
    var window: WindowFunctions
}

enum WindowFunctions : Int {
    case rectangle
    case hanning
    case hamming
    case bartlet
    case blackman
    case flattop
    case seventermharris
}

final class AutoCancellingTimer {
    private var timer: AutoCancellingTimerInstance?
    
    init(interval: TimeInterval, repeats: Bool = false, callback: @escaping ()->()) {
        timer = AutoCancellingTimerInstance(interval: interval, repeats: repeats, callback: callback)
    }
    
    deinit {
        timer?.cancel()
    }
    
    func cancel() {
        timer?.cancel()
    }
}

final class AutoCancellingTimerInstance: NSObject {
    private let repeats: Bool
    private var timer: Timer?
    private var callback: ()->()
    
    deinit {
        Swift.print("Deinit " + self.className)
    }
    
    init(interval: TimeInterval, repeats: Bool = false, callback: @escaping ()->()) {
        self.repeats = repeats
        self.callback = callback
        
        super.init()
        
        timer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                     selector: #selector(AutoCancellingTimerInstance.timerFired(_:)), userInfo: nil, repeats: repeats)
    }
    
    func cancel() {
        timer?.invalidate()
    }
    
    @objc func timerFired(_ timer: Timer) {
        self.callback()
        if !repeats { cancel() }
    }
}

extension TimeZone {

    func offsetFromGMT() -> String
    {
        let localTimeZoneFormatter = DateFormatter()
        localTimeZoneFormatter.timeZone = self
        localTimeZoneFormatter.dateFormat = "Z"
        return localTimeZoneFormatter.string(from: Date())
    }

    func offsetInHours() -> String
    {
    
        let hours = secondsFromGMT()/3600
        let minutes = abs(secondsFromGMT()/60) % 60
        let tz_hr = String(format: "%+.2d:%.2d", hours, minutes) // "+hh:mm"
        return tz_hr
    }
}

/*extension StringProtocol {
    func htmlToAttributedString() throws -> AttributedString {
        try .init(
            .init(
                data: .init(utf8),
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        )
    }
}

extension Text {
    init(html: String, alert: String? = nil) {
        do {
            try self.init(html.htmlToAttributedString())
        } catch {
            self.init(alert ?? error.localizedDescription)
        }
    }
}
*/
