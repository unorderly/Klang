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
    
    @ScaledMetric(relativeTo: .title2) var itemSize: CGFloat = 100
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 16)
                ], spacing: 16) {
                    ReorderableForEach($sounds, allowReordering: .constant(true)) { sound, isDragging in
                        Button(intent: SoundIntent(sound: .init(sound: sound), isFullBlast: false)) {
                            VStack(spacing: 8) {
                                HStack(alignment: .top) {
                                    Text(sound.symbol)
                                        .font(.largeTitle)
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                Text(sound.title)
                                    .lineLimit(1)
                                    .font(.headline)
                                    .bold()
                                    .alignment(.leading)
                            }
                            .padding(4)
                            .padding(.bottom, 4)
                            .frame(height: itemSize)
                        }
                        .overlay {
                            Menu(content: {
                                Button(role: .destructive, action: {
                                    self.sounds.removeAll(where: { $0 == sound })
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }, label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .imageScale(.large)
                                    .font(.headline)
                            }, primaryAction: {
                                self.editingSound = sound
                            })
                            .menuStyle(.button)
                            .buttonStyle(.borderless)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(12)
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .buttonStyle(.bordered)
                        .tint(sound.color)
                        .opacity(isDragging ? 0.5 : 1)
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding()
//                .onDelete { self.sounds.remove(atOffsets: $0) }
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


#Preview {
    ContentView()
}
