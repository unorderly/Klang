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
    @Default(.boards) var boards: [Board]

    var allBoard: Board {
        Board.allBoard(with: sounds)
    }

    @Environment(\.scenePhase) var scenePhase
    

    @State var selectedBoard: Board?
    @State var showAddSheet = false

    @State var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn, sidebar: {
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 16)
                ], spacing: 16) {
                    BoardButton(board: self.allBoard, selected: $selectedBoard)
                    ReorderableForEach($boards, allowReordering: .constant(true)) {
                        board,
                        isDragging in
                       BoardButton(board: board, selected: $selectedBoard)
                        .opacity(isDragging ? 0.5 : 1)
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding()
            }
            .navigationDestination(item: $selectedBoard) { board in
                BoardView(boardID: board.id)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.showAddSheet = true
                    }) {
                        Label("Add Board", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet, content: {
                BoardEditor()
            })
            .navigationTitle(Text("Boards"))
        }, detail: {
            Text("Select a board")
        })
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }

    }
}

struct BoardView: View {
    @Default(.sounds) var sounds: [Sound]
    @Default(.boards) var boards: [Board]

    @State var showAddSheet = false

    @State var editingSound: Sound?

    @State var showBoardEdit = false

    @Environment(\.dismiss) var dismiss

    var boardID: UUID

    var board: Board? {
        if boardID == Board.allID {
            return Board.allBoard(with: sounds)
        } else {
            return self.boards.first(where: { $0.id == boardID })
        }
    }

    var soundsBinding: Binding<[Sound]> {
        Binding(get: {
            board?.sounds.compactMap({ id in sounds.first(where: { $0.id == id }) }) ?? []
        }, set: { sounds in
            if let board = board {
                self.boards.upsert(board.set(\.sounds, to: sounds.map(\.id)), by: \.id)
            }
        })
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 16)
            ], spacing: 16) {
                ReorderableForEach(soundsBinding, allowReordering: .constant(true)) {
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
        .sheet(isPresented: $showAddSheet, content: {
            EditorView(boardID: self.boardID)
        })
        .sheet(isPresented: $showBoardEdit, content: {
            if let board {
                BoardEditor(board: board)
            }
        })
        .sheet(item: $editingSound) { sound in
            EditorView(sound: sound)
        }
        .onChange(of: self.board != nil) { _, hasBoard in
            if !hasBoard {
                self.dismiss()
            }
        }
        .if(self.boardID != Board.allID) { content in
            content.toolbarTitleMenu(content: {
                Button(action: {
                    self.showBoardEdit = true
                }) {
                    Label("Edit Board", systemImage: "pencil")
                }

                Button(role: .destructive, action: {
                    self.boards.removeAll(where: { $0.id == self.boardID })
                }) {
                    Label("Delete Board", systemImage: "trash")
                }
            })
        }
        .navigationTitle(Text("\(board?.symbol ?? "") \(board?.title ?? "")"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Array {
    mutating func upsert<ID: Equatable>(_ element: Element, by id: (Element) -> ID) {
        let elementID = id(element)
        if let index = self.firstIndex(where: { id($0) == elementID }) {
            self[index] = element
        } else {
            self.append(element)
        }
    }
}

struct BoardButton: View {
    var board: Board

    @Binding var selected: Board?

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 100

    var body: some View {
        Button(action: { self.selected = self.board }) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    Text(board.symbol)
                        .font(.largeTitle)
                    Spacer()
                }

                Spacer()

                HStack {
                    Text(board.title)
                    Spacer()
                }
                .lineLimit(1)
                .font(.headline)
                .bold()
            }
            .padding(4)
            .padding(.bottom, 4)
            .frame(height: itemSize)
        }
        .buttonBorderShape(.roundedRectangle)
        .buttonStyle(.bordered)
        .tint(board.color)
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
