#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

import SwiftUI

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        
        self.init(red: r, green: g, blue: b)
    }

    public func encode(to encoder: Encoder) throws {
        let resolved = self.resolve(in: .init())
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(resolved.red, forKey: .red)
        try container.encode(resolved.green, forKey: .green)
        try container.encode(resolved.blue, forKey: .blue)
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    func hex(in environment: EnvironmentValues = .init()) -> String {
        let resolved = self.resolve(in: environment)
   
        if resolved.opacity < 1 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(resolved.red * 255), lroundf(resolved.green * 255), lroundf(resolved.blue * 255), lroundf(resolved.opacity * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(resolved.red * 255), lroundf(resolved.green * 255), lroundf(resolved.blue * 255))
        }
    }

}

extension Color {
    /// Fixes: https://github.com/unorderly/Klang/issues/2
    var ensureContrast: Color {
        if self == .black || self == .white {
            return .primary
        } else {
            return self
        }
    }
}
