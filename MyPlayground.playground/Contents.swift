/* Run the whole playground! The perspectiveTransform() function is displayed at top, but depends on types defined later. */

import CoreGraphics
import Foundation

/// Finds the perspective transform (the homography) from quadrilateral p to quadrilateral q.
/// Follows the method of Dave Eberly, but calculates affine transforms differently.
/// Algorithm based on PerspectiveMappings.pdf by Dave Eberly:
/// https://geometrictools.com/Documentation/PerspectiveMappings.pdf
/// For other code to improve this sample, please see Geometric Tools for Computer Graphics by Schneider & Eberly
/// Eberly's books: https://www.geometrictools.com/Books/Books.html
/// Code uses custom types, but could be rewritten to use matrix and vector types in the SIMD framework
func perspectiveTransform(p: Quadrilateral, q:Quadrilateral) -> Matrix3x3? {
    
    //Eberly: H = Aq * F * Inv(Ap)
    //here: H = Inv(Aq) * F * Ap
    
    //affine transform of p to canonical quadrilateral - use all points but 3rd point (p11)
    //NOTE: Eberly calculates affine transform for p in reverse direction!
    let ptri = Triangle(point1: p.point1, point2: p.point2, point3: p.point4)
    let canon = Triangle(x1: 0, y1: 0, x2: 1, y2: 0, x3: 0, y3: 1)
    
    guard let Ap = affineTransform(from: ptri, to: canon) else {
        print("Could not get affine transform for quadrilateral p")
        return nil
    }

    //affine transform of 1 to canonical quadrilateral - use all points but 3rd point (111)
    //deviating from Eberly, this is from q to canonical q; Eberly goes in the opposite direction
    let qtri = Triangle(point1: q.point1, point2: q.point2, point3: q.point4)

    guard let Aq = affineTransform(from: qtri, to: canon) else {
        print("Could not get affine transform for quadrilateral q")
        return nil
    }
    
    guard let InvAq = Aq.inverted() else {
        print("Could not get inverse of affine transform for quadrilateral q")
        return nil
    }
    
    // (a,b) is coordinate of p11 in canonical quadrilateral
    // (c,d) is coordinate of q11 in canonical quadrilateral
    
    let cp11 = p.p11.applying(Ap.toCGAffineTransform())
    let cq11 = q.p11.applying(Aq.toCGAffineTransform())
    
    let a = cp11.x
    let b = cp11.y
    let c = cq11.x
    let d = cq11.y
    
    let s = a + b - 1
    let t = c + d - 1

    //p convex if s > 0
    //q convex if t > 0
    
    //get fractional linear transformation
    //from canonical p to canonical q
    
    // F = | bcs                   0    0   |
    //     |   0                 ads    0   |
    //     | b(cs - at)   a(ds - bt)    abt |
    // where
    // s = a + b - 1
    // t = c + d - 1

    let F = Matrix3x3(
        m11: b * c * s, m12: 0, m13: 0,
        m21: 0, m22: a * d * s, m23: 0,
        m31: b * (c * s - a * t), m32: a * (d * s - b * t), m33: a * b * t)
    
    //"The 3 × 3 homography matrix H = Aq F Inv(Ap)"
    //NOTE: We calculated the affine transforms differently than Eberly
    return InvAq * F * Ap
}


/* TEST */
func printTransform(from: Quadrilateral, to: Quadrilateral) {
    var p = from
    var q = to
    
    // ensure points are properly ordered
    p.orderPoints(convexHull(_:))
    q.orderPoints(convexHull(_:))
    
    guard let H = perspectiveTransform(p: p, q: q) else {
        print("Could not find transform of p and q")
        return
    }
    
    print("homography\n\(H)")
    
    // convert points in p to 1x3 matrices, apply homography, return as CGPoint
    let hp00 = Matrix1x3(p.p00).applying(H).to2DPoint()
    let hp10 = Matrix1x3(p.p10).applying(H).to2DPoint()
    let hp11 = Matrix1x3(p.p11).applying(H).to2DPoint()
    let hp01 = Matrix1x3(p.p01).applying(H).to2DPoint()
    
    let f = NumberFormatter()
    
    print()
    print("H * p00 = \n\(f.string(hp00, 1)) calculated\n\(q.p00) expected ")
    print()
    print("H * p10 = \n\(f.string(hp10, 1)) calculated\n\(q.p10) expected ")
    print()
    print("H * p11 = \n\(f.string(hp11, 1)) calculated\n\(q.p11) expected ")
    print()
    print("H * p01 = \n\(f.string(hp01, 1)) calculated\n\(q.p01) expected")

}

