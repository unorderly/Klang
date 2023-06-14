//
//  Query.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 13.06.23.
//

import Foundation
import AppIntents
import Defaults


struct SoundQuery: EntityStringQuery {
    func entities(for identifiers: [SoundEntity.ID]) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ identifiers.contains($0.id) })
            .map({ SoundEntity(sound: $0) })
    }
    
    func entities(matching string: String) async throws -> [SoundEntity] {
        return Defaults[.sounds]
            .filter({ $0.title.contains(string) })
            .map({ SoundEntity(sound: $0) })
    }
    
    func suggestedEntities() async throws -> [SoundEntity] {
        Defaults[.sounds]
            .map({ SoundEntity(sound: $0) })
    }
}
