//
//  AddSoundView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI
import Defaults

struct AddSoundView: View {
    @Default(.sounds) var sounds: [Sound]
    @Default(.boards) var boards: [Board]

    var boardID: UUID

    var board: Board? {
        self.boards.first(where: { $0.id == self.boardID })
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 16)
            ], spacing: 16) {
                ForEach(sounds) { sound in
                    AddSoundButton(sound: sound,
                                   select: {
                        if var board = self.board {
                            board.sounds.append(sound.id)
                            Defaults[.boards].upsert(board, by: \.id)
                        }
                        self.dismiss()
                    })
                    .disabled(self.board?.sounds.contains(sound.id) ?? false)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
            .padding(.vertical)
        }
        .presentationDetents([.large, .medium])
    }
}


struct AddSoundButton: View {

    var sound: Sound

    var select: () -> Void

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 100

    @State private var player: AudioPlayer?

    var body: some View {
        Button(action: self.select) {
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
                Image(systemName: "speaker.wave.2.circle.fill")
                    .symbolEffect(.variableColor
                        .cumulative
                        .nonReversing,
                                  options: .repeating,
                                  isActive: self.player?.isPlaying ?? false)
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.large)
                    .font(.title2)
            }
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
    Color.red
        .sheet(isPresented: .constant(true), content: {
            AddSoundView(boardID: Board.allID)
        })
}
