//
//  EditorView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.06.23.
//

import SwiftUI
import Defaults
import MCEmojiPicker


struct EditorView: View {
    @State var title: String
    @State var symbol: String
    @State var file: URL?
    @State var color: Color = .red
    
    @State var isImporting: Bool = false
    @State var isEmojiPickerPresent: Bool = false
    
    
    @State var id: UUID = .init()
    
    @State var isExisting = false
    
    @State var waveform: [Float] = []
    @State var audioPlayer: AudioPlayer?
    
    @Environment(\.dismiss) var dismiss
    
    init(title: String = "",
         symbol: String = "🚦",
         file: URL? = nil,
         color: Color = .red,
         id: UUID = .init(),
         isExisting: Bool = false) {
        self._title = State(initialValue: title)
        self._symbol = State(initialValue: symbol)
        self._file = State(initialValue: file)
        self._color = State(initialValue: color)
        self._id = State(initialValue: id)
        self._isExisting = State(initialValue: isExisting)
    }
    
    init(sound: Sound) {
        self.init(title: sound.title,
                  symbol: sound.symbol,
                  file: sound.url,
                  color: sound.color,
                  id: sound.id,
                  isExisting: true)
    }
    
    var presetColors: [Color] {
        [.red, .blue, .green, .indigo, .mint, .orange, .pink, .purple, .teal, .yellow]
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
                    }
                    
                    ColorRow(selected: $color, colors: self.presetColors)
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
                                    if audioPlayer.player.isPlaying {
                                        audioPlayer.stop()
                                    } else {
                                        Task {
                                            await audioPlayer.play()
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
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 8) {
                                Button(action: {
                                    
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
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "link")
                                        .imageScale(.large)
                                        .padding(8)
                                        .font(.headline)
                                }
                                
                                Text("Download")
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .tint(Color.green)
                            .disabled(true)
                            
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
            if let index = Defaults[.sounds].firstIndex(where: { $0.id == self.id }) {
                Defaults[.sounds][index] = sound
            } else {
                Defaults[.sounds].append(sound)
            }
            self.dismiss()
        }
        .font(.headline)
        .disabled(self.file == nil || self.title.isEmpty)
    }
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
