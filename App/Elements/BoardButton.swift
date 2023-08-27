//
//  BoardButton.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI

struct BoardButton: View {
    var board: Board

    @Binding var isSelected: Bool

    @ScaledMetric(relativeTo: .title2) private var itemSize: CGFloat = 100

    @Namespace var namespace

    var body: some View {
        Button(action: { self.isSelected = true }) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    Text(board.symbol)
                        .font(.largeTitle)
                    Spacer()
                    Text("\(board.sounds.count)")
                        .font(.largeTitle)
                        .bold()
                }

                Spacer()

                HStack {
                    Text(board.title)
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
        .buttonBorderShape(.roundedRectangle)
        .modify(with: { content in
            if self.isSelected {
                content.buttonStyle(.borderedProminent)
            } else {
                content.buttonStyle(.bordered)
            }
        })
        .tint(board.color)
    }
}

#Preview {
    PreviewState(false) { isSelected in
        BoardButton(board: .default.first!, isSelected: isSelected)
            .frame(maxWidth: 200)
    }
}
