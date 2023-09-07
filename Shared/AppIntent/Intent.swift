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

struct SoundIntent: AudioPlaybackIntent {
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
        return try await IntentRunner.perform(intent: self)
    }
}
