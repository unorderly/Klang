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

    struct Row: Identifiable {
        let index: Int
        let items: [Item]

        var id: Int { self.index }
    }
    enum Item: Identifiable {
        case sound(SoundEntity, Int)
        case placeholder(Int)

        var id: String {
            switch self {
            case .sound(let sound, let index):
                return sound.id.uuidString + "-\(index)"
            case .placeholder(let index):
                return "placeholder-\(index)"
            }
        }
    }
    func rows(with numberOfRows: Int) -> [Row] {
        let sounds = self.entry.configuration.sounds
        let columns = numberOfRows * self.widgetFamily.aspectRatio
        print(sounds.count, numberOfRows, columns)
        let items = sounds.enumerated().map({ Item.sound($0.element, $0.offset) }).fillOrPrefix(to: columns * numberOfRows, using: Item.placeholder)
        return items.reduce([], { rows, sound in
            if let last = rows.last, last.count < columns {
                return rows.dropLast() + [last + [sound]]
            } else {
                return rows + [[sound]]
            }
        }).enumerated().map({ .init(index: $0.offset, items: $0.element) })
    }

    var maxRows: Int {
        self.widgetFamily.rows(for: self.entry.configuration.sounds.count)
    }

    @ScaledMetric(relativeTo: .title2) var size: CGFloat = 44
    var body: some View {
        Group {
            if entry.configuration.sounds.isEmpty {
                Text("Tap and hold the widget to add sounds")
            } else {
                ViewThatFits {
                    ForEach((1...self.maxRows).reversed(), id: \.self) { count in
                        VStack(spacing: 4) {
                            ForEach(self.rows(with: count)) { row in
                                HStack(spacing: 4) {
                                    ForEach(row.items) { item in
                                        Group {
                                            switch item {
                                            case .sound(let sound, _):
                                                Button(intent: SoundIntent(sound: sound, isFullBlast: entry.configuration.isFullBlast)) {
                                                    Text(sound.symbol)
                                                        .minimumScaleFactor(0.5)
                                                        .font(.title2)
                                                        .aligned(to: .all)
                                                        .padding(4)
                                                }
                                                .buttonBorderShape(.roundedRectangle)
                                                .buttonStyle(.bordered)
                                                .tint(Color(hex: sound.color) ?? .red)
                                            case .placeholder:
                                                Color.clear
                                            }
                                        }
                                        .frame(minWidth: size, minHeight: size)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .containerBackground(.fill, for: .widget)
    }
}

extension Collection where Index == Int {
    func fillOrPrefix(to count: Int, using filler: (Int) -> Element) -> [Element] {
        if self.count >= count {
            return Array(self.prefix(count))
        } else {
           return Array(self) + (0..<(count - self.count)).map(filler)
        }
    }
}

extension WidgetFamily {
    var aspectRatio: Int {
        switch self {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        case .systemLarge:
            return 1
        case .systemExtraLarge:
            return 2
        case .accessoryCircular:
            return 1
        case .accessoryRectangular:
            return 2
        case .accessoryInline:
            return 1
        @unknown default:
            return 1
        }
    }

    func rows(for count: Int) -> Int {
        // x * r = c <=> x = c / r
        // r = 2
        // c = 4 => 1
        // c = 5 => 2
        Int(ceil(sqrt(ceil(Double(count) / Double(aspectRatio)))))
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
//            .dropLast(2)
                + Sound.default.map({ SoundEntity(sound: $0) })
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

#Preview(as: .systemLarge) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}

#Preview(as: .systemExtraLarge) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}

#Preview(as: .accessoryCircular) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}


#Preview(as: .accessoryRectangular) {
    SoundWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
