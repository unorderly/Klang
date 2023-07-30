//
//  SoundEditorView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 21.07.23.
//

import SwiftUI

import SwiftUI
import Combine
import AVFoundation
import Observation


@Observable
class AudioRecorder: NSObject {
    
    var audioRecorder: AVAudioRecorder?
    
    var isRecording = false {
        didSet {
            if self.isRecording {
                if !(self.audioRecorder?.isRecording ?? false) {
                    Task {
                        await self.startRecording()
                    }
                }
            } else {
                if self.audioRecorder?.isRecording ?? false {
                    self.stopRecording()
                }
            }
        }
    }
    
    @Binding @ObservationIgnored
    var url: URL?
    
    var audioLevel: Double = 0
    
    var id: UUID
    
    init(id: UUID, url: Binding<URL?>) {
        self._url = url
        self.id = id
        super.init()
    }
    
    static func fetchAudioSamples(url: URL) -> [Float] {
        let audioFile = try! AVAudioFile(forReading: url)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: audioFile.fileFormat.sampleRate,
                                   channels: audioFile.fileFormat.channelCount,
                                   interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(audioFile.length))!
        try! audioFile.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData else { return [] }
        
        let channelDataValue = channelData.pointee
        let length = buffer.frameLength
        
        var samples = [Float]()
        for index in 0..<Int(length) {
            let sample = channelDataValue[index]
            samples.append(sample)
        }
        
        return samples
    }
    
    func setupRecorder() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session")
        }
        
        let audioFilename = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
            .appending(component: "\(self.id.uuidString)_\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
        } catch {
            print("Could not set up audio recorder: \(error)")
        }
    }
    
    var levelTask: Task<Void, Never>?
       
    func stopRecording() {
        self.audioRecorder?.stop()
        self.levelTask?.cancel()
    }
    
    func startRecording() async {
        self.setupRecorder()
        await AVAudioApplication.requestRecordPermission()
        self.audioRecorder?.record()
        self.levelTask = Task.detached(priority: .utility) {
            await withTaskCancellationHandler(operation: {
                while !Task.isCancelled {
                    self.audioRecorder?.updateMeters()
                    let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                    await MainActor.run {
                        self.audioLevel = Double(max(level + 50, 0)) / 50
                        print(level, self.audioLevel)
                    }
                    try? await Task.sleep(for: .milliseconds(16))
                }
            }, onCancel: {
                Task { @MainActor in
                    self.audioLevel = 0
                }
            })
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.isRecording = false
        self.levelTask?.cancel()
        if flag {
            self.url = recorder.url
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error)
    }
}
