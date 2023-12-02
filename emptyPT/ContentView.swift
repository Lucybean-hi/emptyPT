import SwiftUI
import PerspectiveTransform

struct ContentView: View {
    @State private var cornerPoints = [
        CGPoint(x: 100, y: 100),    // Top left
        CGPoint(x: 300, y: 100),    // Top right
        CGPoint(x: 100, y: 300),    // Bottom left
        CGPoint(x: 300, y: 300)     // Bottom right
    ]

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let initialOffset = CGPoint(x: center.x - 200, y: center.y - 200)

            ZStack {
                Image("baseImage")
                    .resizable()
                    .frame(width: 400, height: 400)
                    .position(center)

                OverlayImageView(cornerPoints: $cornerPoints)
                    .frame(width: 400, height: 400)
                    .position(center)
                    .opacity(0.5)

                ForEach(Array(zip(cornerPoints.indices, cornerPoints)), id: \.0) { index, point in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                        .position(x: point.x + initialOffset.x, y: point.y + initialOffset.y)
                        .gesture(DragGesture()
                            .onChanged({ value in
                                // Update corner positions
                                cornerPoints[index] = CGPoint(x: value.location.x - initialOffset.x, y: value.location.y - initialOffset.y)
                            }))
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct OverlayImageView: View {
    @Binding var cornerPoints: [CGPoint]

    var body: some View {
        let startPerspective = Perspective(CGRect(x: 0, y: 0, width: 400, height: 400))
        let endPerspective = Perspective(cornerPoints)

        return Image("overlayImage")
            .resizable()
            .modifier(PerspectiveModifier(startPerspective: startPerspective, endPerspective: endPerspective))
    }
}

struct PerspectiveModifier: GeometryEffect {
    var startPerspective: Perspective
    var endPerspective: Perspective

    func effectValue(size: CGSize) -> ProjectionTransform {
        let transform3D = startPerspective.projectiveTransform(destination: endPerspective)

        let affineTransform = CGAffineTransform(
            a: CGFloat(transform3D.m11), b: CGFloat(transform3D.m12),
            c: CGFloat(transform3D.m21), d: CGFloat(transform3D.m22),
            tx: CGFloat(transform3D.m41), ty: CGFloat(transform3D.m42)
        )
        return ProjectionTransform(affineTransform)
    }
}
