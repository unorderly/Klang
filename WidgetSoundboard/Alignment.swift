import SwiftUI

struct AlignmentModifier: ViewModifier {
    let edges: Edge.Set

    func body(content: Content) -> some View {
        VStack {
            if self.edges.contains(.bottom) {
                Spacer(minLength: 0)
            }
            HStack {
                if self.edges.contains(.trailing) {
                    Spacer(minLength: 0)
                }
                content
                    .multilineTextAlignment(self.edges.textAlignment)

                if self.edges.contains(.leading) {
                    Spacer(minLength: 0)
                }
            }
            if self.edges.contains(.top) {
                Spacer(minLength: 0)
            }
        }
    }
}

extension Edge.Set {
    var textAlignment: TextAlignment {
        if self.contains(.leading), !self.contains(.trailing) {
            return .leading
        } else if self.contains(.trailing), !self.contains(.leading) {
            return .trailing
        } else {
            return .center
        }
    }
}

extension TextAlignment {
    var edges: Edge.Set {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .horizontal
        case .trailing:
            return .trailing
        }
    }
}

public extension View {
    func aligned(to edges: Edge.Set) -> some View {
        ModifiedContent(content: self, modifier: AlignmentModifier(edges: edges))
    }

    func alignment(_ alignment: TextAlignment) -> some View {
        ModifiedContent(content: self, modifier: AlignmentModifier(edges: alignment.edges))
    }
}
