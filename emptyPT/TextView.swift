import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct DraggableAnchorPoint: View {
    @Binding var position: CGPoint

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 10, height: 10)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.position = value.location
                    }
            )
    }
}


struct TextView: View {
    @State private var image: UIImage? = UIImage(named: "overlayImage")
    @State private var anchors: [CGPoint] = [
        CGPoint(x: 50, y: 50),
        CGPoint(x: 250, y: 50),
        CGPoint(x: 250, y: 250),
        CGPoint(x: 50, y: 250)
    ]

    func correctPerspective(image: UIImage, anchors: [CGPoint]) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter.perspectiveCorrection()

        filter.setValue(CIVector(cgPoint: anchors[0]), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: anchors[1]), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: anchors[2]), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: anchors[3]), forKey: "inputBottomLeft")
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputCIImage = filter.outputImage else { return nil }
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage)
    }


    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            ForEach(0..<anchors.count, id: \.self) { index in
                DraggableAnchorPoint(position: self.$anchors[index])
            }

            Button("Correct Perspective") {
                if let image = image {
                    self.image = correctPerspective(image: image, anchors: self.anchors)
                }
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
}
