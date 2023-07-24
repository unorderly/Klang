//
//  RecordingButton.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 24.07.23.
//

import SwiftUI


struct RecorderButton: View {
    @State var recoder: AudioRecorder
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            RecordingButton(isActive: $recoder.isRecording) {
                Image(systemName: "mic.fill")
                    .symbolEffect(.pulse, isActive: recoder.isRecording)
                    .imageScale(.large)
                    .padding(8)
                    .font(.headline)
            }
            .background {
                Circle()
                    .foregroundStyle(.tint)
                    .opacity(recoder.isRecording ? 0.15 : 0)
                    .scaleEffect(recoder.audioLevel * 1.5 + 1)
            }
            
            
            Text("Record")
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .buttonStyle(RecordingButtonStyle(isActive: recoder.isRecording))
        .tint(Color.red)
        .animation(.default, value: recoder.isRecording)

    }
}


struct RecordingButtonStyle: ButtonStyle {
    
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(isActive ? AnyShapeStyle(.background) : AnyShapeStyle(.tint))
            .padding(10)
            .background {
                Circle()
                    .foregroundStyle(.tint)
                    .opacity(isActive ? 1 : 0.15)
            }
    }
}

struct RecordingButton<Label: View>: View {
    @Binding var isActive: Bool
    
    var label: Label
    
    @State private var isLongPressing = false
    
    @State private var isDragging = false
    
    init(isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self._isActive = isActive
        self.label = label()
    }
    
    var body: some View {
        VStack {
            Button(action: { }) {
                label
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1)
                    .onChanged({ value in
                        print("long press changed", value)
                    })
                    .onEnded({ _ in
                        print("Long pressing")
                        self.isLongPressing = true
                        self.isActive = true
                    })
                    .sequenced(before:
                                DragGesture()
                        .onChanged({ _ in
                            self.isDragging = true
                        })
                            .onEnded({ _ in
                                print("Drag ended")
                                if self.isLongPressing {
                                    self.isActive = false
                                    self.isLongPressing = false
                                }
                            })
                                .exclusively(before: TapGesture().onEnded({ _ in
                                    print("tapped")
                                    if self.isLongPressing {
                                        self.isActive = false
                                        self.isLongPressing = false
                                    }
                                })
                              ))
                    .simultaneously(with: TapGesture().onEnded({ _ in
                        print("gesture pressed")
                        self.isActive.toggle()
                    }))
            )
        }
    }
}

struct PreviewState<State, Content: View>: View {
    var content: (Binding<State>) -> Content
    
    @SwiftUI.State var state: State
    
    init(_ state: State, @ViewBuilder content: @escaping (Binding<State>) -> Content) {
        self._state = .init(initialValue: state)
        self.content = content
    }
    
    var body: some View {
        self.content($state)
    }
}

#Preview {
    PreviewState(false) { isActive in
        RecordingButton(isActive: isActive) {
            Text(isActive.wrappedValue ? "Recording" : "Record")
        }
    }
}
