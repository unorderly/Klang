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
    private static let activePlayer = PlayerStore()

    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        guard let sound = intent.sound else {
            return .result()
        }
        let soundID = sound.id

        if let player = activePlayer[soundID], player.isPlaying {
            print("Stopping sound \(sound.title)")
            player.stop()
            activePlayer.remove(player, for: soundID)
            return .result()
        }

        guard let fileURL = sound.file.fileURL, let newPlayer = try? AudioPlayer(url: fileURL, isOverlay: intent.isOverlay) else {
            AudioErrorManager.errorManager.reportError("There was a error in the Widget")
            return .result()
        }

        activePlayer[soundID] = newPlayer
        print("Created sound for \(sound.title)")

        if intent.isFullBlast && newPlayer.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }

        do {
            print("Playing sound \(sound.title)")
            defer { activePlayer.remove(newPlayer, for: soundID) }
            try await newPlayer.playOnQueue()
            print("Sound \(sound.title) stopped")
        } catch is CancellationError {
            // iOS cancelled the intent, e.g. because the sound was stopped from another button.
            // That isn't something to bother the user with.
            print("Playback of \(sound.title) was cancelled")
        } catch {
            print("Failed to play sound \(sound.title): \(error)")
            AudioErrorManager.errorManager.reportError("There was a error playing sound in the Widget")
        }
        return .result()
    }
}

/// Keeps track of the sounds that are currently playing, so that tapping a playing sound in the
/// widget stops it again.
///
/// Widget buttons can be tapped in quick succession, which runs several intents at the same time.
/// A plain dictionary would be read and written concurrently by those, which corrupts it.
private final class PlayerStore {
    private let lock = NSLock()
    private var players: [UUID: AudioPlayer] = [:]

    subscript(id: UUID) -> AudioPlayer? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.players[id]
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.players[id] = newValue
        }
    }

    /// Removes `player`, unless a newer one already took its place.
    func remove(_ player: AudioPlayer, for id: UUID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.players[id] === player {
            self.players[id] = nil
        }
    }
}
