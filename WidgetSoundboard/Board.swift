////
////  Board.swift
////  WidgetSoundboard
////
////  Created by Leo Mehlig on 08.06.23.
////
//
//import Foundation
//import SwiftUI
//
//struct Soundboard {
//    struct Sound: Identifiable {
//        let file: String
//        let title: String
//        let symbol: String
//        let color: Color
//        
//        var id: String { self.title }
//    }
//    let title: String
//    let sounds: [Sound]
//    
//    static var one: Soundboard = Soundboard(title: "One", sounds: [
//        .init(file: "frog.caf", title: "Horse", symbol: "🐴", color: .brown),
//        .init(file: "seagulls.caf", title: "Seagulls", symbol: "🐦", color: .blue),
//        .init(file: "horse.caf", title: "Frog", symbol: "🐸", color: .green),
//        .init(file: "wait.m4a", title: "Wait", symbol: "🚦", color: .yellow),
//    ])
//}
