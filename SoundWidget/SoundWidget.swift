//
//  SoundWidget.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        return Timeline(entries: [.init(date: .now, configuration: configuration)], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    
    var playingSound: String? = nil
    
    let configuration: ConfigurationAppIntent
}

struct SoundWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var maxCount: Int {
        switch widgetFamily {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 8
        case .systemLarge:
            return 16
        case .systemExtraLarge:
            return 32
        case .accessoryCircular:
            return 1
        case .accessoryRectangular:
            return 2
        case .accessoryInline:
            return 0
        @unknown default:
            return 0
        }
    }
    
    @ScaledMetric(relativeTo: .title2) var size: CGFloat = 50
    var body: some View {
        Group {
            if entry.configuration.sounds.isEmpty {
                Text("Tap and hold the widget to add sounds")
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: size), alignment: .topLeading)
                ]) {
                    ForEach(Array(entry.configuration.sounds.prefix(maxCount))) { sound in
                        Button(intent: SoundIntent(sound: sound, isFullBlast: entry.configuration.isFullBlast)) {
                            Text(sound.symbol)
                                .minimumScaleFactor(0.5)
                                .font(.title2)
                                .aligned(to: .all)
                                .padding(4)
                                .frame(maxHeight: size)
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .buttonStyle(.bordered)
                        .tint(Color(hex: sound.color) ?? .red)
                    }
                }
//                .background(Color.red)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .containerBackground(.fill, for: .widget)
    }
}

struct SoundWidget: Widget {
    let kind: String = "SoundWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SoundWidgetEntryView(entry: entry)
        }
        .supportedFamilies([
            .accessoryRectangular, .accessoryRectangular, .systemLarge, .systemSmall, .systemMedium, .systemExtraLarge
        ])
//        .contentMarginsDisabled()
        .containerBackgroundRemovable()
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.sounds = Sound.default.map({ SoundEntity(sound: $0) })
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
//        intent.soundboard = 0
        return intent
    }
}

#Preview(as: .systemSmall) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}

#Preview(as: .systemMedium) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
