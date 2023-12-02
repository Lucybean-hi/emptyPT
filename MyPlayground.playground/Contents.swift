////import PerspectiveTransform
////import CoreGraphics
////
////// Define the destination corners as per the overlay you want to match.
////let destinationCorners = [
////    CGPoint(x: 108.315837, y: 80.1687782),
////    CGPoint(x: 377.282671, y: 41.4352201),
////    CGPoint(x: 193.321418, y: 330.023027),
////    CGPoint(x: 459.781253, y: 251.836131)
////]
////
////// Create a Perspective object with the destination corners.
////// Note: The order of points is important: top-left, top-right, bottom-left, bottom-right.
////let destinationPerspective = Perspective(destinationCorners)
////
////// Normally, you would get the starting perspective from the frame of a UIView,
////// but in a Playground, we'll just define it manually for the example.
////// Let's assume the overlay view is a square of 400x400 for simplicity.
////let startCorners = [
////    CGPoint(x: 0, y: 0),
////    CGPoint(x: 400, y: 0),
////    CGPoint(x: 0, y: 400),
////    CGPoint(x: 400, y: 400)
////]
////let startPerspective = Perspective(startCorners)
////
////// Calculate the projective transform from the starting perspective to the destination.
////let transform = startPerspective.projectiveTransform(destination: destinationPerspective)
////
////// Print out the transform to see the resulting matrix.
////print(transform)
//import PlaygroundSupport
//import UIKit
//import CoreGraphics
//
//// Define your CATransform3D, which you've printed out earlier
//let catTransform = CATransform3D(m11: 0.8339906152107471, m12: -0.07908901773184782, m13: 0.0, m14: 0.0004282559010263876,
//                                 m21: 0.19142821649144573, m22: 0.5886397220316582, m23: 0.0, m24: -0.00010907087391917567,
//                                 m31: 0.0, m32: 0.0, m33: 1.0, m34: 0.0,
//                                 m41: 108.31583699999999, m42: 80.1687782, m43: 0.0, m44: 0.9999999999999999)
//
//// Create a path representing the pre-transformation square
//let path = CGMutablePath()
//path.addRect(CGRect(x: 0, y: 0, width: 400, height: 400))
//
//// Convert the CATransform3D to a CGAffineTransform
//var cgTransform = CGAffineTransform(
//    a: CGFloat(catTransform.m11), b: CGFloat(catTransform.m12),
//    c: CGFloat(catTransform.m21), d: CGFloat(catTransform.m22),
//    tx: CGFloat(catTransform.m41), ty: CGFloat(catTransform.m42)
//)
//
//// Apply the CGAffineTransform to the path
//let transformedPath = path.mutableCopy(using: &cgTransform)
//
//// Draw the transformed path in a UIView
//class TransformView: UIView {
//    override func draw(_ rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext() else { return }
//        
//        // Set the stroke color to blue for the original square
//        context.setStrokeColor(UIColor.blue.cgColor)
//        context.addPath(path)
//        context.strokePath()
//        
//        // Set the stroke color to red for the transformed square
//        context.setStrokeColor(UIColor.red.cgColor)
//        if let transformedPath = transformedPath {
//            context.addPath(transformedPath)
//            context.strokePath()
//        }
//    }
//}
//
//// Set up the live view in the Playground to show our custom view
//let view = TransformView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
//view.backgroundColor = .white
//PlaygroundPage.current.liveView = view
