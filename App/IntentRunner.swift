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
    private static var activePlayer: [String: AudioPlayer] = [:]

    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        let soundTitle = intent.sound.title

        if let player = activePlayer[soundTitle], player.isPlaying {
            print("Stopping sound \(intent.sound.title)")
            player.stop()
            activePlayer[soundTitle] = nil
            return .result()
        }

        print("Start playing \(intent.sound.title)")
        let newPlayer = try! AudioPlayer(url: intent.sound.file.fileURL!)

        print("Created sound for \(intent.sound.title)")

        if intent.isFullBlast && newPlayer.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        activePlayer[soundTitle] = newPlayer

        do {
            print("Playing sound \(intent.sound.title)")
            try await newPlayer.playOnQueue()
            print("Sound \(intent.sound.title) stopped")

            activePlayer[intent.sound.title] = nil
        } catch {
            print("Playing Sound failed error:", error.localizedDescription)
            activePlayer[intent.sound.title] = nil
        }
        return .result()
    }
}
