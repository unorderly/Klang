//
//  AudioPlayer.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 26.07.23.
//

import Foundation
import AVFoundation
import SwiftUI
import UIKit
import MediaPlayer

@Observable
final class AudioPlayer: NSObject, AVAudioPlayerDelegate {

    /// How the audio session has to be set up to play a sound.
    struct Configuration: Equatable {
        /// Plays the sound on top of other audio instead of interrupting it.
        var isOverlay: Bool

        /// Overlay sounds play over other audio. Per the AVAudioSession docs for the
        /// `voicePrompt` mode and the `interruptSpokenAudioAndMixWithOthers` option, such audio ducks music
        /// and pauses spoken audio (podcasts, audiobooks), which resumes afterwards.
        var mode: AVAudioSession.Mode {
            self.isOverlay ? .voicePrompt : .default
        }

        /// Both options make the session mixable, which is what lets the sound play on top of
        /// other audio, but also means iOS doesn't consider the app the primary audio app.
        var options: AVAudioSession.CategoryOptions {
            self.isOverlay ? [.duckOthers, .interruptSpokenAudioAndMixWithOthers] : []
        }
    }

    let player: AVAudioPlayer

    /// Plays the sound on top of other audio instead of interrupting it.
    var isOverlay: Bool
    
    var isPlaying: Bool = false
    
    var progress: Double = 0

    /// Guards ``continuation``, which is resumed from the delegate, the monitor and the
    /// cancellation handler, all of which can run at the same time.
    private let continuationLock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var playingTask: Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?
    
    init(url: URL, isOverlay: Bool = false) throws {
        print(url)
        self.player = try AVAudioPlayer(contentsOf: url)
        self.isOverlay = isOverlay
        super.init()
        self.player.delegate = self
    }

    var configuration: Configuration {
        Configuration(isOverlay: self.isOverlay)
    }
    
    static let queue = ConcurrentQueue<Configuration>(setup: { try AudioPlayer.activate(with: $0) },
                                                      teardown: { try AudioPlayer.deactivate() })

    /// Configures and activates the session. Both happen together and only while no sound is
    /// playing: changing the category of a session that is already playing (and, for overlay
    /// sounds, ducking another app) is what makes iOS refuse the change.
    static func activate(with configuration: Configuration) throws {
        do {
            try Self.configureSession(with: configuration)
        } catch {
            // Activating fails when the session got left in a bad state, e.g. when iOS suspended
            // the app while a sound was still playing. Deactivating clears that state, instead of
            // leaving the app unable to play anything until it is force quit.
            print("Failed to activate audio session: \(error). Trying again.")
            try? Self.deactivate()
            try Self.configureSession(with: configuration)
        }
    }

    private static func configureSession(with configuration: Configuration) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback,
                                mode: configuration.mode,
                                options: configuration.options)
        try session.setActive(true)
    }
    
    static func deactivate() throws {
        try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    var isOnSpeaker: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.allSatisfy({ $0.portType == .builtInSpeaker })
    }
    
    func playOnQueue() async throws {
        // Sounds started from a widget play while the app is in the background. iOS extends the
        // app's runtime on its own only while it is the primary audio app, which an overlay sound
        // isn't, because it mixes with whatever else is playing. Without holding on to the runtime
        // ourselves, iOS suspends the app in the middle of a sound, which leaves the audio session
        // in a state where no further sound plays until the app is force quit.
        let activity = await BackgroundActivity.begin(name: "Playing Sound")
        do {
            try await Self.queue.add(context: self.configuration) {
                await self.play()
            }
        } catch {
            await activity.end()
            throw error
        }
        await activity.end()
    }

    static func cancelQueue() async {
        await self.queue.cancelAll()
    }

    private func play() async {
        self.playingTask?.cancel()
        self.playingTask = Task { [weak self] in
            await withTaskCancellationHandler {
                self?.isPlaying = true
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    guard let self else {
                        // Nobody is left to play the sound, so the continuation has to be resumed
                        // here. Leaking it would block the audio session for good.
                        continuation.resume()
                        return
                    }
                    self.continuationLock.lock()
                    self.continuation = continuation
                    self.continuationLock.unlock()
                    if self.player.play() {
                        self.startMonitoring()
                    } else {
                        self.finishPlaying()
                    }
                }
                self?.isPlaying = false
                self?.stopMonitoring()
            } onCancel: { [weak self] in
                guard let self else { return }
                if self.player.isPlaying {
                    self.player.stop()
                    self.player.currentTime = 0
                }
                self.finishPlaying()
                self.isPlaying = false
                self.stopMonitoring()
            }
        }
  
        await self.playingTask?.value
    }
    
    func stop() {
        self.playingTask?.cancel()
    }

    /// Keeps ``progress`` up to date and notices when the sound stopped playing.
    ///
    /// `AVAudioPlayer` doesn't call its delegate in every case: when the audio session gets
    /// interrupted, or when iOS suspends the app in the middle of a sound, playback just stops.
    /// Polling the player makes sure playback always finishes and hands the audio session back,
    /// instead of blocking every sound that comes after it.
    private func startMonitoring() {
        self.monitorTask?.cancel()
        self.monitorTask = Task.detached(priority: .utility) { [weak self] in
            // Give the player a moment to actually start before checking whether it is playing.
            try? await Task.sleep(for: .milliseconds(50))
            while !Task.isCancelled {
                guard let self else { return }
                let isPlaying = self.player.isPlaying
                let progress = self.player.duration > 0 ? self.player.currentTime / self.player.duration : 0
                await MainActor.run {
                    self.progress = isPlaying ? progress : 0
                }
                guard isPlaying else {
                    self.finishPlaying()
                    return
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopMonitoring() {
        self.monitorTask?.cancel()
        self.monitorTask = nil
        self.progress = 0
    }

    /// Resumes the continuation exactly once, no matter which of the delegate callbacks, the
    /// monitor or the cancellation handler notices first that the sound stopped.
    private func finishPlaying() {
        self.continuationLock.lock()
        let continuation = self.continuation
        self.continuation = nil
        self.continuationLock.unlock()
        continuation?.resume()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.finishPlaying()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.finishPlaying()
    }


}

/// Keeps the app running for a little while after it would otherwise be suspended.
@MainActor
final class BackgroundActivity {
    private var identifier: UIBackgroundTaskIdentifier = .invalid

    static func begin(name: String) -> BackgroundActivity {
        let activity = BackgroundActivity()
        activity.identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak activity] in
            Task { @MainActor in
                activity?.end()
            }
        }
        return activity
    }

    func end() {
        guard self.identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(self.identifier)
        self.identifier = .invalid
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
