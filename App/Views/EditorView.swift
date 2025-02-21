//
//  EditorView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.06.23.
//

import SwiftUI
import Defaults
import MCEmojiPicker
import PhotosUI

struct EditorView: View {
    @State var title: String
    @State var symbol: String
    @State var file: URL?
    @State var color: Color = .red
    
    @State var isImporting: Bool = false
    @State var isEmojiPickerPresent: Bool = false
    
    @State var id: UUID = .init()
    
    @State var isExisting = false

    var boardID: UUID?

    @State var waveform: [Float] = []
    @State var audioPlayer: AudioPlayer?

    @State var photoItem: PhotosPickerItem?

    @Environment(\.dismiss) var dismiss
    
    init(title: String = "",
         symbol: String = "🚦",
         file: URL? = nil,
         color: Color? = nil,
         id: UUID = .init(),
         isExisting: Bool = false,
         boardID: UUID? = nil) {
        self._title = State(initialValue: title)
        self._symbol = State(initialValue: symbol)
        self._file = State(initialValue: file)
        if let color {
            self._color = State(initialValue: color)
        } else if let boardID, let board = Defaults[.boards].first(where: { $0.id == boardID }) {
            self._color = State(initialValue: board.color)
        } else {
            self._color = State(initialValue: .red)
        }
        self._id = State(initialValue: id)
        self._isExisting = State(initialValue: isExisting)
        self.boardID = boardID
    }
    
