//
//  EditorView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.06.23.
//

import SwiftUI
import Defaults

struct EditorView: View {
    @State var title: String
    @State var symbol: String
    @State var file: URL?
    @State var color: Color = .red
    
    @State var isImporting: Bool = false
    
    @State var id: UUID = .init()
    
    @State var isExisting = false
    
    @Environment(\.dismiss) var dismiss
    
    init(title: String = "",
         symbol: String = "",
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
    
    var body: some View {
        Form {
            Section {
                TextField("Emoji", text: $symbol)
                    .onChange(of: symbol) { oldValue, newValue in
                        if oldValue != newValue && newValue.count > 1 {
                            self.symbol = String(newValue.last!)
                        }
                    }
                
                TextField("Title", text: $title)
                
                ColorPicker("Color", selection: $color)
            }
            
            Section {
                importButton
                
                if let file {
                    AsyncButton("Play Sound") {
                        let player = try AudioPlayer(url: file)
                        try player.activate()
                        await player.play()
                        try player.deactivate()
                        
                    }
                }
            }
            
            if let file {
                Section {
                    Button(action: {
                        let sound = Sound(id: self.id,
                                          title: title,
                                          symbol: symbol,
                                          color: color,
                                          url: file)
                        if let index = Defaults[.sounds].firstIndex(where: { $0.id == self.id }) {
                            Defaults[.sounds][index] = sound
                        } else {
                            Defaults[.sounds].append(sound)
                        }
                        dismiss()
                    }) {
                        Group {
                            if self.isExisting {
                                Text("Update Sound")
                            } else {
                                Text("Add Sound")
                            }
                        }
                        .aligned(to: .horizontal)
                    }
                    .foregroundStyle(.background)
                    .font(.headline)
                }
                .listRowBackground(Color.accentColor)
            }
        
        }
    }
    
    var importButton: some View {
        Button(action: {
            isImporting = true
        }) {
            if self.file == nil {
                Text("Import Sound")
            } else {
                Text("Replace Sound")
            }
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
                        .appending(component: self.id.uuidString)
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
    }
}


//#Preview("Edit") {
//    EditorView(
//        sound: .init(
//            id: .init(uuidString: "3D82D8A0-9BA6-4014-B49D-393EB5989CDC")!,
//            title: "Test123",
//            symbol: "🚦",
//            color: .red,
//            url: Bundle.main.url(
//                    forResource: "wait",
//                    withExtension: "m4a"
//                )!
//        )
//    )
//}
//
//#Preview("New") {
//    EditorView()
//}
