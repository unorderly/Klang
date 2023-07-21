import SwiftUI
import AVFoundation
import Accelerate

enum RecorderState {
    case recording
    case stopped
    case denied
}

protocol RecorderViewControllerDelegate: AnyObject {
    func didStartRecording()
    func didFinishRecording()
}

let keyID = "key"
struct RecordingView: View {
    
    //MARK:- Properties
    var settings: [String : Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: true,
            AVSampleRateKey: Float64(44100),
            AVNumberOfChannelsKey: 1
        ]
    }
    @State var audioEngine = AVAudioEngine()
    @State private var renderTs: Double = 0
    @State private var recordingTs: Double = 0
    @State private var silenceTs: Double = 0
    @State private var audioFile: AVAudioFile?
    
    @State private var isRecording = false
    @State private var timeText = "00.00"
    @State private var waveforms = [Float](repeating: 0, count: 50)
    @State private var active = false
    
    @State private var timeRecorded: Duration = .seconds(0)
    
    @Binding var url: URL?
    
    var body: some View {
        
        Text("\(timeRecorded, format: .time(pattern: .minuteSecond))")
        AsyncButton(self.isRecording ? "Stop" : "Start", action: handleRecording)
//        AudioVisualizerView(active: self.active, waveforms: waveforms)
        AudioWaveView(samples: self.waveforms)
    }
    
    //MARK:- Actions
    func handleRecording() async {
        if !isRecording {
            await startRecording()
        } else {
            stopRecording()
        }
        isRecording.toggle()
    }
    
    //MARK:- Update User Interface
    private func updateUI(_ recorderState: RecorderState) {
        switch recorderState {
        case .recording:
            DispatchQueue.main.async {
                self.active = true
            }
        case .stopped:
            DispatchQueue.main.async {
                self.active = false
                self.timeRecorded = .seconds(0)
            }
        case .denied:
            DispatchQueue.main.async {
                self.active = false
                self.timeRecorded = .seconds(0)
            }
        }
    }
    
    // MARK:- Recording
    private func startRecording() async {
        
        self.recordingTs = NSDate().timeIntervalSince1970
        self.silenceTs = 0
        
        guard await AVAudioApplication.requestRecordPermission() else {
            return
        }
        
        do {
            
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            try session.setPreferredSampleRate(44100)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        
        let inputNode = self.audioEngine.inputNode
        let outputFormat = AVAudioFormat(settings: settings)!
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)!

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (_buffer, time) in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    
                    return _buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            
            let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                          frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * _buffer.frameLength / AVAudioFrameCount(_buffer.format.sampleRate))!
            
            var error: NSError?
            let status = converter.convert(to: buffer, error: &error, withInputFrom: inputCallback)
 
            
            let level: Float = -50
            let length: UInt32 = 1024
            buffer.frameLength = length
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
            var value: Float = 0
            vDSP_meamgv(channels[0], 1, &value, vDSP_Length(length))
            var average: Float = ((value == 0) ? -100 : 20.0 * log10f(value))
            if average > 0 {
                average = 0
            } else if average < -100 {
                average = -100
            }
            let silent = average < level
            let ts = NSDate().timeIntervalSince1970
            if ts - self.renderTs > 0.1 {
                let floats = UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength))
                let frame = floats.map({ (f) -> Int in
                    return Int(f * Float(Int16.max))
                })
                DispatchQueue.main.async {
                    let seconds = (ts - self.recordingTs)
                    self.timeRecorded = .seconds(seconds)
                    self.renderTs = ts
                    let len = self.waveforms.count
                    for i in 0 ..< len {
                        let idx = ((frame.count - 1) * i) / len
                        let f: Float = sqrt(1.5 * abs(Float(frame[idx])) / Float(Int16.max))
                        self.waveforms[i] = f
                    }
                    self.active = !silent
                }
            }
            
            let write = true
            if write {
                if self.audioFile == nil {
                    self.audioFile = self.createAudioRecordFile()
                }
                if let f = self.audioFile {
                    do {
                        try f.write(from: buffer)
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        do {
            self.audioEngine.prepare()
            try self.audioEngine.start()
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        self.updateUI(.recording)
    }
    
    private func stopRecording() {
        self.audioFile = nil
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.audioEngine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch  let error as NSError {
            print(error.localizedDescription)
            return
        }
        self.updateUI(.stopped)
    }
    
    // MARK:- Paths and files
    private func createAudioRecordPath() -> URL? {
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss-SSS"
        let currentFileName = "recording-\(format.string(from: Date()))" + ".wav"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(currentFileName)
        return url
    }
    
    private func createAudioRecordFile() -> AVAudioFile? {
        guard let path = self.createAudioRecordPath() else {
            return nil
        }
        self.url = path
        do {
            let file = try AVAudioFile(forWriting: path, settings: self.settings, commonFormat: .pcmFormatFloat32, interleaved: true)
            return file
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
}

struct AudioVisualizerView: View {
    
    // Bar width
    @State
    var barWidth: CGFloat = 4.0
    // Indicates if the visualization is active or inactive
    var active: Bool
    
    // Given waveforms
    var waveforms: [Int]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let w = geometry.size.width
                let h = geometry.size.height
                let t = Int(w / self.barWidth)
                let s = max(0, self.waveforms.count - t)
                let m = h / 2
                let r = self.barWidth / 2
                let x = m - r
                
                var bar: CGFloat = 0
                for i in s ..< self.waveforms.count {
                    var v = h * CGFloat(self.waveforms[i]) / 50.0
                    if v > x {
                        v = x
                    }
                    else if v < 3 {
                        v = 3
                    }
                    let oneX = bar * self.barWidth
                    var oneY: CGFloat = 0
                    let twoX = oneX + r
                    var twoY: CGFloat = 0
                    var twoS: CGFloat = 0
                    var twoE: CGFloat = 0
                    var twoC: Bool = false
                    let threeX = twoX + r
                    let threeY = m
                    if i % 2 == 1 {
                        oneY = m - v
                        twoY = m - v
                        twoS = -180.degreesToRadians
                        twoE = 0.degreesToRadians
                        twoC = false
                    }
                    else {
                        oneY = m + v
                        twoY = m + v
                        twoS = 180.degreesToRadians
                        twoE = 0.degreesToRadians
                        twoC = true
                    }
                    path.move(to: CGPoint(x: oneX, y: m))
                    path.addLine(to: CGPoint(x: oneX, y: oneY))
                    path.addArc(center: CGPoint(x: twoX, y: twoY),
                                radius: r,
                                startAngle: .radians(twoS),
                                endAngle: .radians(twoE),
                                clockwise: twoC)
                    path.addLine(to: CGPoint(x: threeX, y: threeY))
                    bar += 1
                }
            }
            
            .stroke(active ? Color.red : Color.gray, lineWidth: 1)
        }
        .background(Color.clear)
        
    }
}

extension Int {
    var degreesToRadians: CGFloat {
        return CGFloat(self) * .pi / 180.0
    }
}

struct RecordButton: View {
    @State private var scale: CGFloat = 1.0
    @State private var startPlayer: AVAudioPlayer?
    @State private var stopPlayer: AVAudioPlayer?
    
    @State var playSounds = true
    var frameColor : Color = Color.red
    @State var isRecording : Bool = false  {
        didSet {
            let animation = Animation.linear(duration: 0.5)
            withAnimation(animation) {
                self.scale = self.isRecording ? 0.0 : 1.0
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if self.playSounds {
                if self.isRecording {
                    self.stopPlayer?.play()
                }
                else {
                    self.startPlayer?.play()
                }
            }
            self.isRecording.toggle()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: scale * 50, style: .continuous)
                    .fill(frameColor)
                Circle()
                    .fill(frameColor)
                    .scaleEffect(scale)
            }
            .frame(width: 100, height: 100)
        }
        .onAppear {
            let startURL = Bundle.main.url(forResource: "StartRecording", withExtension: "aiff")!
            let stopURL = Bundle.main.url(forResource: "StopRecording", withExtension: "aiff")!
            self.startPlayer = try? AVAudioPlayer(contentsOf: startURL)
            self.startPlayer?.prepareToPlay()
            self.stopPlayer = try? AVAudioPlayer(contentsOf: stopURL)
            self.stopPlayer?.prepareToPlay()
        }
    }
}


#Preview {
    RecordingView(url: .constant(nil))
}
