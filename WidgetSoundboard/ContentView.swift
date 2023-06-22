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
    
    @State var editingSound: Sound?
    var body: some View {
        NavigationView {
            List {
                ForEach(sounds) { sound in
                    Button(action: {
                        self.editingSound = sound
                    }) {
                        LabeledContent(content: {
                            Button(intent: SoundIntent(sound: .init(sound: sound), isFullBlast: false)) {
                                Image(systemName: "speaker.wave.3.fill")
                            }
                        }, label: {
                            Text("\(sound.symbol) \t\(sound.title)")
                                .foregroundStyle(Color.primary)
                        })
                    }
                }
                .onDelete { self.sounds.remove(atOffsets: $0) }
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
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .sheet(isPresented: $showAddSheet, content: {
            EditorView()
        })
        .sheet(item: $editingSound) { sound in
            EditorView(sound: sound)
        }
    }
}


//#Preview {
//    ContentView()
//}
