//
//  IntentRunner.swift
//  Widget
//
//  Created by Leo Mehlig on 07.09.23.
//

import Foundation
import AppIntents
enum IntentRunner {
    static func perform(intent: SoundIntent) async throws -> some IntentResult {
        return .result()
    }
}
