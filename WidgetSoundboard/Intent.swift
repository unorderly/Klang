//
//  Intent.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
//

import AppIntents
import AVFoundation
import AudioToolbox
import WidgetKit
import MediaPlayer
import SwiftUI
import Defaults


struct SoundEntity: AppEntity, Identifiable, Hashable {

    static var defaultQuery: SoundQuery = SoundQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Sound")
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(self.symbol) \(self.title)")
    }
    
    var id: UUID
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "Symbol")
    var symbol: String

    @Property(title: "Color")
    var color: String
    
    @Property(title: "Sound")
    var file: IntentFile
    
    init(id: UUID, title: String, symbol: String, color: Color, url: URL) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color.hex()
        self.file = IntentFile(fileURL: url)
    }
    
    init(sound: Sound) {
        self.init(
            id: sound.id,
            title: sound.title,
            symbol: sound.symbol,
            color: sound.color,
            url: sound.url
        )
    }
    
    static func == (lhs: SoundEntity, rhs: SoundEntity) -> Bool {
        lhs.id == rhs.id
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

struct SoundQuery: EntityStringQuery {
    func entities(for identifiers: [SoundEntity.ID]) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ identifiers.contains($0.id) })
            .map({ SoundEntity(sound: $0) })
    }
    
    func entities(matching string: String) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ $0.title.contains(string) })
            .map({ SoundEntity(sound: $0) })
    }
    
    func suggestedEntities() async throws -> [SoundEntity] {
        Defaults[.sounds]
            .map({ SoundEntity(sound: $0) })
    }
}

actor ConcurrentQueue {
    var running: [UUID: Task<Void, Error>] = [:]
    var setup: () async throws -> Void
    var teardown: () async throws -> Void
    
    init(setup: @escaping () async throws -> Void, teardown: @escaping () async throws -> Void) {
        self.setup = setup
        self.teardown = teardown
    }
    nonisolated func add(_ task: @escaping () async throws -> Void) async throws {
        let uuid = UUID()
        let task = Task {
            try await task()
        }
        try await self.start(task: task, with: uuid)
        do {
            try await task.value
            try await self.endTask(with: uuid)
        } catch {
            try await self.endTask(with: uuid)
            throw error
        }
    }
    
    private func start(task: Task<Void, Error>, with uuid: UUID) async throws {
        if self.running.isEmpty {
            try await self.setup()
        }
        self.running[uuid] = task
    }
    
    private func endTask(with uuid: UUID) async throws {
        guard self.running[uuid] != nil else {
            return
        }
        self.running[uuid] = nil
        if self.running.isEmpty {
            try await self.teardown()
        }
    }
    
    func cancelAll() {
        self.running.values.forEach({ $0.cancel() })
        self.running.removeAll()
    }
}

struct SoundIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "Play Sound"
    
    static var description = IntentDescription("Plays a sound")
    
    @Parameter(title: "Sound")
    var sound: SoundEntity
    
    @Parameter(title: "Full Blast Mode")
    var isFullBlast: Bool
    
    init(sound: SoundEntity, isFullBlast: Bool) {
        self.sound = sound
        self.isFullBlast = isFullBlast
    }
    
    init() {
//        sound = "horse"
    }
    
    func perform() async throws -> some IntentResult {
        print("Start playing \(sound.title)")
        
        let player = try AudioPlayer(url: sound.file.fileURL!)
        
        print("Created sound for \(sound.title)")
        
        if self.isFullBlast && player.isOnSpeaker {
            await MPVolumeView.setVolume(1)
        }
        
        do {
            print("Playing sound \(sound.title)")
            try await player.playOnQueue()
            print("Sound \(sound.title) stopped")
        } catch {
            print("Playing Sound fauled error:", error.localizedDescription)
        }
        
        return .result()
    }
}


final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    let player: AVAudioPlayer
    private var continuation: CheckedContinuation<Void, Never>?
    
    init(url: URL) throws {
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
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.player.play()
        }
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
