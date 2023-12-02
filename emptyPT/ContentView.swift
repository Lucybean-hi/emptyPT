import SwiftUI
import PerspectiveTransform
import UIKit
import Foundation
import QuartzCore
import CoreGraphics

struct ContentView: View {
//    @State private var cornerPoints = [
//        CGPoint(x: 0, y: 0),    // Top left
//        CGPoint(x: 400, y: 0),    // Top right
//        CGPoint(x: 0, y: 400),    // Bottom left
//        CGPoint(x: 400, y: 400)     // Bottom right
//    ]
    @State private var topLeft = CGPoint(x: 0, y: 0) // 子视图/正方形 的左上角
    @State private var topRight = CGPoint(x: 400, y: 0)
    @State private var bottomLeft = CGPoint(x: 0, y: 400)
    @State private var bottomRight = CGPoint(x: 400, y: 400)

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let initialOffset = CGPoint(x: 0, y: 230) // 初始左上

            ZStack {
//                Image("baseImage")
//                    .resizable()
//                    .frame(width: 400, height: 400)
//                    .position(center)

              OverlayImageView(topLeft: $topLeft, topRight: $topRight, bottomLeft: $bottomLeft, bottomRight: $bottomRight)
                    .frame(width: 400, height: 400)
//                    .offset(x: 0, y: 0)
                    .position(center)
//                    .opacity(0.5)

//                ForEach(Array(zip(cornerPoints.indices, cornerPoints)), id: \.0) { index, point in
//                    Circle()
//                        .fill(Color.blue)
//                        .frame(width: 30, height: 30)
//                        .position(x: point.x + initialOffset.x, y: point.y + initialOffset.y)
//                        .gesture(DragGesture()
//                            .onChanged({ value in
//                                // Update corner positions
//                                cornerPoints[index] = CGPoint(x: value.location.x - initialOffset.x, y: value.location.y - initialOffset.y)
//                            }))
//                }
                DraggableCornerView(position: $topLeft, initialOffset: initialOffset)
                DraggableCornerView(position: $topRight, initialOffset: initialOffset)
                DraggableCornerView(position: $bottomLeft, initialOffset: initialOffset)
                DraggableCornerView(position: $bottomRight, initialOffset: initialOffset)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.gray)
    }
}

struct DraggableCornerView: View {
    @Binding var position: CGPoint
    var initialOffset: CGPoint

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 30, height: 30)
            .position(x: position.x + initialOffset.x, y: position.y + initialOffset.y) //正方形在长方形上的位置：0（正方形的右上角相对于正方形的左上角的位置） + offset
            .gesture(DragGesture()
                // change 正方形的corner
                .onChanged({ value in
                    position = CGPoint(x: value.location.x - initialOffset.x, y: value.location.y - initialOffset.y)
                }))
    }
}

struct OverlayImageView: View {
//    @Binding var cornerPoints: [CGPoint]
    @Binding var topLeft: CGPoint
    @Binding var topRight: CGPoint
    @Binding var bottomLeft: CGPoint
    @Binding var bottomRight: CGPoint
    var body: some View {
        let startPerspective = Perspective(CGRect(x: 0, y: 0, width: 400, height: 400))
        let endPerspective = Perspective(topLeft, topRight, bottomLeft, bottomRight)

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


