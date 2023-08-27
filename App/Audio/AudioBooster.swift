//
//  AudioBooster.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 26.07.23.
//

import Foundation
import AVFoundation

class AudioBooster {

    static func normalizeAudioAndWriteToURL(audioURL: URL) async throws {
        
        let asset = AVAsset(url: audioURL)
        let track = try await asset.loadTracks(withMediaType: AVMediaType.audio).first!
        
        let reader = try AVAssetReader(asset: asset)
        
        let readSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: readSettings)
        reader.add(output)
        
        reader.startReading()
        
        var maxAmplitude: Float = 0
        
        while reader.status == .reading {
            if let buffer = output.copyNextSampleBuffer(),
               let blockBuffer = CMSampleBufferGetDataBuffer(buffer) {
                
//                var length = 0
//                var dataPointer: UnsafeMutablePointer<Int8>?
//                CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: nil, dataPointerOut: &dataPointer)
//                
//                let samples = UnsafeMutableRawPointer(dataPointer!).assumingMemoryBound(to: Int16.self)
//                let sampleCount = length / 2
//                
//                for i in 0..<sampleCount {
//                    let sample = Int16(bigEndian: samples[i])
//                    maxAmplitude = max(maxAmplitude, abs(max(sample, -Int16.max)))
//                }
                
                let length = CMBlockBufferGetDataLength(blockBuffer)
                let sampleBytes = UnsafeMutablePointer<Int16>.allocate(capacity: length)
                defer { sampleBytes.deallocate() }
                
                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: sampleBytes)
                
                (0..<length).forEach { index in
                    let ptr = sampleBytes + index
                    let amplitude = Float(ptr.pointee)
                    maxAmplitude = max(maxAmplitude, abs(amplitude))
                }
                
                CMSampleBufferInvalidate(buffer)
            }
        }
        
        // Now we have maxAmplitude

        guard reader.status == .completed else { return }
        reader.cancelReading()
        
        // Calculate the scale
        let scale = min(Float(Int16.max) / maxAmplitude, 1)
        
        // Now initialize and configure writer
        let writer = try AVAssetWriter(outputURL: audioURL, fileType: .wav)
        
        let writeSettings: [String : Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: writeSettings)
        writer.add(input)
        
        // Now read file another time to adjust samples
        let readerForNormalize = try AVAssetReader(asset: asset)
        let outputForNormalize = AVAssetReaderTrackOutput(track: track, outputSettings: readSettings)
        readerForNormalize.add(outputForNormalize)
        
        readerForNormalize.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        
        await withCheckedContinuation { continuation in
            let processingQueue = DispatchQueue(label: "processingQueue")
            
            input.requestMediaDataWhenReady(on: processingQueue) {
                while input.isReadyForMoreMediaData {
                    if let nextBuffer = outputForNormalize.copyNextSampleBuffer(),
                       let blockBuffer = CMSampleBufferGetDataBuffer(nextBuffer) {
                        
                        var length = 0
                        var dataPointer: UnsafeMutablePointer<Int8>?
                        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
                        
                        let samples = UnsafeMutableRawPointer(dataPointer!).assumingMemoryBound(to: Int16.self)
                        let sampleCount = length / 2
                        
                        for i in 0..<sampleCount {
                            let sample = Int16(bigEndian: samples[i])
                            let normalizedSample = Int16(Float(sample) * scale)
                            samples[i] = normalizedSample.bigEndian
                        }
                        
                        input.append(nextBuffer)
                    } else if readerForNormalize.status == .completed {
                        input.markAsFinished()
                        writer.finishWriting {}
                        readerForNormalize.cancelReading()
                        continuation.resume()
                        break
                    }
                }
            }
        }
    }

}
