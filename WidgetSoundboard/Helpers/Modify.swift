//
//  Modify.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import SwiftUI


extension View {
    func modify<Content: View>(@ViewBuilder with content: (Self) -> Content) -> Content {
        content(self)
    }

    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        Group {
            if condition {
                content(self)
            } else {
                self
            }
        }
    }
}
