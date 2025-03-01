//
//  Control.swift
//  Widget
//
//  Created by Leo Mehlig on 01.03.25.
//

import SwiftUI
import WidgetKit
import AppIntents

@available(iOS 18, *)
struct SoundControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "app.klang.sounds_widget.control",
                                      provider: Provider()) { sound in
            ControlWidgetButton(action: SoundIntent(sound: sound, isFullBlast: false), label: {
                if let sound {
                    Label("\(sound.symbol) \(sound.title)",
                          image: "custom.speaker.wave.2.fill.badge.play")
                    .controlWidgetActionHint("Play \(sound.title)")
                } else {
                    Label("Choose Sound", systemImage: "speaker.badge.exclamationmark.fill")
                }
            }, actionLabel: { isPlaying in
                if isPlaying {
                    Text("Playing")
                }
            })
            .tint((sound?.color).flatMap(Color.init(hex:))?.ensureContrast ?? .red)
        }
                                      .promptsForUserConfiguration()
                                      .displayName("Play Sound")
                                      .description("Play a sound from your library.")
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: SingleSoundWidgetConfigIntent) -> SoundEntity? {
            configuration.sound
        }


        func currentValue(configuration: SingleSoundWidgetConfigIntent) async throws -> SoundEntity? {
            configuration.sound
        }
    }
}
