import SwiftUI

@available(iOS 18.0, *)
@Observable private class FlexibleHeaderGeometry {
    var offset: CGFloat = 0
    var windowHeight: CGFloat = 0
}

private struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

@available(iOS 18.0, *)
private struct FlexibleHeaderContentModifier: ViewModifier {
    @Environment(FlexibleHeaderGeometry.self) private var geometry
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let height = (geometry.windowHeight / 3.2) - geometry.offset
        content
            .frame(height: height)
            .padding(.bottom, geometry.offset)
            .offset(y: geometry.offset)
            .clipShape(
                RoundedCorners(
                    radius: cornerRadius,
                    corners: [.bottomLeft, .bottomRight]
                )
            )
    }
}

@available(iOS 18.0, *)
private struct FlexibleHeaderScrollViewModifier: ViewModifier {
    @State private var geometry = FlexibleHeaderGeometry()

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                min(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, offset in
                geometry.offset = offset
            }
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: {
                geometry.windowHeight = $0.height
            }
            .environment(geometry)
    }
}

extension ScrollView {
    @ViewBuilder
    @MainActor func flexibleHeaderScrollView() -> some View {
        if #available(iOS 18, *) {
            modifier(FlexibleHeaderScrollViewModifier())
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func flexibleHeaderContent(cornerRadius: CGFloat = 28) -> some View {
        if #available(iOS 18, *) {
            modifier(FlexibleHeaderContentModifier(cornerRadius: cornerRadius))
        } else {
            self
        }
    }

    @ViewBuilder
    func shouldSetInset() -> some View {
        if #available(iOS 18, *) {
            self.ignoresSafeArea(edges: .top)
        } else {
            self
        }
    }
}
