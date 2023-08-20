//
//  SoundWidget.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import SwiftUI
import Defaults

struct SoundTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SoundsEntry
    typealias Intent = SoundsWidgetConfigIntent

    func placeholder(in context: Context) -> Entry {
        .init(date: Date(), config: .init())
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        .init(date: Date(), config: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        return Timeline(entries: [.init(date: .now, config: configuration)], policy: .never)
    }
}

struct BoardTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = BoardEntry
    typealias Intent = BoardWidgetConfigIntent

    func placeholder(in context: Context) -> Entry {
        .init(date: Date(), config: .init())
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        .init(date: Date(), config: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        return Timeline(entries: [.init(date: .now, config: configuration)], policy: .never)
    }
}


struct SoundsEntry: SoundboardTimelineEntry {

    var date: Date
    let config: SoundsWidgetConfigIntent
    var sounds: [SoundEntity] { config.sounds }

    var isFullBlast: Bool { config.isFullBlast }
    var board: BoardEntity? { nil }
}

struct BoardEntry: SoundboardTimelineEntry {
    var date: Date
    let config: BoardWidgetConfigIntent

    var sounds: [SoundEntity] {
        config.board?.sounds ?? []
    }

    var isFullBlast: Bool { config.isFullBlast }

    var board: BoardEntity? { config.board }

}

protocol SoundboardTimelineEntry: TimelineEntry {

    var sounds: [SoundEntity] { get }
    var isFullBlast: Bool { get }
    var board: BoardEntity? { get }
}

struct SoundWidgetEntryView<Entry: SoundboardTimelineEntry>: View {
    var entry: Entry

    @Environment(\.widgetFamily) var widgetFamily

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

    var sounds: [SoundEntity] {
        self.entry.sounds
    }

    func rows(with numberOfRows: Int) -> [Row] {
        let columns = numberOfRows * self.widgetFamily.aspectRatio
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
        self.widgetFamily.rows(for: self.sounds.count)
    }

    @ScaledMetric(relativeTo: .title2) var size: CGFloat = 30
    var body: some View {
        Group {
            if sounds.isEmpty {
                Text("Tap and hold the widget to add sounds")
            } else {
                VStack {
                    if let board = entry.board?.board {
                        HStack {
                            Text(board.symbol)
                            Text(board.title)
                            Spacer()
                        }
                        .foregroundColor(board.color)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                    }
                    ViewThatFits {
                        ForEach((1...self.maxRows).reversed(), id: \.self) { count in
                            VStack(spacing: 4) {
                                ForEach(self.rows(with: count)) { row in
                                    HStack(spacing: 4) {
                                        ForEach(row.items) { item in
                                            Group {
                                                switch item {
                                                case .sound(let sound, _):
                                                    Button(intent: SoundIntent(sound: sound, isFullBlast: entry.isFullBlast)) {
                                                        Text(sound.symbol)
                                                            .minimumScaleFactor(0.5)
                                                            .font(.title2)
                                                            .aligned(to: .all)
                                                    }
                                                    .buttonBorderShape(.roundedRectangle)
                                                    .buttonStyle(.bordered)
//                                                    .buttonStyle(.borderless)
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
        Int(ceil(sqrt(ceil(Double(count) / Double(aspectRatio)))))
    }
}

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

extension SoundsEntry {
    fileprivate static var defaultEntry: Self {
        let intent = SoundsWidgetConfigIntent()
        intent.sounds = Sound.default.map({ SoundEntity(sound: $0) })
        return .init(date: .now, config: intent)
    }

    fileprivate static var empty: SoundsEntry {
        let intent = SoundsWidgetConfigIntent()
        return .init(date: .now, config: intent)
    }
}

extension BoardEntry {
    fileprivate static var defaultEntry: Self {
        let intent = BoardWidgetConfigIntent()
        intent.board = BoardEntity(board: .default.first!)
        return .init(date: .now, config: intent)
    }
}

#Preview(as: .systemSmall) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}

#Preview("Board", as: .systemSmall) {
    BoardWidget()
} timeline: {
    BoardEntry.defaultEntry
}

#Preview(as: .systemMedium) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}
#Preview(as: .systemLarge) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}

#Preview(as: .systemExtraLarge) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}

#Preview(as: .accessoryCircular) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}


#Preview(as: .accessoryRectangular) {
    SoundsWidget()
} timeline: {
    SoundsEntry.defaultEntry
}
