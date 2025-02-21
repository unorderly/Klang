//
//  BoardEditor.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI
import Defaults
import MCEmojiPicker

struct BoardEditor: View {
    @State var title: String
    @State var symbol: String
    @State var color: Color = .red

    @State var isEmojiPickerPresent: Bool = false

    @State var sounds: [UUID] = []

    @State var id: UUID = .init()

    @State var isExisting = false

    @Environment(\.dismiss) var dismiss

    init(title: String = "",
         symbol: String = "🚦",
         color: Color = .red,
         sounds: [UUID] = [],
         id: UUID = .init(),
         isExisting: Bool = false) {
        self._title = State(initialValue: title)
        self._symbol = State(initialValue: symbol)
        self._color = State(initialValue: color)
        self._sounds = State(initialValue: sounds)
        self._id = State(initialValue: id)
        self._isExisting = State(initialValue: isExisting)
    }

    init(board: Board) {
        self.init(title: board.title,
                  symbol: board.symbol,
                  color: board.color,
                  sounds: board.sounds,
                  id: board.id,
                  isExisting: true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(action: {
                            self.isEmojiPickerPresent = true
                        }) {
                            Text(symbol)
                                .padding(4)
                                .font(.title2)
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .tint(self.color)
                        .emojiPicker(
                            isPresented: $isEmojiPickerPresent,
                            selectedEmoji: $symbol
                        )

                        TextField("Title", text: $title)
                            .font(.title3.weight(.semibold))
                    }

                    ColorRow(selected: $color, colors: ColorPalette.colors)
                        .padding(6)

                }
            }
            .navigationTitle(Text(self.isExisting ? "Update Board" : "New Board"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            // Toolbar was causing a bug when playing a sound.
            .navigationBarItems(leading: self.cancelButton,
                                trailing: self.doneButton)
        }
    }


    var cancelButton: some View {
        Button(action: {
            self.dismiss()
        }) {
            Text("Cancel")
        }
    }

    var doneButton: some View {
        Button(self.isExisting ? "Update" : "Create") {
            let board = Board(id: self.id,
                              title: self.title,
                              symbol: self.symbol,
                              color: self.color,
                              sounds: self.sounds)
            Defaults[.boards].upsert(board, by: \.id)
            self.dismiss()
            Defaults[.signals] += 1
        }
        .font(.headline)
        .disabled(self.title.isEmpty)
    }
}

#Preview {
    BoardEditor()
}
