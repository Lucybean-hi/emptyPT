import SwiftUI
//import PerspectiveTransform
import UIKit
import Foundation
import QuartzCore
import CoreGraphics
import CoreImage

struct ContentView: View {
    @State private var topLeft = CGPoint(x: 0, y: 0)
    @State private var topRight = CGPoint(x: 400, y: 0)
    @State private var bottomLeft = CGPoint(x: 0, y: 400)
    @State private var bottomRight = CGPoint(x: 400, y: 400)
    @State private var transformedImage: UIImage? = UIImage(named: "overlayImage")

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let initialOffset = CGPoint(x: 0, y: 230)

            ZStack {
                if let transformedImage = transformedImage {
                    Image(uiImage: transformedImage)
                        .resizable()
                        .frame(width: 400, height: 400)
                        .position(center)
                }

                DraggableCornerView(position: $topLeft, initialOffset: initialOffset, updateTransformedImage: updateImage)
                DraggableCornerView(position: $topRight, initialOffset: initialOffset, updateTransformedImage: updateImage)
                DraggableCornerView(position: $bottomLeft, initialOffset: initialOffset, updateTransformedImage: updateImage)
                DraggableCornerView(position: $bottomRight, initialOffset: initialOffset, updateTransformedImage: updateImage)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.gray)
    }

    func updateImage() {
        transformedImage = perspectiveTransformedImage()
    }

    func perspectiveTransformedImage() -> UIImage {
        guard let originalImage = UIImage(named: "overlayImage"),
              let ciOriginalImage = CIImage(image: originalImage) else {
            return UIImage()
        }

        let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
        let imageSize = ciOriginalImage.extent.size

        let ciTopLeft = CGPoint(x: topLeft.x, y: imageSize.height - topLeft.y)
        let ciTopRight = CGPoint(x: topRight.x, y: imageSize.height - topRight.y)
        let ciBottomLeft = CGPoint(x: bottomLeft.x, y: imageSize.height - bottomLeft.y)
        let ciBottomRight = CGPoint(x: bottomRight.x, y: imageSize.height - bottomRight.y)

        perspectiveTransform.setValue(CIVector(cgPoint: ciTopLeft), forKey: "inputTopLeft")
        perspectiveTransform.setValue(CIVector(cgPoint: ciTopRight), forKey: "inputTopRight")
        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomLeft), forKey: "inputBottomLeft")
        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomRight), forKey: "inputBottomRight")
        perspectiveTransform.setValue(ciOriginalImage, forKey: kCIInputImageKey)

        let ciContext = CIContext()
        guard let outputCIImage = perspectiveTransform.outputImage,
              let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage)
    }
}

struct DraggableCornerView: View {
    @Binding var position: CGPoint
    var initialOffset: CGPoint
    var updateTransformedImage: () -> Void

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 30, height: 30)
            .position(x: position.x + initialOffset.x, y: position.y + initialOffset.y)
            .gesture(DragGesture()
                .onChanged({ value in
                    position = CGPoint(x: value.location.x - initialOffset.x, y: value.location.y - initialOffset.y)
                })
                .onEnded({ _ in
                    updateTransformedImage()
                }))
    }
}

