//
//  IntentRunner.swift
//  App
//
//  Created by Leo Mehlig on 07.09.23.
//

import Foundation
import AppIntents
import UIKit
import MediaPlayer

enum IntentRunner {
    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        print("Start playing \(intent.sound.title)")
        let player = try! AudioPlayer(url: intent.sound.file.fileURL!)

        print("Created sound for \(intent.sound.title)")

        if intent.isFullBlast && player.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        do {
            print("Playing sound \(intent.sound.title)")
            try await player.playOnQueue()
            print("Sound \(intent.sound.title) stopped")
        } catch {
            print("Playing Sound fauled error:", error.localizedDescription)
        }
        return .result()
    }
}