    init(sound: Sound, boardID: UUID? = nil) {
        self.init(title: sound.title,
                  symbol: sound.symbol,
                  file: sound.url,
                  color: sound.color,
                  id: sound.id,
                  isExisting: true,
                  boardID: boardID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(action: {
                            self.isEmojiPickerPresent = true
                        }) {
                            Text(symbol)
                                .padding(4)
                                .font(.title2)
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .tint(self.color)
                        .emojiPicker(
                            isPresented: $isEmojiPickerPresent,
                            selectedEmoji: $symbol
                        )
                        
                        TextField("Title", text: $title)
                            .font(.title3.weight(.semibold))
                    }
                    
                    ColorRow(selected: $color, colors: ColorPalette.colors)
                        .padding(6)
                }
                
                Section {
                    if let url = self.file {
                        WaveformView(samples: self.waveform, progress: self.audioPlayer?.progress ?? 0)
                            .frame(height: 50)
                            .padding(.vertical, 8)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        HStack {
                            VStack(alignment: .center, spacing: 8) {
                                Button(action: {
                                    let audioPlayer = try! self.audioPlayer ?? AudioPlayer(url: url)
                                    self.audioPlayer = audioPlayer
                                    if audioPlayer.isPlaying {
                                        audioPlayer.stop()
                                    } else {
                                        Task {
                                            try await audioPlayer.playOnQueue()
                                        }
                                    }
                                }) {
                                    Image(systemName: self.audioPlayer?.isPlaying ?? false ? "pause.fill" : "play.fill")
                                        .contentTransition(.symbolEffect)
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text(self.audioPlayer?.isPlaying ?? false ? "Pause" : "Play")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .tint(.blue)
                            
                            /*
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 8) {
                                AsyncButton(action: {
                                    try await AudioBooster.normalizeAudioAndWriteToURL(audioURL: url)
                                }) {
                                    Image(systemName: "timeline.selection")
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text("Trim")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .tint(.yellow)
                            .disabled(true)
                            */

                            Spacer()
                            
                            VStack(alignment: .center, spacing: 8) {
                                Button(action: {
                                    self.audioPlayer = nil
                                    self.file = nil
                                }) {
                                    Image(systemName: "trash.fill")
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text("Discard")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .tint(.red)
                            
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .animation(.default, value: self.audioPlayer?.isPlaying ?? false)
                    } else {
                        HStack {
                            RecorderButton(recoder: .init(id: self.id, url: $file))
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 8) {
                                PhotosPicker(selection: $photoItem,
                                             matching: .videos) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text("Extract")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .tint(Color.green)
                            .onChange(of: self.photoItem) { _, item in
                                Task {
                                    if let item {
                                        guard let audio = try! await item.loadTransferable(type: VideoToAudio.self) else {
                                            return
                                        }
                                        let newPath = FileManager.default
                                            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
                                            .appending(component: "\(self.id.uuidString)_\(UUID().uuidString)")
                                            .appendingPathExtension("mp4")
                                        try! await audio.extract(to: newPath)
                                        self.file = newPath
                                    }
                                }
                            }

                            Spacer()
                            
                            VStack(alignment: .center, spacing: 8) {
                                Button(action: {
                                    self.isImporting = true
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text("Import")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .fileImporter(
                                isPresented: $isImporting,
                                allowedContentTypes: [.audio],
                                allowsMultipleSelection: false
                            ) { result in
                                switch result {
                                case .success(let urls):
                                    if let url = urls.first {
                                        guard url.startAccessingSecurityScopedResource() else {
                                            return
                                        }
                                        let newPath = FileManager.default
                                            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
                                            .appending(component: "\(self.id.uuidString)_\(UUID().uuidString)")
                                            .appendingPathExtension(url.pathExtension)
                                        do {
                                            try FileManager.default.removeItem(at: newPath)
                                        } catch { }
                                        try! FileManager.default.copyItem(at: url, to: newPath)
                                        url.stopAccessingSecurityScopedResource()
                                        self.file = newPath
                                    }
                                case .failure(let error):
                                    print("File Import Failed", error)
                                }
                            }
                            .tint(Color.blue)
                            
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                    }
                }
            }
            .animation(.default, value: self.waveform.isEmpty)
            .animation(.default, value: self.file != nil)
            .onChange(of: self.file, initial: true) { _, url in
                if let url {
                    Task { @MainActor in
                        self.waveform = try! await WaveformAnalyzer(audioAssetURL: url)?.samples(count: 1000) ?? []
                    }
                } else {
                    self.waveform = []
                }
            }
            .navigationTitle(Text(self.isExisting ? "Update Sound" : "New Sound"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            // Toolbar was causing a bug when playing a sound.
            .navigationBarItems(leading: self.cancelButton,
                                trailing: self.doneButton)
        }
    }
    
    var cancelButton: some View {
        Button(action: {
            self.dismiss()
        }) {
            Text("Cancel")
        }
    }
    
    var doneButton: some View {
        Button(self.isExisting ? "Update" : "Create") {
            guard let file else {
                return
            }
            let sound = Sound(id: self.id,
                              title: self.title,
                              symbol: self.symbol,
                              color: self.color,
                              url: file)
            Defaults[.sounds].upsert(sound, by: \.id)
            if let boardID, var board = Defaults[.boards].first(where: { $0.id == boardID }) {
                board.sounds.append(self.id)
                Defaults[.boards].upsert(board, by: \.id)
            }
            self.dismiss()
            Defaults[.signals] += 1
        }
        .font(.headline)
        .disabled(self.file == nil || self.title.isEmpty)
    }
}

struct VideoToAudio: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let copy = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
                .appending(component: "\(UUID().uuidString)")
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
        FileRepresentation(importedContentType: .mpeg4Movie) { received in
            print(received)
            let copy = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.io.unorderly.soundboard")!
                .appending(component: "\(UUID().uuidString)")
                .appendingPathExtension("mp4")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }

    func extract(to outputUrl: URL) async throws {
        let asset = AVAsset(url: self.url)
        let composition = AVMutableComposition()
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)


        guard !audioTracks.isEmpty else {
            throw "No tracks"
        }

        for track in audioTracks {
            let timeRange = try await track.load(.timeRange)
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            try compositionTrack.insertTimeRange(timeRange, of: track, at: .zero)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw "No export session"
        }

        let tempURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: UUID().uuidString).appendingPathExtension("m4a")
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .m4a
        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        try FileManager.default.moveItem(at: tempURL, to: outputUrl)
        try FileManager.default.removeItem(at: self.url)
    }
}

extension String: Error {

}
#Preview("Edit") {
    EditorView(
        sound: .init(
            id: .init(uuidString: "3D82D8A0-9BA6-4014-B49D-393EB5989CDC")!,
            title: "Test123",
            symbol: "🚦",
            color: .red,
            url: Bundle.main.url(
                forResource: "wait",
                withExtension: "m4a"
            )!
        )
    )
}

#Preview("New") {
    EditorView()
}