//struct ContentView: View {
//    @State private var topLeft = CGPoint(x: 0, y: 0) // 子视图/正方形 的左上角
//    @State private var topRight = CGPoint(x: 400, y: 0)
//    @State private var bottomLeft = CGPoint(x: 0, y: 400)
//    @State private var bottomRight = CGPoint(x: 400, y: 400)
//    @State private var transformedImage: UIImage? = UIImage(named: "overlayImage")
//
//    var body: some View {
//        GeometryReader { geometry in
//            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
//            let initialOffset = CGPoint(x: 0, y: 230) // 初始左上
//
//            ZStack {
////                Image("baseImage")
////                    .resizable()
////                    .frame(width: 400, height: 400)
////                    .position(center)
//
//              OverlayImageView(transformedImage: $transformedImage, topLeft: $topLeft, topRight: $topRight, bottomLeft: $bottomLeft, bottomRight: $bottomRight)
//                    .frame(width: 400, height: 400)
////                    .offset(x: 0, y: 0)
//                    .position(center)
////                    .opacity(0.5)
//                DraggableCornerView(position: $topLeft, initialOffset: initialOffset)
//                DraggableCornerView(position: $topRight, initialOffset: initialOffset)
//                DraggableCornerView(position: $bottomLeft, initialOffset: initialOffset)
//                DraggableCornerView(position: $bottomRight, initialOffset: initialOffset)
//            }
//        }
//        .edgesIgnoringSafeArea(.all)
//        .background(Color.gray)
//    }
//}
//
//struct DraggableCornerView: View {
//    @Binding var position: CGPoint
//    var initialOffset: CGPoint
//
//    var body: some View {
//        Circle()
//            .fill(Color.blue)
//            .frame(width: 30, height: 30)
//            .position(x: position.x + initialOffset.x, y: position.y + initialOffset.y) //正方形在长方形上的位置：0（正方形的右上角相对于正方形的左上角的位置） + offset
//            .gesture(DragGesture()
//                // change 正方形的corner
//                .onChanged({ value in
//                    position = CGPoint(x: value.location.x - initialOffset.x, y: value.location.y - initialOffset.y)
//                }))
//    }
//}
//
//struct OverlayImageView: View {
//    @Binding var transformedImage: UIImage?
//    @Binding var topLeft: CGPoint
//    @Binding var topRight: CGPoint
//    @Binding var bottomLeft: CGPoint
//    @Binding var bottomRight: CGPoint
//
////    func perspectiveTransformedImage() -> UIImage {
////        // 确保能够加载原始图像
////        guard let originalImage = UIImage(named: "overlayImage"),
////              let ciOriginalImage = CIImage(image: originalImage) else {
////            return UIImage()
////        }
////
////        let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
////        let imageSize = ciOriginalImage.extent.size
////
////        // 将点从SwiftUI转换为Core Image坐标系统
////        let ciTopLeft = CGPoint(x: topLeft.x, y: imageSize.height - topLeft.y)
////        let ciTopRight = CGPoint(x: topRight.x, y: imageSize.height - topRight.y)
////        let ciBottomLeft = CGPoint(x: bottomLeft.x, y: imageSize.height - bottomLeft.y)
////        let ciBottomRight = CGPoint(x: bottomRight.x, y: imageSize.height - bottomRight.y)
////
////        // 设置透视变换的参数
////        perspectiveTransform.setValue(CIVector(cgPoint: ciTopLeft), forKey: "inputTopLeft")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciTopRight), forKey: "inputTopRight")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomLeft), forKey: "inputBottomLeft")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomRight), forKey: "inputBottomRight")
////        perspectiveTransform.setValue(ciOriginalImage, forKey: kCIInputImageKey)
////
////        let ciContext = CIContext()
////        guard let outputCIImage = perspectiveTransform.outputImage,
////              let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
////            return UIImage()
////        }
////        return UIImage(cgImage: cgImage)
////    }
//
//    var body: some View {
//        return Image(uiImage: perspectiveTransformedImage())
//            .resizable()
//        func updateTransformedImage() {
//            self.transformedImage = perspectiveTransformedImage()
//        }
//        func perspectiveTransformedImage() -> UIImage {
//            guard let originalImage = transformedImage,
//                  let ciOriginalImage = CIImage(image: originalImage) else {
//                return UIImage()
//            }
//
//            let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
//            let imageSize = ciOriginalImage.extent.size
//
//            // 将点从SwiftUI转换为Core Image坐标系统
//            let ciTopLeft = CGPoint(x: topLeft.x, y: imageSize.height - topLeft.y)
//            let ciTopRight = CGPoint(x: topRight.x, y: imageSize.height - topRight.y)
//            let ciBottomLeft = CGPoint(x: bottomLeft.x, y: imageSize.height - bottomLeft.y)
//            let ciBottomRight = CGPoint(x: bottomRight.x, y: imageSize.height - bottomRight.y)
//
//            // 设置透视变换的参数
//            perspectiveTransform.setValue(CIVector(cgPoint: ciTopLeft), forKey: "inputTopLeft")
//            perspectiveTransform.setValue(CIVector(cgPoint: ciTopRight), forKey: "inputTopRight")
//            perspectiveTransform.setValue(CIVector(cgPoint: ciBottomLeft), forKey: "inputBottomLeft")
//            perspectiveTransform.setValue(CIVector(cgPoint: ciBottomRight), forKey: "inputBottomRight")
//            perspectiveTransform.setValue(ciOriginalImage, forKey: kCIInputImageKey)
//
//            let ciContext = CIContext()
//            guard let outputCIImage = perspectiveTransform.outputImage,
//                  let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
//                return UIImage()
//            }
//            return UIImage(cgImage: cgImage)
//        }
//    }
//}
//
////struct OverlayImageView: View {
////    @Binding var topLeft: CGPoint
////    @Binding var topRight: CGPoint
////    @Binding var bottomLeft: CGPoint
////    @Binding var bottomRight: CGPoint
////  var body: some View {
////    return Image(uiImage: perspectiveTransformedImage())
////      .resizable()
////    //        let startPerspective = Perspective(CGRect(x: 0, y: 0, width: 400, height: 400))
////    //        let endPerspective = Perspective(topLeft, topRight, bottomLeft, bottomRight)
////    //
////    //        return Image("overlayImage")
////    //            .resizable()
////    //            .modifier(PerspectiveModifier(startPerspective: startPerspective, endPerspective: endPerspective))
////    func perspectiveTransformedImage() -> UIImage {
////        guard let overlayUIImage = UIImage(named: "overlayImage") else {
////            return UIImage()
////        }
////        let ciOverlayImage = CIImage(image: overlayUIImage)!
////
////        let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
////        let imageSize = ciOverlayImage.extent.size
////
////        // Convert points from SwiftUI to Core Image coordinate system
////        let ciTopLeft = CGPoint(x: topLeft.x, y: imageSize.height - topLeft.y)
////        let ciTopRight = CGPoint(x: topRight.x, y: imageSize.height - topRight.y)
////        let ciBottomLeft = CGPoint(x: bottomLeft.x, y: imageSize.height - bottomLeft.y)
////        let ciBottomRight = CGPoint(x: bottomRight.x, y: imageSize.height - bottomRight.y)
////
////        perspectiveTransform.setValue(CIVector(cgPoint: ciTopLeft), forKey: "inputTopLeft")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciTopRight), forKey: "inputTopRight")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomLeft), forKey: "inputBottomLeft")
////        perspectiveTransform.setValue(CIVector(cgPoint: ciBottomRight), forKey: "inputBottomRight")
////        perspectiveTransform.setValue(ciOverlayImage, forKey: kCIInputImageKey)
////
////        let ciContext = CIContext()
////        guard let outputCIImage = perspectiveTransform.outputImage,
////              let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
////            return UIImage()
////        }
////
////        return UIImage(cgImage: cgImage)
////    }
////  }
////}
//
////struct PerspectiveModifier: GeometryEffect {
////    var startPerspective: Perspective
////    var endPerspective: Perspective
////
////    func effectValue(size: CGSize) -> ProjectionTransform {
////        let transform3D = startPerspective.projectiveTransform(destination: endPerspective)
////
////        let affineTransform = CGAffineTransform(
////            a: CGFloat(transform3D.m11), b: CGFloat(transform3D.m12),
////            c: CGFloat(transform3D.m21), d: CGFloat(transform3D.m22),
////            tx: CGFloat(transform3D.m41), ty: CGFloat(transform3D.m42)
////        )
////        return ProjectionTransform(affineTransform)
////    }
////}
//
//
