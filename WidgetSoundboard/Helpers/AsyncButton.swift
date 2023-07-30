//
//  File.swift
//  
//
//  Created by Leo Mehlig on 26.02.23.
//

import Foundation
import SwiftUI

public struct AsyncButton<Content: View>: View {
    
    let label: (Bool) -> Content
    let action: () async throws -> Void
    
    @Binding var isRunning: Bool?
    
    @State private var isLoading = false
    @State private var error: Error?
    
    @State private var task: Task<Void, Never>?
    
    public init(action: @escaping () async throws -> Void, @ViewBuilder label: @escaping (Bool) -> Content) {
        self.action = action
        self.label = label
        self._isRunning = .constant(nil)
    }
    
    public init(_ title: any StringProtocol, action: @escaping () async throws -> Void) where Content == AnyView {
        self.action = action
        self.label = { isLoading in
            AnyView(Text(title)
                .opacity(isLoading ? 0.5 : 1)
                .overlay(ProgressView().hidden(!isLoading)))
        }
        self._isRunning = .constant(nil)
    }
    
    public init(_ title: any StringProtocol, isLoading: Binding<Bool>, action: @escaping () async throws -> Void) where Content == AnyView {
        self.action = action
        self.label = { isLoading in
            AnyView(Text(title)
                .opacity(isLoading ? 0.5 : 1)
                .overlay(ProgressView().hidden(!isLoading)))
        }
        self._isRunning = isLoading.map(to: { $0 }, from: { $0! })
    }
    
    public init(_ title: LocalizedStringKey, action: @escaping () async throws -> Void) where Content == AnyView {
        self.action = action
        self.label = { isLoading in
            AnyView(Text(title)
                .opacity(isLoading ? 0.5 : 1)
                .overlay(ProgressView().hidden(!isLoading)))
        }
        self._isRunning = .constant(nil)
    }
    
    public init<T: View>(action: @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> T) where Content == AnyView {
        self.action = action
        self.label = { isLoading in
            AnyView(label()
                        .opacity(isLoading ? 0.5 : 1)
                        .overlay(ProgressView().hidden(!isLoading)))
        }
        self._isRunning = .constant(nil)
    }
    
    public var body: some View {
        Button(action: {
            self.performAction()
        }, label: {
            self.label(isLoading)
        })
        .onChange(of: self.isRunning == true && !self.isLoading, initial: true) { _, value in
            if value {
                self.performAction()
            }
        }
        .onChange(of: self.isRunning == false && self.isLoading, initial: true) { _, value in
            if value {
                self.task?.cancel()
            }
        }
        .disabled(self.isLoading)
        .alert(error: $error, title: Text("Unexpected error"))
    }
    
    private func performAction() {
        self.task?.cancel()
        self.task = Task {
            await withTaskCancellationHandler {
                self.isLoading = true
                self.isRunning = true
                do {
                    try await self.action()
                } catch {
                    self.error = error
                }
                self.isLoading = false
                self.isRunning = false
            } onCancel: {
                self.isLoading = false
                self.isRunning = false
            }
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}

extension View {
    public func alert<Error: Swift.Error>(error: Binding<Error?>, title: Text) -> some View {
        self.alert(item: Binding<String?>(get: {
            error.wrappedValue?.localizedDescription
        }, set: {
            if $0 == nil {
                error.wrappedValue = nil
            }
        }), content: {
            SwiftUI.Alert(title: title,
                  message: Text($0),
                  dismissButton: .cancel())
        })
    }
}


extension View {
    public func hidden(_ flag: Bool) -> some View {
        Group {
            if !flag {
                self
            }
        }
    }
}



public extension Binding {
    func map<T>(to: @escaping (Value) -> T, from: @escaping (T) -> Value) -> Binding<T> {
        Binding<T>(get: { () -> T in
            to(self.wrappedValue)
        }, set: { (value: T) in
            self.wrappedValue = from(value)
        })
    }
    
    func hasValue<T>(default: T?) -> Binding<Bool> where Value == T? {
        self.map(to: {
            $0 != nil
        }, from: {
            if $0 {
                return self.wrappedValue ?? `default`
            } else {
                return nil
            }
        })
    }
}
