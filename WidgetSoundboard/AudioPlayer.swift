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
    let player: AVAudioPlayer
    
    var isPlaying: Bool = false
    
    var progress: Double = 0
    
    private var continuation: CheckedContinuation<Void, Never>?
    private var playingTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    
    init(url: URL) throws {
        print(url)
        self.player = try AVAudioPlayer(contentsOf: url)
        super.init()
        self.player.delegate = self
    }
    
    static let queue = ConcurrentQueue(setup: { try AudioPlayer.activate() }, teardown: { try AudioPlayer.deactivate() })
    
    static func activate() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    static func deactivate() throws {
        try AVAudioSession.sharedInstance().setActive(false)
    }
    
    var isOnSpeaker: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.allSatisfy({ $0.portType == .builtInSpeaker })
    }
    
    func playOnQueue() async throws {
        try await Self.queue.add {
            await self.play()
        }
    }
    
    func play() async {
        self.playingTask?.cancel()
        self.playingTask = Task { [weak self] in
            self?.progressTask = Task.detached(priority: .utility) { [weak self] in
                await withTaskCancellationHandler(operation: {
                    while !Task.isCancelled {
                        guard let self else { return }
                        let progress = self.player.currentTime / self.player.duration
                        self.progress = progress
                        try? await Task.sleep(for: .milliseconds(16))
                    }
                }, onCancel: { [weak self] in
                    self?.progress = 0
                })
            }
            await withTaskCancellationHandler {
                self?.isPlaying = true
                await withCheckedContinuation { continuation in
                    self?.continuation = continuation
                    self?.player.play()
                }
                self?.isPlaying = false
            } onCancel: { [weak self] in
                if self?.player.isPlaying ?? false {
                    self?.player.stop()
                    self?.player.currentTime = 0
                }
                self?.isPlaying = false
            }
        }
  
        await self.playingTask?.value
    }
    
    func stop() {
        self.playingTask?.cancel()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.continuation?.resume()
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
