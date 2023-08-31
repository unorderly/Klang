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
    static let sounds = Defaults.Key<[Sound]>("app_soundboard_sounds", default: [], suite: .kit)

    static let boards = Defaults.Key<[Board]>("app_soundboard_soundboards", default: [], suite: .kit)
}

struct Board: Codable, Defaults.Serializable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var symbol: String
    var color: Color
    var sounds: [UUID]
    var galleryID: UUID?

    init(id: UUID = .init(), title: String, symbol: String, color: Color, sounds: [UUID], galleryID: UUID? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color
        self.sounds = sounds
        self.galleryID = galleryID
    }

    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to value: Value) -> Self {
        var object = self
        object[keyPath: keyPath] = value
        return object
    }

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

    static let preview: Board = Board(id: .init(uuidString: "2f8b9a6d-4c3e-4f17-a9c2-7e12d7a5b8e1")!,
                                      title: "Preview",
                                      symbol: "🎛️",
                                      color: .blue,
                                      sounds: Sound.preview.map(\.id))

    func delete(from boards: inout [Board], with sounds: inout [Sound], includeSounds: Bool) {
        boards.removeAll(where: { $0.id == self.id })
        if includeSounds {
            let deletedSounds = self.sounds.filter({ sound in
                !boards.contains(where: { $0.sounds.contains(sound) })
            })
            sounds.removeAll(where: { deletedSounds.contains($0.id) })
        }
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

    static let preview: [Sound] = [
        Sound(id: .init(uuidString: "68397bc1-2866-4a27-a966-235bafe73f44")!,
              title: "Toy",
              symbol: "🪆",
              color: .red,
              file: "preview-toy.mp3"),
        Sound(id: .init(uuidString: "d319d8c5-8261-4679-9d08-9a1a7e47ca8b")!,
              title: "Toilet",
              symbol: "🚽",
              color: .blue,
              file: "preview-toilet.mp3"),
        Sound(id: .init(uuidString: "f8ed6679-2c32-4d05-a646-b608522d9873")!,
              title: "Silly",
              symbol: "🙃",
              color: .orange,
              file: "preview-silly.mp3")
    ]
}
