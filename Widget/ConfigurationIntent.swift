//
//  AppIntent.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import AppIntents
import Defaults

struct SoundsWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Soundboard Widget Configration"
    static var description = IntentDescription("This is used to configure the widget.")

    @Parameter(title: "Sounds",
               description: "Pick the sounds for this widgets. If there is not enough room for all sounds, only the first will be displayed.",
               default: [])
    var sounds: [SoundEntity]

    @Parameter(title: "Full Blast Mode",
               description: "If enabled, the sound will set to full volumn before playing the sound. To protect your ears, this only happens when no headphones/speakers are connected (hopefully).",
               default: false)
    var isFullBlast: Bool

    init(sounds: [SoundEntity] = SoundEntity.default, isFullBlast: Bool) {
        self.sounds = sounds
        self.isFullBlast = isFullBlast
    }

    init() { 
        self.init(isFullBlast: false)
    }
}

struct BoardWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Soundboard Widget Configration"
    static var description = IntentDescription("This is used to configure the widget.")

    @Parameter(title: "Board")
    var board: BoardEntity?

    @Parameter(title: "Full Blast Mode",
               description: "If enabled, the sound will set to full volumn before playing the sound. To protect your ears, this only happens when no headphones/speakers are connected (hopefully).",
               default: false)
    var isFullBlast: Bool

    init(board: BoardEntity? = .default, isFullBlast: Bool) {
        self.board = board
        self.isFullBlast = isFullBlast
    }

    init() { 
        self.init(isFullBlast: false)
    }
}

@available(iOS 18, *)
struct SingleSoundWidgetConfigIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Soundboard Widget Configration"
    static var description = IntentDescription("This is used to configure the widget.")

    @Parameter(title: "Sound",
               description: "Pick the sound for this control.")
    var sound: SoundEntity?

    @Parameter(title: "Full Blast Mode",
               description: "If enabled, the sound will set to full volumn before playing the sound. To protect your ears, this only happens when no headphones/speakers are connected (hopefully).",
               default: false)
    var isFullBlast: Bool

    init(sound: SoundEntity? = SoundEntity.default.first, isFullBlast: Bool) {
        self.sound = sound
        self.isFullBlast = isFullBlast
    }

    init() {
        self.init(isFullBlast: false)
    }
}
