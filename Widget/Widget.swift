//
//  Widget.swift
//  Widget
//
//  Created by Leo Mehlig on 27.08.23.
//

import WidgetKit
import SwiftUI

struct SoundsWidget: Widget {
    let kind: String = "app.klang.sounds_widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SoundsWidgetConfigIntent.self, provider: SoundTimelineProvider()) { entry in
            SoundWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sounds")
        .description("Choose from all your sounds")
        .supportedFamilies([
            .accessoryRectangular, .accessoryRectangular, .systemLarge, .systemSmall, .systemMedium, .systemExtraLarge
        ])
        .containerBackgroundRemovable()
    }
}


struct BoardWidget: Widget {
    let kind: String = "app.klang.board_widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BoardWidgetConfigIntent.self, provider: BoardTimelineProvider()) { entry in
            SoundWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Board")
        .description("Select one of your boards and get its sounds in the widget")
        .supportedFamilies([
            .systemLarge, .systemSmall, .systemMedium, .systemExtraLarge
        ])
        .containerBackgroundRemovable()
    }
}
