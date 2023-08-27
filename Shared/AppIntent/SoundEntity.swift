//
//  SoundEntity.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import Foundation
import AppIntents
import SwiftUI
import Defaults

struct SoundEntity: AppEntity, Identifiable, Hashable {

    static var defaultQuery: SoundQuery = SoundQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Sound")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(self.symbol) \(self.title)")
    }

    var id: UUID

    @Property(title: "Title")
    var title: String

    @Property(title: "Symbol")
    var symbol: String

    @Property(title: "Color")
    var color: String

    @Property(title: "Sound")
    var file: IntentFile

    init(id: UUID, title: String, symbol: String, color: Color, url: URL) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color.hex()
        self.file = IntentFile(fileURL: url)
    }

    init(sound: Sound) {
        self.init(
            id: sound.id,
            title: sound.title,
            symbol: sound.symbol,
            color: sound.color,
            url: sound.url
        )
    }

    static func == (lhs: SoundEntity, rhs: SoundEntity) -> Bool {
        lhs.id == rhs.id
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

struct SoundQuery: EntityStringQuery {
    func entities(for identifiers: [SoundEntity.ID]) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ identifiers.contains($0.id) })
            .map({ SoundEntity(sound: $0) })
    }

    func entities(matching string: String) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ $0.title.contains(string) })
            .map({ SoundEntity(sound: $0) })
    }

    func suggestedEntities() async throws -> [SoundEntity] {
        Defaults[.sounds]
            .map({ SoundEntity(sound: $0) })
    }
}

