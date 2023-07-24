//
//  WaveformView.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 24.07.23.
//

import SwiftUI

struct WaveformView: View {
    
    var samples: [Float]
    var progress: Double
    
    
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 1.5
    
    
    
    var body: some View {
        GeometryReader { proxy in
            let resampled = self.samples.resample(to: self.requiredBars(in: proxy.size.width))
            HStack {
                Rectangle()
                    .foregroundStyle(.secondary)
                    .frame(width: proxy.size.width * CGFloat(progress), alignment: .leading)
                Spacer(minLength: 0)
            }
            .animation(.interactiveSpring(), value: progress)
                .mask {
                    self.bars(for: resampled, in: proxy)
                }
            Rectangle()
                .foregroundStyle(.tertiary)
                .mask {
                    self.bars(for: resampled, in: proxy)
                }
        }
    }
    
    func bars(for samples: [Float], in proxy: GeometryProxy) -> some View {
        HStack(spacing: spacing) {
            ForEach(samples.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .frame(width: barWidth,
                           height: max(proxy.size.height / 2 *  CGFloat(samples[index]) * 2, barWidth),
                           alignment: .center)
            }
        }
    }
    
    func requiredBars(in width: CGFloat) -> Int {
        Int((width + spacing) / (barWidth + spacing))
    }
}

extension Collection where Element == Float, Index == Int {
    func resample(to newSampleRate: Int) -> [Element] {
        guard self.count > 1 else {
            return Array(repeating: self.first ?? 0, count: newSampleRate)
        }
        // Calculate the stride value for interpolation operation
        let strideValue = Element(self.count - 1) / Element(newSampleRate - 1)
        let newSamples: [Element] = stride(from: 0, to: strideValue * Element(newSampleRate - 1) + 1, by: strideValue).map { index -> Element in
            let intIndex = Int(index)
            let fraction = index - Element(intIndex)
            // Interpolate between this sample and the next (if there is a next)
            if intIndex < self.count - 1 {
                return self[intIndex] * (1 - fraction) + self[intIndex + 1] * fraction
            } else {
                return self[intIndex]
            }
        }
        return newSamples
    }
}

#Preview {
    PreviewState(0.5) { progres in
        WaveformView(samples: Array(repeating: [0.5, 0.6, 0.7, 0.5, 1, 0.9, 0.8, 0.7, 0.4, 0.2, 0.0, 0.1, 0.2], count: 10).flatMap({ $0 }),
                     progress: progres.wrappedValue)
        .frame(height: 50)
        .padding()
        
        Slider(value: progres, in: 0...1)
    }
}
