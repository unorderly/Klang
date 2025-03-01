//
//  SoundWidget.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import SwiftUI
import Defaults

struct SoundWidgetEmptyView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var rows: Int {
        switch widgetFamily {
        case .accessoryCircular, .accessoryRectangular:
            return 1
        case .systemSmall, .systemMedium:
            return 2
        case .systemLarge, .systemExtraLarge:
            return 4
        default:
            return 0
        }
    }
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ForEach(Array(0..<self.rows), id: \.self) { _ in
                    HStack(spacing: 12) {
                        ForEach(Array(0..<(self.rows * widgetFamily.aspectRatio)), id: \.self) { _ in
                            ContainerRelativeShape()
                                .foregroundStyle(Color.palette.randomElement()!)
                                .opacity(0.3)
                        }
                    }
                }
            }
            .blur(radius: 5.0)

            switch widgetFamily {
            case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
                VStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.headline)
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                    Label("Press and Hold to Edit Widget", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleOnly)
                        .multilineTextAlignment(.center)
                }
            case .accessoryRectangular:
                Label("Setup Widget", systemImage: "info.circle.fill")
                    .font(.headline)
                    .imageScale(.large)
                    .symbolRenderingMode(.hierarchical)
            case .accessoryCircular:
                Image(systemName: "info.circle.fill")
                    .font(.headline)
                    .imageScale(.large)
                    .symbolRenderingMode(.hierarchical)
            default: EmptyView()
            }

        }
        .widgetURL(URL(string: "klang://setup-widget")!)
    }
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
                SoundWidgetEmptyView()
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
                                                    .tint(Color(hex: sound.color)?.ensureContrast ?? .red)
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

#Preview("Empty-Small", as: .systemSmall) {
    SoundsWidget()
} timeline: {
    SoundsEntry.empty
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
