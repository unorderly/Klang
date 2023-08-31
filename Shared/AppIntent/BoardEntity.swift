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

struct BoardEntity: AppEntity, Identifiable, Hashable {

    static var defaultQuery: BoardQuery = BoardQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Soundboard")

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

    init(id: UUID, title: String, symbol: String, color: Color) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color.hex()
    }

    init(board: Board, allSounds: [Sound] = Defaults[.sounds]) {
        self.init(
            id: board.id,
            title: board.title,
            symbol: board.symbol,
            color: board.color
        )
    }


    static var `default`: BoardEntity? {
        if let board = Defaults[.boards].first {
            return BoardEntity(board: board)
        }
        return nil
    }

    var board: Board? {
        Defaults[.boards].first(where: { $0.id == self.id })
    }

    var sounds: [SoundEntity] {
        if let board {
            return board.sounds
                .compactMap({ id in Defaults[.sounds].first(where: { $0.id == id }) })
                .map(SoundEntity.init(sound:))
        } else {
            return []
        }
    }

    static func == (lhs: BoardEntity, rhs: BoardEntity) -> Bool {
        lhs.id == rhs.id
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

struct BoardQuery: EntityStringQuery {
    func entities(for identifiers: [BoardEntity.ID]) async throws -> [BoardEntity] {
        return Defaults[.boards]
            .filter({ identifiers.contains($0.id) })
            .map({ BoardEntity(board: $0) })
    }

    func entities(matching string: String) async throws -> [BoardEntity] {
        return Defaults[.boards]
            .filter({ $0.title.contains(string) })
            .map({ BoardEntity(board: $0) })
    }

    func suggestedEntities() async throws -> [BoardEntity] {
        Defaults[.boards]
            .map({ BoardEntity(board: $0) })
    }
}

