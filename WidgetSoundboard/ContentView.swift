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
import SwiftUIReorderableForEach

struct ContentView: View {
    @Default(.sounds) var sounds: [Sound]
    
    @Environment(\.scenePhase) var scenePhase
    
    @State var showAddSheet = false
    
    @State var editingSound: Sound?
    

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 16)
                ], spacing: 16) {
                    ReorderableForEach($sounds, allowReordering: .constant(true)) {
                        sound,
                        isDragging in
                        SoundButton(sound: sound,
                                    isEditing: $editingSound.equals(sound),
                                    delete: {
                            self.sounds.removeAll(where: {
                                $0 == sound
                            })
                        })
                        .opacity(isDragging ? 0.5 : 1)
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.showAddSheet = true
                    }) {
                        Label("Add Sound", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(Text("Sounds"))
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

struct SoundButton: View {

    var sound: Sound

    @Binding var isEditing: Bool

    var delete: () -> Void

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 100

    @State private var player: AudioPlayer?

    var body: some View {
        Button(action: {
            let audioPlayer = try! self.player ?? AudioPlayer(url: sound.url)
            self.player = audioPlayer
            if audioPlayer.player.isPlaying {
                audioPlayer.stop()
            } else {
                Task {
                    await audioPlayer.play()
                }
            }
        }) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    Text(sound.symbol)
                        .font(.largeTitle)
                    Spacer()
                }

                Spacer()

                HStack {
                    Text(sound.title)
                    Spacer()
                    Image(systemName: "speaker.wave.3.fill")
                        .symbolEffect(.variableColor
                            .cumulative
                            .nonReversing,
                                      options: .repeating,
                                      isActive: self.player?.isPlaying ?? false)
                        .opacity(self.player?.isPlaying ?? false ? 1 : 0)
                }
                .lineLimit(1)
                .font(.headline)
                .bold()
            }
            .padding(4)
            .padding(.bottom, 4)
            .frame(height: itemSize)
        }
        .overlay {
            Menu(content: {
                Button(role: .destructive, action: self.delete) {
                    Label("Delete", systemImage: "trash")
                }
            }, label: {
                Image(systemName: "ellipsis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.large)
                    .font(.headline)
            }, primaryAction: {
                self.isEditing = true
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(12)
        }
        .buttonBorderShape(.roundedRectangle)
        .buttonStyle(.bordered)
        .tint(sound.color)
        .animation(.default, value: self.player?.isPlaying ?? false)
    }
}

#Preview {
    ContentView()
}
