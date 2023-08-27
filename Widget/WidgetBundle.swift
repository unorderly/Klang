//
//  SoundWidgetBundle.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import WidgetKit
import SwiftUI

@main
struct SoundWidgetBundle: WidgetBundle {
    var body: some Widget {
        SoundsWidget()
        BoardWidget()
    }
}
