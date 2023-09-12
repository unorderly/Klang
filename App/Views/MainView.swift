//
//  MainView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
//

import SwiftUI
import SwiftData
import WidgetKit
import Defaults
import SwiftUIReorderableForEach

struct MainView: View {
    @Default(.sounds) var sounds: [Sound]
    @Default(.boards) var boards: [Board]

    var allBoard: Board {
        Board.allBoard(with: sounds)
    }

    @Environment(\.scenePhase) var scenePhase
    

    @State var selectedBoard: Board?
    @State var showAddSheet = false
    @State var showGallery = false
    @State var showWidgetSetup = false

    @Environment(\.openURL) var openURL

    @State var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn, sidebar: {
            ScrollView(.vertical) {
                LazyVStack(spacing: 20) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: minimumWidth), spacing: 16)
                    ], spacing: 16) {
                        BoardButton(board: self.allBoard, isSelected: $selectedBoard.equals(self.allBoard))
                        ReorderableForEach($boards, allowReordering: .constant(true)) {
                            board,
                            isDragging in
                            BoardButton(board: board, isSelected: $selectedBoard.equals(board))
                                .opacity(isDragging ? 0.5 : 1)
                                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                        }
                    }

                    Button(action: {
                        self.showGallery = true
                    }) {
                        Label("Find more soundboards in the Gallery", systemImage: "sparkles.rectangle.stack")
                    }
                    .buttonStyle(.bordered)
                    .font(.headline)
                }
                .padding()
            }
            .navigationDestination(item: $selectedBoard) { board in
                BoardView(boardID: board.id)
            }
            .sheet(isPresented: $showAddSheet, content: {
                BoardEditor()
            })
            .navigationTitle(Text("Soundboards"))
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.showGallery = true
                    }) {
                        Label("Gallery", systemImage: "sparkles.rectangle.stack.fill")
                    }
                }

                ToolbarItem {
                    Button(action: {
                        self.showAddSheet = true
                    }) {
                        Label("Add Board", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu("About", systemImage: "ellipsis.circle") {
                        Button(action: {
                            openURL(URL(string: "mailto:klang@unorderly.io?subject=Klang%20Feedback")!)
                        }) {
                            Label("Contact Us", systemImage: "envelope.fill")
                        }

                        Button(action: {
                            openURL(URL(string: "https://github.com/unorderly/Klang")!)
                        }) {
                            Label("Source Code", systemImage: "curlybraces.square.fill")
                        }
                    }
                }
            }
        }, detail: {
            ContentUnavailableView("Select A Board", systemImage: "sparkles.rectangle.stack")
        })
        .sheet(isPresented: $showGallery, content: {
            GalleryView()
        })
        .alert("Setup Widgets", 
               isPresented: $showWidgetSetup,
               actions: {
            Button("Show Guide") {
                openURL(URL(string: "https://support.apple.com/en-us/HT207122")!)
            }
            Button(role: .cancel, action: { }) { Text("Cancel") }
        }, message: {
            Text("Setting up widgets correctly can be a bit tricky. Follow this guide to get your soundboards set up.")
        })
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .onOpenURL(perform: { url in
            if url.host() == "setup-widget" {
                self.showWidgetSetup = true
            }
        })
        .onAppear {
            if sounds.isEmpty {
                GalleryBoard.animals.save()
            }
        }

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


#Preview {
    MainView()
}
