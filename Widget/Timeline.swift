//
//  Timeline.swift
//  Widget
//
//  Created by Leo Mehlig on 27.08.23.
//

import WidgetKit
import SwiftUI
import Defaults

protocol SoundboardTimelineEntry: TimelineEntry {

    var sounds: [SoundEntity] { get }
    var isFullBlast: Bool { get }
    var board: BoardEntity? { get }
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


extension SoundsEntry {
    static var defaultEntry: Self {
        let intent = SoundsWidgetConfigIntent()
        return .init(date: .now, config: intent)
    }

    static var empty: SoundsEntry {
        let intent = SoundsWidgetConfigIntent()
        intent.sounds = []
        return .init(date: .now, config: intent)
    }
}

extension BoardEntry {
    static var defaultEntry: Self {
        let intent = BoardWidgetConfigIntent()
        return .init(date: .now, config: intent)
    }
}

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