func testPerspectiveTransform() {
    let p = Quadrilateral(
        point1: CGPoint(x: 2, y: 2),
        point2: CGPoint(x: 5, y: 1),
        point3: CGPoint(x: 6, y: 4),
        point4: CGPoint(x: 1, y: 3))
    
    let q = Quadrilateral(
        point1: CGPoint(x: 0, y: 1),
        point2: CGPoint(x: 6, y: 2),
        point3: CGPoint(x: 5, y: 5),
        point4: CGPoint(x: 2, y: 4))
    
    print("*** p -> q ***")
    printTransform(from: p, to: q)
    print()
    print("*** q -> p (swapped) ***")
    printTransform(from: q, to: p)
}

testPerspectiveTransform()


/* SUPPORTING TYPES. Replace with SIMD types as desired. */
func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
    degrees * CGFloat.pi / 180.0
}

func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
    180.0 * radians / CGFloat.pi
}

extension CGVector {
    init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func * (_ vector: CGVector, _ scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    static func * (_ scalar: CGFloat, _ vector: CGVector) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    static func * (lhs: CGVector, rhs: CGVector) -> CGFloat {
        lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }

    static func dotProduct(v1: CGVector, v2: CGVector) -> CGFloat {
        v1.dx * v2.dx + v1.dy * v2.dy
    }

    static func / (_ vector: CGVector, _ scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }

    static func / (_ scalar: CGFloat, _ vector: CGVector) -> CGVector {
        CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }

    // Returns again between vectors in range 0 to 2 * pi [positive]
    // a * b = ||a|| ||b|| cos(theta)
    // theta = arc cos (a * b / ||a|| ||b||)
    static func angleBetweenVectors(v1: CGVector, v2: CGVector) -> CGFloat {
        acos( v1 * v2 / (v1.length() * v2.length()) )
    }

    func length() -> CGFloat {
        sqrt(self.dx * self.dx + self.dy * self.dy)
    }
}

extension NumberFormatter {
    func string(_ value: Double, _ digits: Int, failText: String = "[?]") -> String {
        minimumFractionDigits = max(0, digits)
        maximumFractionDigits = minimumFractionDigits
        
        guard let s = string(from: NSNumber(value: value)) else {
            return failText
        }
        
        return s
    }
    
    func string(_ value: Float, _ digits: Int, failText: String = "[?]") -> String {
        minimumFractionDigits = max(0, digits)
        maximumFractionDigits = minimumFractionDigits
        
        guard let s = string(from: NSNumber(value: value)) else {
            return failText
        }
        
        return s
    }
    
    func string(_ value: CGFloat, _ digits: Int, failText: String = "[?]") -> String {
        minimumFractionDigits = max(0, digits)
        maximumFractionDigits = minimumFractionDigits
        
        guard let s = string(from: NSNumber(value: Double(value))) else {
            return failText
        }
        
        return s
    }
    
    func string(_ point: CGPoint, _ digits: Int = 1, failText: String = "[?]") -> String {
        let sx = string(point.x, digits, failText: failText)
        let sy = string(point.y, digits, failText: failText)
        return "(\(sx), \(sy))"
    }
    
    func string(_ vector: CGVector, _ digits: Int = 1, failText: String = "[?]") -> String {
        let sdx = string(vector.dx, digits, failText: failText)
        let sdy = string(vector.dy, digits, failText: failText)
        return "(\(sdx), \(sdy))"
    }
    
    func string(_ transform: CGAffineTransform, rotationDigits: Int = 2, translationDigits: Int = 1, failText: String = "[?]") -> String {
        let sa = string(transform.a, rotationDigits)
        let sb = string(transform.b, rotationDigits)
        let sc = string(transform.c, rotationDigits)
        let sd = string(transform.d, rotationDigits)
        let stx = string(transform.tx, translationDigits)
        let sty = string(transform.ty, translationDigits)

        var s = "a:  \(sa)   b: \(sb)   0"
        s += "\nc:  \(sc)   d: \(sd)   0"
        s += "\ntx: \(stx)   ty: \(sty)   1"
        return s
    }
}

struct Matrix1x3: CustomStringConvertible {
    var m1: CGFloat
    var m2: CGFloat
    var m3: CGFloat
    
