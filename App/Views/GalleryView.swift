//
//  GalleryView.swift
//  App
//
//  Created by Leo Mehlig on 31.08.23.
//

import SwiftUI
import Defaults

struct GalleryView: View {

    var gallaryBoards: [GalleryBoard] = GalleryBoard.all

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    @State var selectedBoard: GalleryBoard?

    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: minimumWidth), spacing: 16)
                ], spacing: 16) {
                    ForEach(gallaryBoards) { board in
                        GalleryBoardButton(board: board, isSelected: $selectedBoard.equals(board))
                    }
                }
                .padding()
            }
            .navigationDestination(item: $selectedBoard) { board in
                GalleryBoardView(board: board)
            }
            .navigationTitle(Text("Gallery"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Dismiss", systemImage: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}



struct GalleryBoardView: View {
    @Environment(\.dismiss) var dismiss

    var board: GalleryBoard

    @ScaledMetric(relativeTo: .headline) var minimumWidth: CGFloat = 120

    @Default(.boards) var installedBoards

    var isInstalled: Bool {
        self.installedBoards.contains(where: { $0.galleryID == board.id })
    }

    @State var showsReplaceAlert = false

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: minimumWidth), spacing: 16)
            ], spacing: 16) {
                ForEach(board.sounds) { sound in
                    GallerySoundButton(sound: sound)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                if self.isInstalled {
                    self.showsReplaceAlert = true
                } else {
                    self.board.save()
                }
            }) {
                Label("Add Board", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .aligned(to: .horizontal)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .padding(.top, 16)
            .background(
                Rectangle()
                    .foregroundStyle(.thinMaterial)
                    .fadedMask(on: .top, 16)
                    .ignoresSafeArea()
            )
        }
        .alert("You have already saved this board.", isPresented: $showsReplaceAlert, actions: {
            Button(action: {
                self.board.save()
            }) {
                Text("Save Again")
            }

            Button(role: .cancel, action: { }) {
                Text("Cancel")
            }
        }, message: {
            Text("Would you like to save it again?")
        })
        .navigationTitle(Text("\(board.symbol) \(board.title)"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GallerySoundButton: View {

    var sound: GallerySound

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 100

    @State private var player: AudioPlayer?

    @Environment(\.openURL) var openURL

    var body: some View {
        Button(action: {
            let audioPlayer = try! self.player ?? AudioPlayer(url: sound.url)
            self.player = audioPlayer
            if audioPlayer.player.isPlaying {
                audioPlayer.stop()
            } else {
                Task {
                    try await audioPlayer.playOnQueue()
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
                Button(action: {
                    self.sound.save()
                }) {
                    Label("Add Sound", systemImage: "plus.circle.fill")
                }

                Section(content: {
                    Button(action: {
                        openURL(sound.source)
                    }) {
                        Label(sound.source.niceWebsiteName, systemImage: "link")
                    }
                    Text(sound.license.description)
                }, header: {
                    Text("Source & License")
                })
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
        .buttonBorderShape(.roundedRectangle)
        .buttonStyle(.bordered)
        .tint(sound.color)
        .animation(.default, value: self.player?.isPlaying ?? false)
    }
}

extension URL {
    var niceWebsiteName: String {
        if let host = self.host() {
            return host
        } else {
            return self.absoluteString
        }
    }
}

struct GalleryBoardButton: View {
    var board: GalleryBoard

    @Binding var isSelected: Bool

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 120

    @Namespace var namespace

    @Default(.boards) var installedBoards

    var isInstalled: Bool {
        self.installedBoards.contains(where: { $0.galleryID == board.id })
    }

    @State var showsReplaceAlert = false

    var body: some View {
        Button(action: { self.isSelected = true }) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    Text(board.symbol)
                        .font(.largeTitle)
                    Spacer()
                    Button(action: {
                        if self.isInstalled {
                            self.showsReplaceAlert = true
                        } else {
                            self.board.save()
                        }
                    }) {
                        Image(systemName: self.isInstalled ? "checkmark.circle.fill" : "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .contentTransition(.symbolEffect)
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            .animation(.default, value: isInstalled)
                    }
                        .font(.title2)
                        .bold()
                }

                Spacer(minLength: 4)

                VStack {
                    Text("\(board.sounds.count) Sounds")
                        .aligned(to: .leading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(board.title)
                        .aligned(to: .leading)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .bold()
                }
                .lineLimit(1)
            }
            .padding(4)
            .padding(.bottom, 4)
            .frame(height: itemSize)
        }
        .buttonBorderShape(.roundedRectangle)
        .buttonStyle(.bordered)
        .alert("You have already saved this board.", isPresented: $showsReplaceAlert, actions: {
            Button(action: {
                self.board.save()
            }) {
                Text("Save Again")
            }

            Button(role: .cancel, action: { }) {
                Text("Cancel")
            }
        }, message: {
            Text("Would you like to save it again?")
        })
        .tint(board.color)
    }
}

#Preview {
    VStack {
        GalleryView()
        Button("Clear All Boards") {
            Defaults[.boards].removeAll()
        }
    }
}

#Preview {
    GalleryBoardView(board: .animals)
}
