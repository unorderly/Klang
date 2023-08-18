//
//  SoundButton.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI
import Defaults

struct SoundButton: View {

    var sound: Sound

    @Binding var isEditing: Bool

    var boardID: UUID?

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
                Button(action: {
                    self.isEditing = true
                }) {
                    Label("Edit Sound", systemImage: "pencil")
                }
                if var board = Defaults[.boards].first(where: { $0.id == self.boardID }) {
                    Button(role: .destructive, action: {
                        board.sounds.removeAll(where: { $0 == self.sound.id })
                        Defaults[.boards].upsert(board, by: \.id)
                    }) {
                        Label("Remove From Board", systemImage: "trash")
                    }
                }
                Button(role: .destructive, action: {
                    Defaults[.sounds].removeAll(where: { $0.id == self.sound.id })
                    for var board in Defaults[.boards] where board.sounds.contains(self.sound.id) {
                        board.sounds.removeAll(where: { $0 == self.sound.id })
                        Defaults[.boards].upsert(board, by: \.id)
                    }
                }) {
                    Label("Delete Sound", systemImage: "trash")
                }
            }, label: {
                Image(systemName: "ellipsis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.large)
                    .font(.headline)
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
    SoundButton(sound: .default.first!, isEditing: .constant(false), boardID: nil)
        .frame(maxWidth: 200)
        .aligned(to: .all)
}