    init(m1: CGFloat, m2: CGFloat, m3: CGFloat) {
        self.m1 = m1
        self.m2 = m2
        self.m3 = m3
    }
    
    init(_ p: CGPoint) {
        m1 = p.x
        m2 = p.y
        m3 = 1
    }
    
    var description: String {
        let f = NumberFormatter()
        return "\(f.string(m1, 2))"
            + "\n\(f.string(m2, 2))"
            + "\n\(f.string(m3, 2))"
    }
    
    /// |  m11  m12  m13 |      | m1 |
    /// |  m21  m22  m23 |  *   | m2 |
    /// |  m31  m32  m33 |      | m3 |
    func applying(_ x: Matrix3x3) -> Matrix1x3 {
        Matrix1x3(
            m1: x.m11 * m1 + x.m12 * m2 + x.m13 * m3,
            m2: x.m21 * m1 + x.m22 * m2 + x.m23 * m3,
            m3: x.m31 * m1 + x.m32 * m2 + x.m33 * m3)
    }
    
    func to2DPoint() -> CGPoint {
        CGPoint(x: m1 / m3, y: m2 / m3)
    }
}

/// Indices are m(row,column)
/// |  m11  m12  m13 |
/// |  m21  m22  m23 |
/// |  m31  m32  m33 |
struct Matrix3x3: CustomStringConvertible {
    var m11: CGFloat    //row 1
    var m12: CGFloat
    var m13: CGFloat

    var m21: CGFloat    //row 2
    var m22: CGFloat
    var m23: CGFloat

    var m31: CGFloat    //row 3
    var m32: CGFloat
    var m33: CGFloat
    
    var description: String {
        let f = NumberFormatter()
        
        var s = "\(f.string(m11, 2))   \(f.string(m12, 2))   \(f.string(m13, 2))"
        s += "\n\(f.string(m21, 2))   \(f.string(m22, 2))   \(f.string(m23, 2))"
        s += "\n\(f.string(m31, 2))   \(f.string(m32, 2))   \(f.string(m33, 2))"
        return s
    }
    
    func inverted() -> Matrix3x3? {
        let d = determinant()
        
        //TODO pick some realistic near-zero number here
        if abs(d) < 0.0000001 {
            return nil
        }

        //transpose matrix first
        let t = self.transpose()
        
        //determinants of 2x2 minor matrices
        let a11 = t.m22 * t.m33 - t.m32 * t.m23
        let a12 = t.m21 * t.m33 - t.m31 * t.m23
        let a13 = t.m21 * t.m32 - t.m31 * t.m22
        
        let a21 = t.m12 * t.m33 - t.m32 * t.m13
        let a22 = t.m11 * t.m33 - t.m31 * t.m13
        let a23 = t.m11 * t.m32 - t.m31 * t.m12
        
        let a31 = t.m12 * t.m23 - t.m22 * t.m13
        let a32 = t.m11 * t.m23 - t.m21 * t.m13
        let a33 = t.m11 * t.m22 - t.m21 * t.m12
        
        //adjugate (adjoint) matrix: apply + - + ... pattern
        let adj = Matrix3x3(
            m11: a11, m12: -a12, m13: a13,
            m21: -a21, m22: a22, m23: -a23,
            m31: a31, m32: -a32, m33: a33)
        return adj / d
    }
    
    func determinant() -> CGFloat {
        m11 * (m22 * m33 - m32 * m23) - m12 * (m21 * m33 - m31 * m23) + m13 * (m21 * m32 - m31 * m22)
    }
    
    func transpose() -> Matrix3x3 {
        Matrix3x3(m11: m11, m12: m21, m13: m31, m21: m12, m22: m22, m23: m32, m31: m13, m32: m23, m33: m33)
    }
    
