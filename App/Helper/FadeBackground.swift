import SwiftUI

struct FadeBackgroundModifier<Background: View>: ViewModifier {
    let background: Background
    let edges: Edge.Set
    let length: CGFloat

    func body(content: Content) -> some View {
        content.background(self.background
                            .mask(self.fadeMask)
                            .padding(self.edges, -self.length)
                            .ignoresSafeArea())
    }

    private var fadeMask: some View {
        HStack(spacing: 0) {
            if edges.contains(.leading) {
                LinearGradient(gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white
                ]), startPoint: .leading, endPoint: .trailing)
                .frame(width: length)
                .padding(.vertical, length)
            }
            VStack(spacing: 0) {
                if edges.contains(.top) {
                    LinearGradient(gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]), startPoint: .top, endPoint: .bottom)
                    .frame(height: length)
                }
                Color.white
                if edges.contains(.bottom) {
                    LinearGradient(gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]), startPoint: .bottom, endPoint: .top)
                    .frame(height: length)
                }
            }
            if edges.contains(.trailing) {
                LinearGradient(gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white
                ]), startPoint: .trailing, endPoint: .leading)
                .frame(width: length)
                .padding(.vertical, length)
            }
        }
    }
}

struct FadedMask: ViewModifier {

    let edges: Edge.Set
    let length: CGFloat

    func body(content: Content) -> some View {
        content.mask(self.fadeMask)
    }

    private var fadeMask: some View {
        HStack(spacing: 0) {
            if edges.contains(.leading) {
                LinearGradient(gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white
                ]), startPoint: .leading, endPoint: .trailing)
                .frame(width: length)
                //                    .padding(.vertical, length)
            }
            VStack(spacing: 0) {
                if edges.contains(.top) {
                    LinearGradient(gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]), startPoint: .top, endPoint: .bottom)
                    .frame(height: length)
                }
                Color.white
                if edges.contains(.bottom) {
                    LinearGradient(gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]), startPoint: .bottom, endPoint: .top)
                    .frame(height: length)
                }
            }
            if edges.contains(.trailing) {
                LinearGradient(gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white
                ]), startPoint: .trailing, endPoint: .leading)
                .frame(width: length)
                //                    .padding(.vertical, length)
            }
        }
    }
}

public extension View {
    func fadedBackground<Content: View>(_ content: Content,
                                        on edges: Edge.Set = .all,
                                        _ length: CGFloat = 12) -> some View {
        ModifiedContent(content: self,
                        modifier: FadeBackgroundModifier(background: content,
                                                         edges: edges,
                                                         length: length))
    }

    func fadedMask(on edges: Edge.Set = .all,
                   _ length: CGFloat = 12) -> some View {
        ModifiedContent(content: self, modifier: FadedMask(edges: edges, length: length))
    }
}

struct FadeBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
            Text("Hello, World!")
                .padding(20)
                .fadedBackground(Color.red, on: .top)
        }
    }
}
