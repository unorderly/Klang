//
//  ColorRow.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 24.07.23.
//

import SwiftUI

struct ColorSizeKey: PreferenceKey {
    typealias Value = [CGSize]
    static let defaultValue: [CGSize] = []

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

public struct ColorRow: View {
    @Binding public var selected: Color

    public var colors: [Color]

    public init(selected: Binding<Color>, colors: [Color]) {
        self._selected = selected
        self.colors = colors
    }

    @State private var size: CGSize = .init(width: 22, height: 22)

    @State private var custom: Color = .clear
    @State private var selectedColor: Color = .clear

    public var body: some View {
        HStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                ForEach((3..<colors.count).reversed(), id: \.self) { count in
                    HStack(spacing: 0) {
                        ForEach(colors.prefix(count), id: \.description) { color in
                            self.circle(for: color)
                            Spacer(minLength: 20)
                                .frame(maxWidth: 30)
                        }
                    }
                }
            }

            ColorPicker("Color Picker",
                        selection: $selectedColor,
                        supportsOpacity: false)
            .onChange(of: selectedColor) {
                custom = selectedColor
            }
            .onAppear {
                selectedColor = custom
            }
            .accessibilityAddTraits(!self.colors.contains(self.selected) ? .isSelected : [])
            .labelsHidden()
            .background(GeometryReader {
                Color.clear.preference(key: ColorSizeKey.self, value: [$0.size])
            })
        }
        .aligned(to: .horizontal)
        .onPreferenceChange(ColorSizeKey.self, perform: { value in
            self.size = CGSize(width: max(value.first?.width ?? 0, 22),
                               height: max(value.first?.height ?? 0, 22))
        })
        .onChange(of: self.selected) { _, value in
            if !self.colors.contains(value) {
                self.custom = .clear
            } else if self.custom == .clear {
                self.custom = value
            }
        }
        .onChange(of: self.custom) { _, value in
            if (value.cgColor?.alpha ?? 0) > 0 {
                self.selected = value
            }
        }
        .onAppear {
            if !self.colors.contains(self.selected) {
                self.custom = self.selected
            }
        }
    }

    func circle(for color: Color) -> some View {
        Button(action: {
            self.selected = color
        }) {
            Circle()
                .foregroundColor(color)
                .mask {
                    if color != self.selected {
                        Circle()
                    } else {
                        Circle()
                            .inset(by: 5)
                            .overlay {
                                Circle()
                                    .inset(by: 1.5)
                                    .stroke(lineWidth: 3)
                            }
                        
                    }
                }
        }
        .animation(.default, value: self.selected)
        .buttonStyle(.plain)
        .frame(width: self.size.width, height: self.size.height)
        .accessibilityAddTraits(color == self.selected
                                    ? .isSelected
                                    : [])
        .tint(color)
    }
}
#Preview {
    ColorRow(selected: .constant(.red), colors: ColorPalette.colors)
        .padding()
}
