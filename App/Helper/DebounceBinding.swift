import Combine
import SwiftUI

struct DebounceBindingModifier<Value: Equatable>: ViewModifier {
    @Binding var global: Value
    @Binding var local: Value

    var delay: RunLoop.SchedulerTimeType.Stride

    @State private var localPublisher: PassthroughSubject<Value, Never> = .init()

    let onChange: (Value) -> Void
    init(global: Binding<Value>,
         local: Binding<Value>,
         delay: RunLoop.SchedulerTimeType.Stride,
         onChange: @escaping (Value) -> Void = { _ in }) {
        self._global = global
        self._local = local
        self.delay = delay
        self.onChange = onChange
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: self.local, { _, value in
                self.localPublisher.send(value)
            })
            .onReceive(self.localPublisher
                .removeDuplicates()
                .debounce(for: self.delay, scheduler: RunLoop.main)) { value in
                    if self.global != value {
                        self.global = value
                        self.onChange(value)
                    }
            }
            .onDisappear {
                if self.global != self.local {
                    self.global = self.local
                    self.onChange(self.local)
                }
            }
            .onAppear {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.local = self.global
                }
            }
    }
}

extension View {
    public func debounce<Value: Equatable>(from local: Binding<Value>, to global: Binding<Value>, // asdf
                                           for delay: RunLoop.SchedulerTimeType.Stride = 0.3,
                                           onChange: @escaping (Value) -> Void = { _ in }) -> some View {
        self.modifier(DebounceBindingModifier(global: global, local: local, delay: delay, onChange: onChange))
    }
}
