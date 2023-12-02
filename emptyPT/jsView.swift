import SwiftUI

struct jsView: View {
    @State private var anchors: [CGPoint] = [
        CGPoint(x: 50, y: 50),
        CGPoint(x: 250, y: 50),
        CGPoint(x: 250, y: 250),
        CGPoint(x: 50, y: 250)
    ]
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Image("overlayImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Path { path in
                        path.move(to: self.anchors[0])
                        path.addLine(to: self.anchors[1])
                        path.addLine(to: self.anchors[2])
                        path.addLine(to: self.anchors[3])
                        path.addLine(to: self.anchors[0])
                    }
                    .stroke(Color.red, lineWidth: 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let index = self.getNearestAnchorIndex(to: value.location, in: geo.size)
                                self.anchors[index] = value.location
                            }
                    )
                }
            }
            
            Button("Correct Perspective") {
                // Perform perspective correction here
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
    
    func getNearestAnchorIndex(to point: CGPoint, in size: CGSize) -> Int {
        var nearestIndex = 0
        var shortestDistance = CGFloat.greatestFiniteMagnitude
        
        for (index, anchor) in anchors.enumerated() {
            let distance = pow(anchor.x - point.x, 2) + pow(anchor.y - point.y, 2)
            if distance < shortestDistance {
                shortestDistance = distance
                nearestIndex = index
            }
        }
        
        return nearestIndex
    }
}
