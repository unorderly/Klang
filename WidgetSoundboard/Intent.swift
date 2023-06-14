//
//  Intent.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
//

import AppIntents
import AVFoundation
import AudioToolbox
import WidgetKit
import MediaPlayer
import SwiftUI



struct SoundEntity: AppEntity, Identifiable, Hashable {

    static var defaultQuery: SoundQuery = SoundQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Sound")
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(self.symbol) \(self.title)")
    }
    
    var id: UUID
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "Symbol")
    var symbol: String
//    
//    @Property(title: "Color")
//    var color: Color
    
    @Property(title: "Sound")
    var file: IntentFile
    
    init(id: UUID, title: String, symbol: String, color: Color, url: URL) {
        self.id = id
        self.title = title
        self.symbol = symbol
//        self.color = color
        self.file = IntentFile(fileURL: url)
    }
    
    init(sound: Sound) {
        self.init(id: sound.id, title: sound.title, symbol: sound.symbol, color: sound.color, url: sound.url)
    }
    
    static func == (lhs: SoundEntity, rhs: SoundEntity) -> Bool {
        lhs.id == rhs.id
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}



struct SoundIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "Play Sound"
    
    static var description = IntentDescription("Plays a sound")
    
    @Parameter(title: "Sound")
    var sound: SoundEntity
    
    init(sound: SoundEntity) {
        self.sound = sound
    }
    
    init() {
//        sound = "horse"
    }
    
    func perform() async throws -> some IntentResult {
        //        await MPVolumeView.setVolume(1)
        print("Start playing \(sound.title)")
        
        let player = try AudioPlayer(url: sound.file.fileURL!)
        
        print("Created sound for \(sound.title)")
        
        do {
            try player.activate()
            print("Activated session for \(sound.title)")
        } catch {
            print("Activation error:", error)
        }
        
        
        print("Playing sound \(sound.title)")
        await player.play()
        
        print("Sound \(sound.title) stopped")
        do {
            try player.deactivate()
            print("Deactivated session for \(sound.title)")
        } catch {
            print("Deactivated error:", error.localizedDescription)
        }
        
        return .result()
    }
}


class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    let player: AVAudioPlayer
    private var continuation: CheckedContinuation<Void, Never>?
    
    init(url: URL) throws {
        self.player = try AVAudioPlayer(contentsOf: url)
        super.init()
        self.player.delegate = self
    }
    func activate() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay, .duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    func deactivate() throws {
        try AVAudioSession.sharedInstance().setActive(false)
    }
    
    func play() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.player.play()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.continuation?.resume()
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
