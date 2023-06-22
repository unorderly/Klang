//
//  AppIntent.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    @Parameter(title: "Sounds",
               description: "Pick the sounds for this widgets. If there is not enough room for all sounds, only the first will be displayed.",
               default: [],
               size: [
                .systemSmall: .init(min: 0, max: 4),
                .systemMedium: .init(min: 0, max: 8),
                .systemLarge: .init(min: 0, max: 16),
                .systemExtraLarge: .init(min: 0, max: 32),
                .accessoryCircular: .init(min: 0, max: 1),
                .accessoryRectangular: .init(min: 0, max: 2),
                .accessoryInline: .init(min: 0, max: 0)
               ])
    var sounds: [SoundEntity]
    
    
    @Parameter(title: "Full Blast Mode",
               description: "If enabled, the sound will set to full volumn before playing the sound. To protect your ears, this only happens when no headphones/speakers are connected (hopefully).",
               default: false)
    var isFullBlast: Bool
}
