//
//  SoundWidgetLiveActivity.swift
//  SoundWidget
//
//  Created by Leo Mehlig on 07.06.23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SoundWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SoundWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SoundWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SoundWidgetAttributes {
    fileprivate static var preview: SoundWidgetAttributes {
        SoundWidgetAttributes(name: "World")
    }
}

extension SoundWidgetAttributes.ContentState {
    fileprivate static var smiley: SoundWidgetAttributes.ContentState {
        SoundWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SoundWidgetAttributes.ContentState {
         SoundWidgetAttributes.ContentState(emoji: "🤩")
     }
}

//#Preview("Notification", as: .content, using: SoundWidgetAttributes.preview) {
//   SoundWidgetLiveActivity()
//} contentStates: {
//    SoundWidgetAttributes.ContentState.smiley
//    SoundWidgetAttributes.ContentState.starEyes
//}
