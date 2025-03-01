//
//  BoardView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import Defaults
import SwiftUI
import SwiftUIReorderableForEach
import UIKit
import UniformTypeIdentifiers

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
    @State private var isExportingBoard = false
    @State private var exportURL: URL?

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
        .sheet(
            isPresented: $showCreateSheet,
            content: {
                EditorView(boardID: self.boardID)
            }
        )
        .sheet(
            isPresented: $showAddSheet,
            content: {
                AddSoundView(boardID: self.boardID)
            }
        )
        .sheet(
            isPresented: $showBoardEdit,
            content: {
                if let board {
                    BoardEditor(board: board)
                }
            }
        )
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

                    let documentsURL = FileManager.default.containerURL
                    let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

                    FileManager.default.deleteIfExists(at: destinationURL)

                    do {
                        guard url.startAccessingSecurityScopedResource() else { continue }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        url.stopAccessingSecurityScopedResource()

                        let newSound = Sound(id: UUID(),
                                             title: "Imported Sound",
                                             symbol: "🚦",
                                             color: Color.palette.randomElement()!,
                                             url: destinationURL)
                        Defaults[.sounds].upsert(newSound, by: \.id)

                        if let boardID = self.board?.id,
                           var board = Defaults[.boards].first(where: { $0.id == boardID })
                        {
                            board.sounds.append(newSound.id)
                            Defaults[.boards].upsert(board, by: \.id)
                        }
                    } catch {
                        self.playbackError = .importFailed
                        showErrorAlert = true
                    }

                }
            case .failure:
                self.playbackError = .importFailed
                showErrorAlert = true
            }
        }
        .fileMover(isPresented: $isExportingBoard,
                   file: exportURL,
                   onCompletion: { result in
            print("File moved: \(result)")
            if let exportURL {
                FileManager.default.deleteIfExists(at: exportURL)
            }
            if case .failure = result {
                self.playbackError = .exportFailed
                showErrorAlert = true
            }
        }, onCancellation: {
            print("Cancelled")
            if let exportURL {
                FileManager.default.deleteIfExists(at: exportURL)
            }
        })
        .if(self.boardID != Board.allID) { content in
            content.toolbarTitleMenu(content: {
                Button(action: {
                    self.showBoardEdit = true
                }) {
                    Label("Edit Board", systemImage: "pencil")
                }

                Button(action: {
                    exportBoard()
                }) {
                    Label("Export Board", systemImage: "square.and.arrow.up")
                }

                Button(
                    role: .destructive,
                    action: {
                        self.showDeleteAlert = true
                    }
                ) {
                    Label("Delete Board", systemImage: "trash")
                }
            })
        }
        .alert(
            "There was an error",
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {}
            },
            message: {
                Text(self.playbackError?.errorDescription ?? "")
            }
        )
        .alert(
            "Do you also want to delete the sounds in this board?",
            isPresented: $showDeleteAlert,
            actions: {
                Button(
                    role: .destructive,
                    action: {
                        self.board?.delete(from: &self.boards, with: &self.sounds, includeSounds: false)
                    }
                ) {
                    Text("Just Board")
                }

                Button(
                    role: .destructive,
                    action: {
                        self.board?.delete(from: &self.boards, with: &self.sounds, includeSounds: true)
                    }
                ) {
                    Text("Board & Sounds")
                }

                Button(role: .cancel, action: {}) {
                    Text("Cancel")
                }
            },
            message: {
                Text("Only sounds, which are not used in any other boards will be deleted.")
            }
        )
        .navigationTitle(Text("\(board?.symbol ?? "") \(board?.title ?? "")"))
        .navigationBarTitleDisplayMode(.inline)
    }


    private func exportBoard() {
        guard let board = board else { return }
        let folderName = "\(board.symbol) \(board.title)"
        let boardFolderURL = FileManager.default.temporaryDirectory.appendingPathComponent(folderName)

        do {
            FileManager.default.deleteIfExists(at: boardFolderURL)

            // Create new folder
            try FileManager.default.createDirectory(
                at: boardFolderURL, withIntermediateDirectories: true)

            // Copy each sound to the folder
            let boardSounds = board.sounds.compactMap { soundID in
                sounds.first(where: { $0.id == soundID })
            }

            for sound in boardSounds {
                let fileName = "\(sound.symbol) \(sound.title).mp3"
                let soundFileURL = boardFolderURL.appendingPathComponent(fileName)
                try FileManager.default.copyItem(at: sound.url, to: soundFileURL)
            }
            self.exportURL = boardFolderURL
            isExportingBoard = true
        } catch {
            print("Failed to export board: \(error)")
            self.playbackError = .exportFailed
            showErrorAlert = true
        }
    }
}

#Preview {
  NavigationStack {
    BoardView(boardID: Board.allID)
  }
}
