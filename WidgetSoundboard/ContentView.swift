//
//  ContentView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
//

import SwiftUI
import SwiftData
import WidgetKit
import Defaults

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Default(.sounds) var sounds: [Sound]
    
    @Environment(\.scenePhase) var scenePhase
    
    @State var showAddSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sounds) { sound in
                    LabeledContent(content: {
                        Button(intent: SoundIntent(sound: .init(sound: sound))) {
                            Image(systemName: "speaker.wave.3.fill")
                        }
                    }, label: {
                        Text("\(sound.symbol) \(sound.title)")
                    })
                }
                .onDelete(perform: { self.sounds.remove(atOffsets: $0) })
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        self.showAddSheet = true
                    }) {
                        Label("Add Sound", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
        .onAppear {
            print(Defaults[.sounds].map(\.id))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .sheet(isPresented: $showAddSheet, content: {
            AddSoundView()
        })
    }
}

struct AddSoundView: View {
    @State var title: String = ""
    @State var symbol: String = ""
    @State var file: URL?
    @State var color: Color = .red
    
    @State var isImporting: Bool = false
    
    @State var id: UUID = .init()
    
    @Environment(\.dismiss) var dismiss
    
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
                        Defaults[.sounds].append(.init(title: title, symbol: symbol, color: color, url: file))
                        dismiss()
                    }) {
                        Label("Add Sound", systemImage: "plus")
                    }
                }
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

#Preview {
    ContentView()
}