    /// Converts the 3x3 matrix to a CGAffineTransform. Assumes that unused terms are zero.
    func toCGAffineTransform() -> CGAffineTransform {
        let CGM = self.transpose()
        return CGAffineTransform(a: CGM.m11, b: CGM.m12, c: CGM.m21, d: CGM.m22, tx: CGM.m31, ty: CGM.m32)
    }
    
    /// |  a11  a12  a13 |      |  b11  b12  b13 |
    /// |  a21  a22  a23 | *   |  b21  b22  b23 |
    /// |  a31  a32  a33 |      |  b31  b32  b33 |
    static func * (_ a: Matrix3x3, _ b: Matrix3x3) -> Matrix3x3 {
        return Matrix3x3(
            m11: a.m11 * b.m11 + a.m12 * b.m21 + a.m13 * b.m31,
            m12: a.m11 * b.m12 + a.m12 * b.m22 + a.m13 * b.m32,
            m13: a.m11 * b.m13 + a.m12 * b.m23 + a.m13 * b.m33,
            
            m21: a.m21 * b.m11 + a.m22 * b.m21 + a.m23 * b.m31,
            m22: a.m21 * b.m12 + a.m22 * b.m22 + a.m23 * b.m32,
            m23: a.m21 * b.m13 + a.m22 * b.m23 + a.m23 * b.m33,
            
            m31: a.m31 * b.m11 + a.m32 * b.m21 + a.m33 * b.m31,
            m32: a.m31 * b.m12 + a.m32 * b.m22 + a.m33 * b.m32,
            m33: a.m31 * b.m13 + a.m32 * b.m23 + a.m33 * b.m33)
    }
    
    static func / (_ m: Matrix3x3, _ s: CGFloat) -> Matrix3x3 {
        Matrix3x3(
            m11: m.m11/s, m12: m.m12/s, m13: m.m13/s,
            m21: m.m21/s, m22: m.m22/s, m23: m.m23/s,
            m31: m.m31/s, m32: m.m32/s, m33: m.m33/s)
    }
}

/// A representation of a 4x4 matrix used for calculation. The values are used to create
/// a CATransform3D.
struct Matrix4x4 {
    var m11: CGFloat
    var m12: CGFloat
    var m13: CGFloat
    var m14: CGFloat

    var m21: CGFloat
    var m22: CGFloat
    var m23: CGFloat
    var m24: CGFloat

    var m31: CGFloat
    var m32: CGFloat
    var m33: CGFloat
    var m34: CGFloat

    var m41: CGFloat
    var m42: CGFloat
    var m43: CGFloat
    var m44: CGFloat
    
    static var identity: Matrix4x4 {
        Matrix4x4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1)
    }
}

enum AngularOrientation: Int {
    case colinear
    case clockwise
    case counterclockwise
}

// To find orientation of ordered triplet (p, q, r).
// The function returns following values
// 0 --> p, q and r are colinear
// 1 --> Clockwise
// 2 --> Counterclockwise
func orientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> AngularOrientation {
    let val = (q.y - p.y) * (r.x - q.x) -
              (q.x - p.x) * (r.y - q.y);
  
    if (val == 0) {
        return .colinear
    }
    
    return val > 0 ? .clockwise : .counterclockwise
}

/// https://www.geeksforgeeks.org/convex-hull-set-1-jarviss-algorithm-or-wrapping/
/// For divide & conquer, see https://www.geeksforgeeks.org/convex-hull-using-divide-and-conquer-algorithm/
func convexHull(_ unordered: [CGPoint]) -> [CGPoint] {
    if unordered.isEmpty {
        return []
    }

    //differing from geeksforgeeks code: sort code so that first point is left bottommost
    let points = unordered.sorted(by: { (p1: CGPoint, p2: CGPoint) -> Bool in p1.y < p2.y || (p1.y == p2.y && p1.x < p2.x) })
    
    if points.count < 3 {
        return points
    }
    
    var hull: [CGPoint] = []
    
    let left = 0
    
    var p = left
    var q = 0
    
    repeat
    {
        hull.append(points[p])
        
        q = (p+1) % points.count
        
        for i in 0 ..< points.count {
            if orientation(points[p], points[i], points[q]) == .counterclockwise {
                q = i;
            }
        }

        p = q
  
    } while (p != left)
  
    return hull
}


