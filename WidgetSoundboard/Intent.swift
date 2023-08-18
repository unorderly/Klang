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
import Defaults

struct SoundIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "Play Sound"
    
    static var description = IntentDescription("Plays a sound")
    
    @Parameter(title: "Sound")
    var sound: SoundEntity
    
    @Parameter(title: "Full Blast Mode")
    var isFullBlast: Bool
    
    init(sound: SoundEntity, isFullBlast: Bool) {
        self.sound = sound
        self.isFullBlast = isFullBlast
    }
    
    init() {
    }
    
    func perform() async throws -> some IntentResult {
        print("Start playing \(sound.title)")
        
        let player = try AudioPlayer(url: sound.file.fileURL!)
        
        print("Created sound for \(sound.title)")
        
        if self.isFullBlast && player.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }
        
        do {
            print("Playing sound \(sound.title)")
            try await player.playOnQueue()
            print("Sound \(sound.title) stopped")
        } catch {
            print("Playing Sound fauled error:", error.localizedDescription)
        }
        
        return .result()
    }
}
