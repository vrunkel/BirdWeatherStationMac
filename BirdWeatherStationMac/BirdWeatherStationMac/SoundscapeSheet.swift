//
//  SoundscapeSheet.swift
//  BirdWeatherStation
//
//  Created by Volker Runkel on 03.04.24.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct SoundscapeSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var player: AVAudioPlayer?
    @State private var markerOffset = CGSize(width: 0, height: 0)
    @State private var delayMeteringTimer: AutoCancellingTimer?
    @State private var playDisabled: Bool = false
    @State var soundStart:Int?
    @State var soundEnd: Int?
        
    @AppStorage("SonaBright", store: .standard) var sonaBright : Double = 0.32
    @AppStorage("SonaContr", store: .standard) var sonaContr : Double = 1.7
    @AppStorage("SonaPower", store: .standard) var sonaPower : Double = 0.6
    
    @State var soundscapeURL: URL
    @State private var tempFlacFile: TemporaryFileURL?
    
    @State private var sonoImage: CGImage?
    @State private var filteredImage: CIImage?
    
    let colorControlsFilter: CIFilter = CIFilter(name: "CIColorControls")!
    let colorGamma = CIFilter(name: "CIGammaAdjust")!
    let colorMapFilter = CIFilter(name: "CIColorMap")!
    
    let flacDecoder = FlacToRawDecoder()
       
    
    var body: some View {
        VStack {
            if filteredImage != nil {
                VStack(alignment: .leading) {
                    Text("Adjust sonagram")
                    HStack {
                        Slider(value: $sonaBright, in: -1...1)
                        Slider(value: $sonaContr, in: 0.3...4)
                        Slider(value: $sonaPower, in: -5...5)
                    }
                    .controlSize(.small)
                    .onChange(of: "\(sonaContr) \(sonaBright) \(sonaPower)") {
                        self.createFilters(image: self.sonoImage!)
                    }
                }
                if filteredImage != nil {
                        ScrollView([.horizontal]) {
                            VStack(alignment:.leading) {
                                Image(self.convertCIImageToCGImage(inputImage: filteredImage!)!, scale: 1, orientation: .downMirrored, label: Text(""))
                                    .frame(width: CGFloat(sonoImage!.width), height: 256)
                                    .overlay(alignment: .bottomLeading) {
                                        if let start = soundStart, let end = soundEnd, let sonoImage = sonoImage {
                                            Rectangle()
                                                .fill(Color.red.opacity(0.3))
                                                .frame(width: (Double(end)-Double(start))/(flacDecoder.durationSeconds ?? 9) * Double(sonoImage.width), height:256)
                                                .offset(x:Double(start)/(flacDecoder.durationSeconds ?? 9) * Double(sonoImage.width))
                                        }
                                    }
                                
                                Divider()
                                    .id(1)
                                    .frame(width: 3, height:5)
                                    .offset(y:3)
                                    .overlay(.pink)
                                    .offset(markerOffset)
                                    .animation(.linear(duration: flacDecoder.durationSeconds ?? 9), value: markerOffset)
                            }
                        }
                        .frame(width: 500, height: 256)
                }
                HStack(spacing: 20) {
                    Button(action: {
                        let sp = NSSavePanel()
                        sp.allowedContentTypes = [UTType(filenameExtension: "flac", conformingTo: .audio) ?? .audio]
                        if sp.runModal() == .OK, let url = sp.url {
                            try? FileManager.default.copyItem(at: tempFlacFile!.contentURL, to: url)
                        }
                    }) {
                        Text("Save FLAC")
                    }
                    .disabled(playDisabled)
                    
                    Button("Play") {
                        withAnimation {
                            markerOffset = CGSize(width: sonoImage!.width, height: 0)
                        }
                        playSound()
                    }
                    .disabled(playDisabled)
                                        
                    Button(action: {
                        if let player = player {
                            if player.isPlaying {
                                player.stop()
                            }
                        }
                        dismiss()
                    }, label: { Text("Close")})
                }
            } else {
                ContentUnavailableView(
                    "No soundscape yet",
                    systemImage: "headphones",
                    description: Text("Loading it down ...")
                )
            }
        }
        .frame(width: 500, height: 320)
        .padding()
        .onAppear() {
            self.downloadSoundscape()
            //self.createFilters(image: sonoImage!)
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    
    func createFilters(image: CGImage) {
        
        self.colorControlsFilter.setDefaults()
        self.colorControlsFilter.name = "colorControls"
        self.colorGamma.setDefaults()
        self.colorGamma.name = "colorGamma"
        self.colorMapFilter.setDefaults()
        self.colorMapFilter.name = "colorMap"
        
        self.colorControlsFilter.setValue(sonaBright, forKey:"inputBrightness")
        self.colorControlsFilter.setValue(sonaContr, forKey:"inputContrast")
        
        self.colorGamma.setValue(sonaPower, forKey:"inputPower")
        
        let imageName = "SonaBright"
        let data = NSImage(named: imageName)!.tiffRepresentation
        
        let imageRep = NSBitmapImageRep(data: data!)
        let colormapImage = CIImage(bitmapImageRep: imageRep!)
        self.colorMapFilter.setValue(colormapImage, forKey: "inputGradientImage")
        
        self.colorControlsFilter.setValue(CIImage(cgImage: image), forKey: kCIInputImageKey)
        self.colorGamma.setValue(self.colorControlsFilter.outputImage, forKey: kCIInputImageKey)
        
        self.colorMapFilter.setValue(self.colorGamma.outputImage, forKey: kCIInputImageKey)
        self.filteredImage = self.colorMapFilter.outputImage
    }
    
    private func downloadSoundscape() {
         let task = URLSession.shared.dataTask(with: soundscapeURL) { data, response, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode) else {
                        print(response)
                        return
                    }
                    let temporaryFile = TemporaryFileURL(extension: "flac")
                temporaryFile.keepAlive()
                    if let mimeType = httpResponse.mimeType, mimeType == "audio/flac",
                        let data = data,
                       let _ = try? data.write(to: temporaryFile.contentURL) {
                        flacDecoder.decode(from: temporaryFile.contentURL)
                        if let cgImage = flacDecoder.sonagram() {
                            self.tempFlacFile = temporaryFile
                            self.sonoImage = cgImage//NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
                            self.createFilters(image: sonoImage!)
                        }
                    } else {
                        print(":(")
                    }
                }
                task.resume()
    }
    
    func playSound() {
    
        do {
            player = try AVAudioPlayer(contentsOf: tempFlacFile!.contentURL)
            player?.prepareToPlay()
            player?.play()
            playDisabled.toggle()
            self.delayMeteringTimer = AutoCancellingTimer(interval: 0.1, repeats: true) {
                let curTime = player!.currentTime
                if curTime == 0.0 {
                    player?.stop()
                    playDisabled.toggle()
                    self.delayMeteringTimer = nil
                }
            }
            
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}
