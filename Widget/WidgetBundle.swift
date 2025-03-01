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
        if #available(iOS 18, *) {
            return WidgetBundleBuilder.buildBlock(
                ios17Widgets,
                ios18Widgets
            )
        } else {
            return WidgetBundleBuilder.buildBlock(
                ios17Widgets
            )
        }
    }

    @WidgetBundleBuilder
    var ios17Widgets: some Widget {
        SoundsWidget()
        BoardWidget()
    }

    @available(iOS 18.0, *) @WidgetBundleBuilder
    var ios18Widgets: some Widget {
        SoundControl()
    }
}