/// Quadrilaterial defined using terminology of Eberly.
/// NOTE: points must be defined in the correct order! There's currently no convex hull or other method to enforce the correct order.
/// "The first convex quadrilateral has vertices p00, p10, p11 and p01, listed in counterclockwise order."
///             p11 (3rd)
///   p01 (4th)
///                 p10 (2nd)
///     p00 (1st)
struct Quadrilateral {
    var p00: CGPoint { point1}
    var p10: CGPoint { point2 }
    var p11: CGPoint { point3 }
    var p01: CGPoint { point4 }
    
    var point1: CGPoint
    var point2: CGPoint
    var point3: CGPoint
    var point4: CGPoint

    var points: [CGPoint] {
        [point1, point2, point3, point4]
    }
    
    /// Ensure points are ordered counterclosewise, with point1 (p00) at bottom left.
    /// This assumes CG coordinates, with the origin at bottom left, +x right, +y up
    /// A suitable ordering function would be a traditional convex hull.
    mutating func orderPoints(_ orderingFunction: ([CGPoint]) -> [CGPoint]) {
        let ordered = orderingFunction(points)
        point1 = ordered[0]
        point2 = ordered[1]
        point3 = ordered[2]
        point4 = ordered[3]
    }
}

/// Three points nominally defining a triangle, but possibly colinear.
/// Used as an argument to the function SAM.transform(t1:t2:)
struct Triangle {
    var point1: CGPoint
    var point2: CGPoint
    var point3: CGPoint
    
    var x1: CGFloat { point1.x }
    var y1: CGFloat { point1.y }
    var x2: CGFloat { point2.x }
    var y2: CGFloat { point2.y }
    var x3: CGFloat { point3.x }
    var y3: CGFloat { point3.y }
    
    /// Point1 as a 2D vector
    var vector1: CGVector { CGVector(point1) }
    
    /// Point2 as a 2D vector
    var vector2: CGVector { CGVector(point2) }
    
    /// Point3 as a 2D vector
    var vector3: CGVector { CGVector(point3) }
    
    /// Return a Triangle after applying an affine transform to self.
    func applying(_ t: CGAffineTransform) -> Triangle {
        Triangle(
            point1: self.point1.applying(t),
            point2: self.point2.applying(t),
            point3: self.point3.applying(t)
        )
    }
    
    init(point1: CGPoint, point2: CGPoint, point3: CGPoint) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
    }
    
    init(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, x3: CGFloat, y3: CGFloat) {
        point1 = CGPoint(x: x1, y: y1)
        point2 = CGPoint(x: x2, y: y2)
        point3 = CGPoint(x: x3, y: y3)
    }
    
    /// Returns a (Bool, CGFloat) tuple indicating whether the points in the Triangle are colinear, and the angle between vectors tested.
    func colinear(degreesTolerance: CGFloat = 0.5) -> Bool {
        let v1 = vector2 - vector1
        let v2 = vector3 - vector2
        let radians = CGVector.angleBetweenVectors(v1: v1, v2: v2)
        
        if radians.isNaN {
            return true
        }
        
        var degrees = radiansToDegrees(radians)
        
        if degrees > 90 {
           degrees = 180 - degrees
        }
        
        return degrees < degreesTolerance
    }
    
    /// | p1.x    p2.x      p3.x |
    /// | p1.y    p2.y      p3.y |
    /// |   1       1            1    |
    func toMatrix() -> Matrix3x3 {
        Matrix3x3(
            m11: point1.x, m12: point2.x, m13: point3.x,
            m21: point1.y, m22: point2.y, m23: point3.y,
            m31: 1, m32: 1, m33: 1)
    }
}

func affineTransform(from: Triangle, to: Triangle) -> Matrix3x3? {
    // following example from https://stackoverflow.com/questions/18844000/transfer-coordinates-from-one-triangle-to-another-triangle
    // M * A = B
    // M = B * Inv(A)
    let A = from.toMatrix()
    
    guard let invA = A.inverted() else {
        return nil
    }
    
    let B = to.toMatrix()
    let M = B * invA
    
    return M
}

func cgAffineTransform(from: Triangle, to: Triangle) -> CGAffineTransform? {
    guard let M = affineTransform(from: from, to: to) else {
        return nil
    }
    return M.toCGAffineTransform()
}
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
