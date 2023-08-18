//
//  Item.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
//

import Foundation
import Defaults
import SwiftUI

public extension UserDefaults {
    static let kit: UserDefaults = {
        UserDefaults(suiteName: "group.io.unorderly.soundboard")!
    }()
}

extension Defaults.Keys {
    static let sounds = Defaults.Key<[Sound]>("app_soundboard_sounds", suite: .kit) {
        Sound.default.map { sound in
            let newURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
                .appending(component: sound.id.uuidString)
                .appendingPathExtension(sound.url.pathExtension)
            do {
                try FileManager.default.removeItem(at: newURL)
            } catch { }
            try! FileManager.default.copyItem(at: sound.url, to: newURL)
            return sound.set(\.url, to: newURL)
        }
    }

    static let boards = Defaults.Key<[Board]>("app_soundboard_soundboards", suite: .kit) {
        Board.default
    }
}

struct Board: Codable, Defaults.Serializable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var symbol: String
    var color: Color
    var sounds: [UUID]

    init(id: UUID = .init(), title: String, symbol: String, color: Color, sounds: [UUID]) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color
        self.sounds = sounds
    }

    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to value: Value) -> Self {
        var object = self
        object[keyPath: keyPath] = value
        return object
    }

    static var `default`: [Board] = [
        .init(id: UUID(uuidString: "052171A6-1018-4DAB-8E97-27A6DDFC0018")!,
              title: "Klang",
              symbol: "🔔",
              color: .pink,
              sounds: Sound.default.map(\.id))
    ]

    static var allID: UUID {
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    }

    static func allBoard(with sounds: [Sound]) -> Board {
        Board(id: Board.allID,
              title: "All",
              symbol: "📣",
              color: .blue,
              sounds: sounds.map(\.id))
    }
}

struct Sound: Codable, Defaults.Serializable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var symbol: String
    var color: Color
    var url: URL
    
    init(id: UUID = .init(), title: String, symbol: String, color: Color, url: URL) {
        self.id = id
        self.url = url
        self.title = title
        self.symbol = symbol
        self.color = color
    }
    
    init(id: UUID = .init(), title: String, symbol: String, color: Color, file: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color
        self.url = Bundle.main.url(forResource: file, withExtension: nil)!
    }
    
    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to value: Value) -> Self {
        var object = self
        object[keyPath: keyPath] = value
        return object
    }
    
    static var `default`: [Sound] = [
        .init(id: UUID(uuidString: "052171A6-1008-4DF5-8E97-27A6CCFC0018")!, title: "Horse", symbol: "🐴", color: .brown, file: "horse.m4a"),
        .init(id: UUID(uuidString: "5FAA1AC1-AF94-41ED-9038-2AE7C6AF1B62")!, title: "Seagulls", symbol: "🐦", color: .blue, file: "seagulls.caf"),
        .init(id: UUID(uuidString: "F3827106-F450-412B-AD99-B9746A18B224")!, title: "Frog", symbol: "🐸", color: .green, file: "frog.caf"),
        .init(id: UUID(uuidString: "EDE81226-88E1-4321-BC89-855B005D5063")!, title: "Wait", symbol: "🚦", color: .yellow, file: "wait.m4a"),
    ]
}
