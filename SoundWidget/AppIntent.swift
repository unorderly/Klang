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
               default: [])
    var sounds: [SoundEntity]
}
