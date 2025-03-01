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
    @State private var showErrorAlert: Bool = false
    @State private var playbackError: PlaybackError?

    var body: some View {
        Button(action: {
            do {
                if self.player == nil {
                    self.player = try AudioPlayer(url: sound.url)
                }

                guard let audioPlayer = self.player else { return }

                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                } else {
                    Task {
                        try await audioPlayer.playOnQueue()
                    }
                }
            } catch {
                showErrorAlert = true
                self.playbackError = .failedToPlay
            }
        }) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    Text(sound.symbol)
                        .font(.largeTitle)
                    Spacer()
                }

                Spacer()

                Text(sound.title)
                    .aligned(to: .leading)
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
                Section {
                    Button(action: {
                        self.isEditing = true
                    }) {
                        Label("Edit Sound", systemImage: "pencil")
                    }

                    exportButton
                }

                Section {
                    if var board = Defaults[.boards].first(where: { $0.id == self.boardID }) {
                        Button(role: .destructive, action: {
                            board.sounds.removeAll(where: { $0 == self.sound.id })
                            Defaults[.boards].upsert(board, by: \.id)
                            player?.stop()
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
                        player?.stop()
                    }) {
                        Label("Delete Sound", systemImage: "trash")
                    }
                }
            }, label: {
                Image(systemName: self.player?.isPlaying ?? false ? "speaker.wave.2.circle.fill" : "ellipsis.circle.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.variableColor
                        .cumulative
                        .nonReversing,
                                  options: .repeating,
                                  isActive: self.player?.isPlaying ?? false)
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.large)
                    .font(.title2)
                    .animation(.default, value: self.player?.isPlaying ?? false)
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(12)
        }
        .alert("There was an Error", isPresented: $showErrorAlert, actions: {
            Button("OK") { }
        }, message: {
            Text(self.playbackError?.errorDescription ?? "")
        })
        .buttonBorderShape(.roundedRectangle)
        .buttonStyle(.bordered)
        .tint(sound.color.ensureContrast)
        .animation(.default, value: self.player?.isPlaying ?? false)
    }

    var exportButton: some View {
        ShareLink(item: sound,
                  preview: SharePreview(
                    "\(sound.symbol) \(sound.title)",
                    image: Image(systemName: "music.quarternote.3")
                  )) {
            Label("Share Sound", systemImage: "square.and.arrow.up")
        }
    }
}

enum PlaybackError: Error {
    case failedToPlay
    case importFailed
    case exportFailed

    var errorDescription: String {
        switch self {
        case .failedToPlay:
            return "Failed to play sound."
        case .importFailed:
            return "Failed to import sound."
        case .exportFailed:
            return "Failed to export sounds."
        }
    }
}

#Preview {
    SoundButton(sound: .preview.first!, isEditing: .constant(false), boardID: nil)
        .frame(maxWidth: 200)
        .aligned(to: .all)
}
