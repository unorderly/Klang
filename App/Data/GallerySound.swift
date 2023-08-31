//
//  GallerySound.swift
//  App
//
//  Created by Leo Mehlig on 31.08.23.
//

import SwiftUI
import Defaults

struct GallerySound: Codable, Identifiable, Hashable {

    enum License: Hashable, Codable, CustomStringConvertible {
        case cc0, ccAttribution

        var description: String {
            switch self {
            case .cc0:
                return "Creative Commons 0 License"
            case .ccAttribution:
                return "Creative Commons Attribution License"
            }
        }
    }
    var id: UUID
    var title: String
    var symbol: String
    var color: Color
    var url: URL
    var source: URL
    var license: License


    init(id: UUID = .init(), title: String, symbol: String, color: Color, source: URL, license: License, url: URL) {
        self.id = id
        self.url = url
        self.title = title
        self.symbol = symbol
        self.color = color
        self.source = source
        self.license = license
    }

    init(id: UUID = .init(), title: String, symbol: String, color: Color, source: URL, license: License, file: String) {
        self.init(
            id: id,
            title: title,
            symbol: symbol,
            color: color,
            source: source,
            license: license,
            url: Bundle.main.url(forResource: "Gallery/" + file, withExtension: nil)!
        )
    }

    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to value: Value) -> Self {
        var object = self
        object[keyPath: keyPath] = value
        return object
    }

    @discardableResult
    func save() -> Sound {
        let newURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
            .appending(component: self.id.uuidString)
            .appendingPathExtension(self.url.pathExtension)
        do {
            try FileManager.default.removeItem(at: newURL)
        } catch { }
        try! FileManager.default.copyItem(at: self.url, to: newURL)
        let sound = Sound(title: self.title, symbol: self.symbol, color: self.color, url: newURL)
        Defaults[.sounds].append(sound)
        return sound
    }
}

