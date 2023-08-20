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

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    @State var searchQuery = ""

    @State var fuse = Fuse(tokenize: true)

    var filteredSounds: [Sound] {
        if searchQuery.isEmpty {
            return self.sounds
        } else {
            let fuseMatches = self.fuse.search(String(self.searchQuery.prefix(100)), in: self.sounds)
            return fuseMatches.sorted(by: { $0.score < $1.score }).map({ self.sounds[$0.index] })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                if sounds.isEmpty {
                    ContentUnavailableView("No Sounds", systemImage: "speaker.slash.fill", description: Text("Create some sounds and then add them to this board."))
                } else if filteredSounds.isEmpty {
                    ContentUnavailableView.search
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: minimumWidth), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredSounds) { sound in
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
                }
            }
            .searchable(text: $searchQuery,
                        placement: .automatic,
                        prompt: Text("Search Sounds"))
            .navigationTitle(Text("Add Sound"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large, .medium])
    }
}

extension Sound: Fuseable {
    var properties: [FuseProperty] {
        [
            .init(name: self.title),
            .init(name: self.symbol)
        ]
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
