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
    private static var player: AudioPlayer?

    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        if let currentPlayer = player, currentPlayer.isPlaying {
            print("Stopping sound \(intent.sound.title)")
            currentPlayer.stop()
            player = nil
            return .result()
        }

        print("Start playing \(intent.sound.title)")
        let newPlayer = try! AudioPlayer(url: intent.sound.file.fileURL!)
        player = newPlayer

        print("Created sound for \(intent.sound.title)")

        if intent.isFullBlast && newPlayer.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        do {
            print("Playing sound \(intent.sound.title)")
            try await newPlayer.playOnQueue()
            print("Sound \(intent.sound.title) stopped")
        } catch {
            print("Playing Sound fauled error:", error.localizedDescription)
        }
        return .result()
    }
}
