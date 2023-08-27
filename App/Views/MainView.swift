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

    @State var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn, sidebar: {
            ScrollView(.vertical) {
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
            .navigationTitle(Text("Soundboards"))
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
