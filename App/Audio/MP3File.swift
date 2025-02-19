//
//  MP3File.swift
//  Klang
//
//  Created by Mariela  on 19.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MP3File: FileDocument {
    static var readableContentTypes = [UTType.mp3]

    var fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(configuration: ReadConfiguration) throws {
        throw NSError(domain: "MP3File", code: 1, userInfo: nil)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL)
    }
}
