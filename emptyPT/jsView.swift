//import SwiftUI
//import CoreImage
//import CoreImage.CIFilterBuiltins
//
//struct DraggableAnchorPoint: View {
//    @Binding var position: CGPoint
//
//    var body: some View {
//        Circle()
//            .fill(Color.red)
//            .frame(width: 10, height: 10)
//            .position(position)
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        self.position = value.location
//                    }
//            )
//    }
//}
//
//struct jsView: View {
//    @State private var image: UIImage? = UIImage(named: "overlayImage")
//    @State private var anchors: [CGPoint] = [
//        CGPoint(x: 50, y: 50),
//        CGPoint(x: 250, y: 50),
//        CGPoint(x: 250, y: 250),
//        CGPoint(x: 50, y: 250)
//    ]
//
//  func correctPerspective(image: UIImage, anchors: [CGPoint]) -> UIImage? {
//      guard let ciImage = CIImage(image: image) else { return nil }
//      let filter = CIFilter.perspectiveCorrection()
//
//      filter.inputImage = ciImage
//      filter.setValue(CIVector(x: anchors[0].x, y: ciImage.extent.height - anchors[0].y), forKey: "inputTopLeft")
//      filter.setValue(CIVector(x: anchors[1].x, y: ciImage.extent.height - anchors[1].y), forKey: "inputTopRight")
//      filter.setValue(CIVector(x: anchors[2].x, y: ciImage.extent.height - anchors[2].y), forKey: "inputBottomLeft")
//      filter.setValue(CIVector(x: anchors[3].x, y: ciImage.extent.height - anchors[3].y), forKey: "inputTopRight")
//
//
//      guard let outputCIImage = filter.outputImage else { return nil }
//      let context = CIContext()
//      guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
//
//      return UIImage(cgImage: outputCGImage)
//  }
//
//
//
//    var body: some View {
//        VStack {
//            if let image = image {
//                GeometryReader { geo in
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .overlay(
//                            Path { path in
//                                path.move(to: self.anchors[0])
//                                path.addLine(to: self.anchors[1])
//                                path.addLine(to: self.anchors[2])
//                                path.addLine(to: self.anchors[3])
//                                path.addLine(to: self.anchors[0])
//                            }
//                            .stroke(Color.red, lineWidth: 2)
//                        )
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .onChanged { value in
//                                    let index = self.getNearestAnchorIndex(to: value.location, in: geo.size)
//                                    self.anchors[index] = value.location
//                                }
//                        )
//                }
//            }
//            ForEach(0..<anchors.count, id: \.self) { index in
//                DraggableAnchorPoint(position: self.$anchors[index])
//            }
//            Button("Correct Perspective") {
//                if let image = image {
//                    self.image = correctPerspective(image: image, anchors: self.anchors)
//                }
//            }
//            .padding()
//            .background(Color.red)
//            .foregroundColor(.white)
//            .clipShape(Capsule())
//        }
//    }
//
//    func getNearestAnchorIndex(to point: CGPoint, in size: CGSize) -> Int {
//        var nearestIndex = 0
//        var shortestDistance = CGFloat.greatestFiniteMagnitude
//
//        for (index, anchor) in anchors.enumerated() {
//            let distance = pow(anchor.x - point.x, 2) + pow(anchor.y - point.y, 2)
//            if distance < shortestDistance {
//                shortestDistance = distance
//                nearestIndex = index
//            }
//        }
//
//        return nearestIndex
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
