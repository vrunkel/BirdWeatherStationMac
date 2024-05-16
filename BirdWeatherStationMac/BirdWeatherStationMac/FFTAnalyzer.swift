//
//  FFTAnalyzer.swift
//  bcAdmin4
//
//  Created by Volker Runkel on 28.11.16.
//  Copyright © 2016 ecoObs GmbH. All rights reserved.
//

import Foundation
import Accelerate
import Quartz
import QuartzCore
import CoreGraphics
import SwiftImage

public class FFTAnalyzer {
    
    var lastdBGain: Float = 0.0
    
    let conv_fftsetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(2048))), FFTRadix(kFFTRadix2))
    
    deinit {
        vDSP_destroy_fftsetup(conv_fftsetup)
    }
    
    class func calculateAnalysisWindowClass(numberOfSamples: Int, windowType:Int)->[Float] {
        
        var window = [Float](repeating:1.0, count:numberOfSamples) // also rectangle!
        let halfWindow = numberOfSamples / 2
        switch windowType {
        case 1: // Hanning
            //vDSP_hann_window(UnsafeMutablePointer(mutating: window), vDSP_Length(numberOfSamples), 0) // Hann
            vDSP_hann_window(&window, vDSP_Length(numberOfSamples), 0) // Hann
            /*for index in 0..<numberOfSamples {
             window[index] = Float(0.5 - 0.5*(cos(2*M_PI*Double(index)/Double(numberOfSamples-1)))) // Hanning window
             }*/
        case 2: vDSP_hamm_window(&window, vDSP_Length(numberOfSamples), 0) // Hamm
        case 3:
            for index in 0..<numberOfSamples {
                window[index] = 1 - (Float(index) / Float(halfWindow))
            }
        case 4: vDSP_blkman_window(&window, vDSP_Length(numberOfSamples), 0) // Blckman
        case 5: // Flattop
            for index in 0..<numberOfSamples {
                var value: Double = 1 - 1.933 * cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 1.286 * cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.388 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.032 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        case 6: // quick 7term harris hack
            for index in 0..<numberOfSamples {
                var value: Double = 0.27122036 - 0.4334461*cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.2180041*cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.0657853 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.010761867 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.000770012*cos(10 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.0000136*cos(12 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        default: window[0] = 1.0
        }
        return window
    }
    
    func calculateAnalysisWindow(numberOfSamples: Int, windowType:Int)->[Float] {
        
        var window = [Float](repeating:1.0, count:numberOfSamples) // also rectangle!
        let halfWindow = numberOfSamples / 2
        switch windowType {
        case 1: // Hanning
            //vDSP_hann_window(UnsafeMutablePointer(mutating: window), vDSP_Length(numberOfSamples), 0) // Hann
            vDSP_hann_window(&window, vDSP_Length(numberOfSamples), 0) // Hann
            /*for index in 0..<numberOfSamples {
             window[index] = Float(0.5 - 0.5*(cos(2*M_PI*Double(index)/Double(numberOfSamples-1)))) // Hanning window
             }*/
        case 2: vDSP_hamm_window(&window, vDSP_Length(numberOfSamples), 0) // Hamm
        case 3:
            for index in 0..<numberOfSamples {
                window[index] = 1 - (Float(index) / Float(halfWindow))
            }
        case 4: vDSP_blkman_window(&window, vDSP_Length(numberOfSamples), 0) // Blckman
        case 5: // Flattop
            for index in 0..<numberOfSamples {
                var value: Double = 1 - 1.933 * cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 1.286 * cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.388 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.032 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        case 6: // quick 7term harris hack
            for index in 0..<numberOfSamples {
                var value: Double = 0.27122036 - 0.4334461*cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.2180041*cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.0657853 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.010761867 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.000770012*cos(10 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.0000136*cos(12 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        default: window[0] = 1.0
        }
        let sum = window.reduce(.zero, +)
        let dBGain = 20.0 * log10(sum/Float(numberOfSamples))
        self.lastdBGain = dBGain
        return window
    }
    
    // To get rid of the `() -> () in` casting
    func withExtendedLifetime<T>(x: T, f: () -> ()) {
        //do {
            return /*try*/ Swift.withExtendedLifetime(x, f)
        //} catch _ {
        //    print("Error trying")
        //}
        
    }
    
    // In the spirit of withUnsafePointers
    func withExtendedLifetimes<A0, A1>(arg0: A0, _ arg1: A1, f: () -> ()) {
        return withExtendedLifetime(x: arg0) { self.withExtendedLifetime(x: arg1, f: f) }
    }
    
    internal func spectrumForValues(signal: [Float], fftsetup: FFTSetup) -> [Float] {
        // Find the largest power of two in our samples
        let log2N = vDSP_Length(log2(Double(signal.count)))
        let n = 1 << log2N
        let fftLength = n / 2
        
        // This is expensive; factor it out if you need to call this function a lot
        //let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        var fft = [Float](repeating:0.0, count:Int(n))
        
        // Generate a split complex vector from the real data
        var realp = [Float](repeating:0.0, count:Int(fftLength))
        var imagp = realp
        //var myfftsetup = fftsetup
        
        withExtendedLifetimes(arg0:realp, imagp) {
            var splitComplex = DSPSplitComplex(realp:&realp, imagp:&imagp)
            UnsafePointer(signal).withMemoryRebound(to: DSPComplex.self, capacity: 1) {
                vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(fftLength))
            }
            //vDSP_ctoz(UnsafePointer(signal), 2, &splitComplex, 1, fftLength)
            
            // Take the fft
            vDSP_fft_zrip(fftsetup, &splitComplex, 1, log2N, FFTDirection(kFFTDirection_Forward))
            
            // Normalize
            var normFactor: Float = 1.0 / Float(n*2)
            vDSP_vsmul(splitComplex.realp, 1, &normFactor, splitComplex.realp, 1, vDSP_Length(fftLength))
            vDSP_vsmul(splitComplex.imagp, 1, &normFactor, splitComplex.imagp, 1, vDSP_Length(fftLength))
            
            // Zero out Nyquist
            splitComplex.imagp[0] = 0.0
            
            // Convert complex FFT to magnitude
            var b: Float = 1
            vDSP_zvmags(&splitComplex, 1, &fft, 1, vDSP_Length(fftLength))
            
            /* test um mehr vektor zu machen */
            var kAdjust0DB : Float = 1.5849e-13
            /*vDSP_vsadd(UnsafePointer(fft), 1, &kAdjust0DB, UnsafeMutablePointer(mutating: fft), 1, vDSP_Length(fftLength));
            vDSP_vdbcon(UnsafePointer(fft), 1, &b, UnsafeMutablePointer(mutating: fft), 1, vDSP_Length(fftLength), 1);*/
            var _fft = fft
            vDSP_vsadd(&_fft, 1, &kAdjust0DB, &fft, 1, vDSP_Length(fftLength));
            vDSP_vdbcon(&_fft, 1, &b, &fft, 1, vDSP_Length(fftLength), 1);
            
            /* test ende */
            
            //vvsqrtf(UnsafeMutablePointer(fft), UnsafePointer(fft), [Int32(fftLength)])
            //vDSP_vdbcon(UnsafePointer(fft), vDSP_Stride(1), UnsafePointer(b), UnsafeMutablePointer(fft), vDSP_Stride(1), [Int32(fftLength)], 0)
            
        }
        
        // Cleanup
        //vDSP_destroy_fftsetup(fftsetup)
        return fft
    }
    
    public func sonagramImageMain(fromSamples: inout [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        
        let whitePixel = GrayPixel(g:255)
        var results = [GrayPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        // we need a loop now that will move data slowly into b and calc ffts...
        var localStartSample = startSample
        if localStartSample < 0 {
            localStartSample = 0
        }
        var frameIndex: Int = localStartSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        //let maxStep = Double(numberOfFrames) / 10.0
        // let scaleFactor = ScaleFactor
        var imageWidth = 0
        while (frameIndex + FFTSize - 1) < localStartSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            if self.lastdBGain != 0.0 {
                fft = fft.map{$0 - self.lastdBGain}
            }
            for index in 1..<halfSize {
                var floatValue = fft[index]
                if floatValue == -.infinity {
                    floatValue = 0
                }
                if floatValue == .infinity {
                    floatValue = 255
                }
                if !floatValue.isNaN {
                    var value: Int = -Int(floatValue)
                    if value > 255 { value = 255}
                    if value < 0 { value = 0}
                    results[curAddr+index*numberOfFrames].g = UInt8(abs(value))
                }
                else {
                    results[curAddr+index*numberOfFrames].g = UInt8(abs(0))
                }
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<GrayPixel>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: Int(numberOfFrames*MemoryLayout<GrayPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }
    
    public func sonagramImageForCoreML(fromSamples: inout [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0, overwriteSpreadFactor: Float = -1) -> CGImage? {
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        
        let whitePixel = GrayPixel(g:255)
        var results = [GrayPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        // we need a loop now that will move data slowly into b and calc ffts...
        var localStartSample = startSample
        if localStartSample < 0 {
            localStartSample = 0
        }
        var frameIndex: Int = localStartSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        //let maxStep = Double(numberOfFrames) / 10.0
        // let scaleFactor = ScaleFactor
        var imageWidth = 0
       
        var spreadFactor : Float = 1.0
        if overwriteSpreadFactor > -1 {
            spreadFactor = overwriteSpreadFactor
        }
    
        let dBGain = 0 //self.lastdBGain + (UserDefaultsHelper.getData(type: NSNumber.self, forKey: .MainSonadBGain) ?? (NSNumber(value: 0.0))).floatValue
       
        while (frameIndex + FFTSize - 1) < localStartSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            
            if abs(spreadFactor - 1.0) > 0.1 {
                fft = fft.map{$0 * spreadFactor}
            }
            
            if self.lastdBGain != 0.0 {
                fft = fft.map{$0 - self.lastdBGain - self.lastdBGain}
            }
            for index in 1..<halfSize {
                var floatValue = fft[index]
                if floatValue == -.infinity {
                    floatValue = 0
                }
                if floatValue == .infinity {
                    floatValue = 255
                }
                if !floatValue.isNaN {
                    var value: Int = -Int(floatValue)
                    if value < 0 { value = 0}
                    if value > 255 { value = 255}
                    results[curAddr+index*numberOfFrames].g = UInt8(abs(value))
                }
                else {
                    results[curAddr+index*numberOfFrames].g = UInt8(abs(0))
                }
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<GrayPixel>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: Int(numberOfFrames*MemoryLayout<GrayPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }
    
    /// Creates an RGBa image of the sonagram data
    /*
     if all pixel values are set to 255
     r value alone gives blues
     g value alone gives pinks
     b value alone gives reds
     
     */
    
    /*public func sonagramImageRGBA(fromSamples: inout [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        var image : Image<RGBA<UInt8>>? //(named: "SonaBright")!
        var colorType = 0
        
        if colorType > 1 {
            switch colorType {
            case 2: image = Image<RGBA<UInt8>>(named: "SonaGrey")!
            case 3: image = Image<RGBA<UInt8>>(named: "SonaRed")!
            case 4: image = Image<RGBA<UInt8>>(named: "SonaBright")!
            default:
                image = Image<RGBA<UInt8>>(named: "SonaBright")!
            }
        }
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        
        let whitePixel = RGBAPixel(r: 0, g: 0, b: 0, a: 255)
        var results = [RGBAPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        // we need a loop now that will move data slowly into b and calc ffts...
        var localStartSample = startSample
        if localStartSample < 0 {
            localStartSample = 0
        }
        var frameIndex: Int = localStartSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        //let maxStep = Double(numberOfFrames) / 10.0
        let spreadFactor : Float = (UserDefaultsHelper.getData(type: NSNumber.self, forKey: .MainSonaSpread) ?? (NSNumber(value: 1.0))).floatValue
        
        let useRed = (UserDefaultsHelper.getData(type: Bool.self, forKey: .MainSonaRedBool) ?? false)
        let useGreen = (UserDefaultsHelper.getData(type: Bool.self, forKey: .MainSonaGreenBool) ?? false)
        let useBlue = (UserDefaultsHelper.getData(type: Bool.self, forKey: .MainSonaBlueBool) ?? true)
        
        var imageWidth = 0
        let dBGain = self.lastdBGain + (UserDefaultsHelper.getData(type: NSNumber.self, forKey: .MainSonadBGain) ?? (NSNumber(value: 0.0))).floatValue
        var cutOffValue = 255
        if (NSApp.delegate as! AppDelegate).inAppPurchaseStatus == .pro {
            if UserDefaultsHelper.getData(type: Int.self, forKey: .MainSonadBCutoff) ?? 0 > 0 {
                switch UserDefaultsHelper.getData(type: Int.self, forKey: .MainSonadBCutoff)! {
                case 1:
                    cutOffValue = 132
                case 2:
                    cutOffValue = 160
                case 3:
                    cutOffValue = 190
                case 4:
                    cutOffValue = 215
                default:
                    cutOffValue = 255
                }
            }
        }
        while (frameIndex + FFTSize - 1) < localStartSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            if dBGain != 0.0 {
                fft = fft.map{$0 - dBGain - self.lastdBGain}
            }
            if abs(spreadFactor - 1.0) > 0.1 {
                fft = fft.map{$0 * spreadFactor}
            }
            for index in 1..<halfSize {
                var floatValue = fft[index]
                if floatValue == -.infinity {
                    floatValue = 0
                }
                if floatValue == .infinity {
                    floatValue = 255
                }
                if !floatValue.isNaN {
                    
                    
                    var value: Int = -Int(floatValue)
                    if value > cutOffValue { value = 255}
                    if value < 0 { value = 0}
                    
                    var redValue =  (useBlue || useGreen) ? UInt8(value) : 255
                    var greenValue = (useBlue || useRed) ? UInt8(value) : 255
                    var blueValue = (useRed || useGreen) ? UInt8(value) : 255
                    
                    if colorType > 1 {
                        let pixel: RGBA<UInt8> = image![abs(value), 0]
                        redValue =  UInt8(pixel.red)
                        greenValue = UInt8(pixel.green)
                        blueValue = UInt8(pixel.blue)
                    }
                    
                    //results[curAddr+index*numberOfFrames].setBlue(value: UInt8(abs(value)))
                    //results[curAddr+index*numberOfFrames].setRGB(red: UInt8(abs(redValue)), green: UInt8(abs(greenValue)), blue: UInt8(abs(blueValue)))
                    results[curAddr+index*numberOfFrames].setRGB(red: redValue, green: greenValue, blue: blueValue)
                    
                }
                else {
                    results[curAddr+index*numberOfFrames].setRGB(red: UInt8(abs(0)), green: UInt8(abs(0)), blue: UInt8(abs(0)))
                }
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<RGBAPixel>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(numberOfFrames*MemoryLayout<RGBAPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }
    
    public func sonagramGrayImage(fromSamples: [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        let whitePixel = GrayPixel(g:255)
        var results = [GrayPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        // we need a loop now that will move data slowly into b and calc ffts...
        var frameIndex: Int = startSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        //let maxStep = Double(numberOfFrames) / 10.0
        // let scaleFactor = ScaleFactor
        var imageWidth = 0
        while (frameIndex + FFTSize - 1) < startSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            if self.lastdBGain != 0.0 {
                fft = fft.map{$0 - self.lastdBGain}
            }
            for index in 1..<halfSize {
                var value: Int = -Int(fft[index])
                if value > 255 { value = 255}
                results[curAddr+index*numberOfFrames].g = UInt8(abs(value))
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<GrayPixel>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: Int(imageWidth*MemoryLayout<GrayPixel>.size/*MemoryLayout<GrayPixel>.size*/), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }*/
    
    public func sonagramColorImage(fromSamples: [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        let whitePixel = PixelData()
        var results = [PixelData](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        // we need a loop now that will move data slowly into b and calc ffts...
        var frameIndex: Int = startSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        //let maxStep = Double(numberOfFrames) / 10.0
        // let scaleFactor = ScaleFactor
        var imageWidth = 0
        while (frameIndex + FFTSize - 1) < startSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            if self.lastdBGain != 0.0 {
                fft = fft.map{$0 - self.lastdBGain}
            }
            for index in 1..<halfSize {
                var value: Int = -Int(fft[index])
                if value > 255 { value = 255}
                results[curAddr+index*numberOfFrames].r = UInt8(abs(value))
                results[curAddr+index*numberOfFrames].g = UInt8(abs(value))
                results[curAddr+index*numberOfFrames].b = UInt8((abs(value)/2))
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 8*4, bytesPerRow: Int(numberOfFrames*MemoryLayout<PixelData>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }
    
}
