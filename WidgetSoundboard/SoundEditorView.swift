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
struct SoundEditorView: View {
    
    @State
    var recorder: AudioRecorder
    
    var body: some View {
        AsyncButton(recorder.isRecording ? "Stop Recording" : "Record Sound",
                    action: {
            await recorder.record()
        })
    }
}

struct AudioWaveView: View {
    let samples: [Float]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let middleY = geometry.size.height / 2
                path.move(to: CGPoint(x: 0, y: middleY))
                
                for i in samples.indices {
                    let sample = samples[i]
                    let height = Double(geometry.size.height) * Double(sample)
                    let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: height))
                    path.addRect(rect.offsetBy(dx: CGFloat(i), dy: middleY - CGFloat(height / 2)))
                }
            }
            .stroke(Color.blue, lineWidth: 1)
        }
    }
}

@Observable
class AudioRecorder: NSObject {
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    
    var isRecording = false
    
    var soundSamples: [Float] = []
    
    @Binding @ObservationIgnored
    var url: URL?
    
    @Binding @ObservationIgnored
    var audioLevel: Double
    
    var id: UUID
    
    init(id: UUID, url: Binding<URL?>, audioLevel: Binding<Double>) {
        self._url = url
        self._audioLevel = audioLevel
        self.id = id
        super.init()
    }
    
    func fetchAudioSamples(url: URL) -> [Float] {
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
            .appending(component: self.id.uuidString)
            .appendingPathExtension("m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
        } catch {
            print("Could not set up audio recorder: \(error)")
        }
    }
    
    var levelTask: Task<Void, Never>?
       
    func record() async {
        if self.isRecording {
            self.audioRecorder.stop()
            self.isRecording = false
            self.levelTask?.cancel()
        } else {
            self.setupRecorder()
            await AVAudioApplication.requestRecordPermission()
            self.audioRecorder.record()
            self.isRecording = true
            self.levelTask = Task.detached(priority: .utility) {
                await withTaskCancellationHandler(operation: {
                    while !Task.isCancelled {
                        self.audioRecorder.updateMeters()
                        let level = self.audioRecorder.averagePower(forChannel: 0)
                        await MainActor.run {
                            self.audioLevel = Double(level) / 160 + 1
                            print(self.audioLevel)
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
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.isRecording = false
        self.levelTask?.cancel()
        if flag {
            self.url = recorder.url
            self.soundSamples = self.fetchAudioSamples(url: recorder.url)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error)
    }
}


#Preview {
    SoundEditorView(recorder: .init(id: .init(), url: .constant(nil), audioLevel: .constant(0)))
}
