//
//  URL.swift
//  Klang
//
//  Created by Leo Mehlig on 01.03.25.
//

import Foundation

extension FileManager {
    var containerURL: URL {
        self.containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
    }

    func deleteIfExists(at url: URL) {
        if self.fileExists(atPath: url.path) {
            try? self.removeItem(at: url)
        }
    }
}
