//
//  BoardView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI
import Defaults
import SwiftUIReorderableForEach

struct BoardView: View {
    @Default(.sounds) var sounds: [Sound]
    @Default(.boards) var boards: [Board]

    @State var showCreateSheet = false
    @State var showAddSheet = false

    @State var editingSound: Sound?

    @State var showBoardEdit = false
    @State var showDeleteAlert = false
    @State var showErrorAlert = false
    @State private var showImporter = false
    @State private var playbackError: PlaybackError?

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

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: minimumWidth), spacing: 16)
            ], spacing: 16) {
                ReorderableForEach(soundsBinding, allowReordering: .constant(true)) {
                    sound,
                    isDragging in
                    SoundButton(sound: sound,
                                isEditing: $editingSound.equals(sound),
                                boardID: boardID)
                    .opacity(isDragging ? 0.5 : 1)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
        .overlay {
            if soundsBinding.wrappedValue.isEmpty {
                ContentUnavailableView("No Sounds",
                                       systemImage: "bell.slash.fill",
                                       description: Text("This board is empty. Try adding some sounds."))
            }
        }
        .toolbar {
            ToolbarItem {
                if self.boardID != Board.allID {
                    Menu(content: {
                        Button(action: {
                            self.showCreateSheet = true
                        }) {
                            Label("New Sound", systemImage: "plus.circle.fill")
                        }
                        Button(action: {
                            self.showAddSheet = true
                        }) {
                            Label("Add Existing Sound", systemImage: "doc.on.doc.fill")
                        }
                        Button(action: {
                            showImporter = true
                        }) {
                            Label("Import Sound", systemImage: "square.and.arrow.down.fill")
                        }
                    }, label: {
                        Label("Add Sound", systemImage: "plus")
                    })
                } else {
                    Button(action: {
                        self.showCreateSheet = true
                    }) {
                        Label("New Sound", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet, content: {
            EditorView(boardID: self.boardID)
        })
        .sheet(isPresented: $showAddSheet, content: {
            AddSoundView(boardID: self.boardID)
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
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.mp3],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if !gotAccess { return }

                    if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

                        FileManager.default.deleteIfExists(at: destinationURL)

                        do {
                            try FileManager.default.copyItem(at: url, to: destinationURL)

                            let newSound = Sound(id: UUID(), title: "Imported Sound", symbol: "🚦", color: .orange, url: destinationURL)
                            Defaults[.sounds].upsert(newSound, by: \.id)

                            if let boardID = self.board?.id, var board = Defaults[.boards].first(where: { $0.id == boardID }) {
                                board.sounds.append(newSound.id)
                                Defaults[.boards].upsert(board, by: \.id)
                            }
                        } catch {
                            self.playbackError = .importFailed
                            showErrorAlert = true
                        }

                        url.stopAccessingSecurityScopedResource()
                    } else {
                        self.playbackError = .documentsDirectoryNotFound
                        showErrorAlert = true
                    }
                }
            case .failure:
                self.playbackError = .importFailed
                showErrorAlert = true
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
                    self.showDeleteAlert = true
                }) {
                    Label("Delete Board", systemImage: "trash")
                }
            })
        }
        .alert("There was an error",
               isPresented: $showErrorAlert,
               actions: {
            Button("OK") { }
        }, message: {
            Text(self.playbackError?.errorDescription ?? "")
        })
        .alert("Do you also want to delete the sounds in this board?",
               isPresented: $showDeleteAlert,
               actions: {
            Button(role: .destructive, action: {
                self.board?.delete(from: &self.boards, with: &self.sounds, includeSounds: false)
            }) {
                Text("Just Board")
            }

            Button(role: .destructive, action: {
                self.board?.delete(from: &self.boards, with: &self.sounds, includeSounds: true)
            }) {
                Text("Board & Sounds")
            }

            Button(role: .cancel, action: { }) {
                Text("Cancel")
            }
        }, message: {
            Text("Only sounds, which are not used in any other boards will be deleted.")
        })
        .navigationTitle(Text("\(board?.symbol ?? "") \(board?.title ?? "")"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension FileManager {
    func deleteIfExists(at url: URL) {
        if self.fileExists(atPath: url.path) {
            try? self.removeItem(at: url)
        }
    }
}

#Preview {
    NavigationStack {
        BoardView(boardID: Board.allID)
    }
}
