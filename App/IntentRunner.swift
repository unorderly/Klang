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
    private static var activePlayer: [UUID: AudioPlayer] = [:]

    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        let soundID = intent.sound.id

        if let player = activePlayer[soundID], player.isPlaying {
            print("Stopping sound \(intent.sound.title)")
            player.stop()
            activePlayer[soundID] = nil
            return .result()
        }

        guard let fileURL = intent.sound.file.fileURL, let newPlayer = try? AudioPlayer(url: fileURL) else {
            AudioErrorManager.errorManager.reportError("There was a error in the Widget")
            return .result()
        }

        activePlayer[soundID] = newPlayer
        print("Created sound for \(intent.sound.title)")

        if intent.isFullBlast && newPlayer.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        do {
            print("Playing sound \(intent.sound.title)")
            defer { activePlayer[soundID] = nil }
            try await newPlayer.playOnQueue()
            print("Sound \(intent.sound.title) stopped")
        } catch {
            AudioErrorManager.errorManager.reportError("There was a error playing sound in the Widget")
        }
        return .result()
    }
}
