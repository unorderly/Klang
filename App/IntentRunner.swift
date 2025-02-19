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
    private static var currentPlayer: AudioPlayer?
    private static var currentSoundTitle: String?

    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        if let player = currentPlayer, player.isPlaying, currentSoundTitle == intent.sound.title {
            print("Stopping sound \(intent.sound.title)")
            player.stop()
            currentPlayer = nil
            currentSoundTitle = nil
            return .result()
        }

        print("Start playing \(intent.sound.title)")
        let newPlayer = try! AudioPlayer(url: intent.sound.file.fileURL!)

        print("Created sound for \(intent.sound.title)")

        if intent.isFullBlast && newPlayer.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        currentPlayer = newPlayer
        currentSoundTitle = intent.sound.title

        do {
            print("Playing sound \(intent.sound.title)")
            try await newPlayer.playOnQueue()
            print("Sound \(intent.sound.title) stopped")

            if currentSoundTitle == intent.sound.title {
                currentPlayer = nil
                currentSoundTitle = nil
            }
        } catch {
            print("Playing Sound failed error:", error.localizedDescription)
            currentPlayer = nil
            currentSoundTitle = nil
        }
        return .result()
    }
}
