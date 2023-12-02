import CoreGraphics
import Foundation
import simd

// Run the whole playground! The perspectiveTransform() function at top depends on types defined below.
// At the bottom is a test function that writes to the console.

/// Find the perspective transform (the homography) from quadrilateral p to quadrilateral q.
/// Algorithm based on PerspectiveMappings.pdf by Dave Eberly:
/// https://geometrictools.com/Documentation/PerspectiveMappings.pdf
/// See also Geometric Tools for Computer Graphics by Schneider & Eberly:
/// https://www.geometrictools.com/Books/Books.html
/// Code uses SIMD types. An extension to CGPoint provides conversions.
func perspectiveTransform(from: Quadrilateral, to: Quadrilateral) -> (transform: float3x3, pOrdered: Quadrilateral, qOrdered: Quadrilateral)? {
    //Use the convex hull to order points counterclockwise, then reorder so that index 0 is closest to origin
    let p = from.toOrderedQuadrilateral(convexHull(_:))
    let q = to.toOrderedQuadrilateral(convexHull(_:))
    
    //points of canonical quadrilateral used to calculate affine transform
    let canon = Triangle(simd_float2(0,0), simd_float2(1,0), simd_float2(0,1))
    
    //affine transform from canonical quadrilateral to p using points 00, 10, 01 but not 11
    let ptri = Triangle(p.v00, p.v10, p.v01)
    
    guard let Ap = affineTransform(from: canon, to: ptri) else {
        print("Could not get affine transform for quadrilateral p")
        return nil
    }
    
    //affine transform from canonical quadrilateral to q using points 00, 10, 01 but not 11
    let qtri = Triangle(q.v00, q.v10, q.v01)

    guard let Aq = affineTransform(from: canon, to: qtri) else {
        print("Could not get affine transform for quadrilateral q")
        return nil
    }
    
    let InvAp = Ap.inverse
    
    if InvAp.determinant.isNaN  {
        print("Could not get inverse of affine transform for quadrilateral p")
        return nil
    }
    
    let InvAq = Aq.inverse
    
    if InvAq.determinant.isNaN {
        print("Could not get inverse of affine transform for quadrilateral q")
        return nil
    }
    
    // (a,b) is coordinate of p11 in canonical quadrilateral
    // (c,d) is coordinate of q11 in canonical quadrilateral
    let ap11 = InvAp * p.v11           // (x,y,1)
    let aq11 = InvAq * q.v11
    
    let cp11 = ap11.toVector2()     // (x,y) in 2D plane
    let cq11 = aq11.toVector2()
    
    let a = cp11.x
    let b = cp11.y
    let c = cq11.x
    let d = cq11.y

    let s = a + b - 1       // p is convex if s > 0
    let t = c + d - 1       // q is convex if t > 0

    let pconvex = s > 0
    let qconvex = t > 0
    
    if !pconvex || !qconvex {
        print("p is \(pconvex ? "convex" : "NOT convex"), s = \(s)")
        print("q is \(qconvex ? "convex" : "NOT convex"), t = \(t)")
        return nil
    }
    
    //fractional linear transformation F from canonical p to canonical q
    
    // F = | bcs                   0    0   |
    //     |   0                 ads    0   |
    //     | b(cs - at)   a(ds - bt)    abt |
    // where
    // s = a + b - 1
    // t = c + d - 1

    // initialize float3x3 by columns
    let F = float3x3(
        simd_float3(b * c * s,  0,          b * (c * s - a * t)),
        simd_float3(0,          a * d * s,  a * (d * s - b * t)),
        simd_float3(0,          0,          a * b * t)
    )
    
    //"The 3 × 3 homography matrix H = Aq * F * Inv(Ap)"
    let H = Aq * F * InvAp
    
    //return transform along with ordered quadrilaterals
    return (H, p, q)
}

/// Finds the affine transform (translation, rotation, scale, ...) from one triangle to another.
/// Used in perspectiveTransform( ).
func affineTransform(from: Triangle, to: Triangle) -> float3x3? {
    // following example from https://stackoverflow.com/questions/18844000/transfer-coordinates-from-one-triangle-to-another-triangle
    // M * A = B
    // M = B * Inv(A)
    let A = from.toMatrix()
    let invA = A.inverse
    
    if invA.determinant.isNaN {
        return nil
    }
    
    let B = to.toMatrix()
    let M = B * invA
    
    return M
}

func degreesToRadians(_ degrees: Float) -> Float {
    degrees * Float.pi / 180.0
}

func radiansToDegrees(_ radians: Float) -> Float {
    180.0 * radians / Float.pi
}

// Returns angle between two 2D vectors in range 0 to 2 * pi [positive]
// a * b = ||a|| ||b|| cos(theta)
// theta = arc cos (a * b / ||a|| ||b||)
func angleBetweenVectors(_ v1: simd_float2, _ v2: simd_float2) -> Float {
    acos(simd_dot(v1, v2) / (simd_length(v1) * simd_length(v1)))
}

// Conversions to/from CGPoint for use with CGImage and SIMD matrix operations.
extension CGPoint {
    /// A 1x2 vector of the point: (x, y)
    var vector2: simd_float2 {
        simd_float2(Float(self.x), Float(self.y))
    }
    
    /// A 1x3 vector of the point (x, y, 1)
    var vector3: simd_float3 {
        simd_float3(Float(self.x), Float(self.y), Float(1))
    }
    
    /// Returns a point (v.x, v.y)
    static func fromVector2(_ v: simd_float2) -> CGPoint {
        CGPoint(x: CGFloat(v.x), y: CGFloat(v.y))
    }
    
    /// Returns a point (x, y) = (v.x / v.z, v.y / v.z)
    /// Returns {x +∞, y +∞} if v.z == 0
    static func fromVector3(_ v: simd_float3) -> CGPoint {
        CGPoint(x: CGFloat(v.x / v.z), y: CGFloat(v.y / v.z))
    }
}

// Conversions between 2D points and 1x3 homogeneous coordinates.
extension simd_float2 {
    /// Returns (inf, inf) if v.z == 0
    static func fromVector3(_ v: simd_float3) -> simd_float2 {
        simd_float2(v.x / v.z, v.y / v.z)
    }
    
    /// Returns (x, y, 1)
    func toVector3() -> simd_float3 {
        simd_float3(self.x, self.y, 1)
    }
}

// Conversions between 1x3 homogeneous coordinates and 2D points.
extension simd_float3 {
    /// Returns (x,y,1)
    static func fromVector2(_ v: simd_float2) -> simd_float3 {
        simd_float3(v.x, v.y, 1)
    }
    
    /// Returns (inf,inf) if v.z == 0
    func toVector2() -> simd_float2 {
        simd_float2(self.x / self.z, self.y / self.z)
    }
}

extension NumberFormatter {
    func string(_ m: simd_float2, _ digits: Int) -> String {
        "[\(string(m.x, digits)), \(string(m.y, digits))]"
    }
    
    func string(_ m: simd_float3, _ digits: Int) -> String {
        "[\(string(m.x, digits)), \(string(m.y, digits)), \(string(m.z, digits))]"
    }

    func string(_ m: float3x3, _ digits: Int) -> String {
        //SIMD: column, row (like x,y)

        "\(string(m[0][0], digits))  \(string(m[1][0], digits))  \(string(m[2][0], digits))"
        + "\n\(string(m[0][1], digits))  \(string(m[1][1], digits))  \(string(m[2][1], digits))"
        + "\n\(string(m[0][2], digits))  \(string(m[1][2], digits))  \(string(m[2][2], digits))"
    }
    
    func string(_ m: float4x4, _ digits: Int) -> String {
        "\(string(m[0][0], digits))  \(string(m[1][0], digits))  \(string(m[2][0], digits))  \(string(m[3][0], digits))"
        + "\n\(string(m[0][1], digits))  \(string(m[1][1], digits))  \(string(m[2][1], digits))  \(string(m[3][1], digits))"
        + "\n\(string(m[0][2], digits))  \(string(m[1][2], digits))  \(string(m[2][2], digits))  \(string(m[3][2], digits))"
        + "\n\(string(m[0][3], digits))  \(string(m[1][3], digits))  \(string(m[2][3], digits))  \(string(m[3][3], digits))"
    }

    func string(_ t: Triangle, _ digits: Int) -> String {
        "\(string(t.point1, digits)), \(string(t.point2, digits)), \(string(t.point3, digits))"
    }
    
    func string(_ q: Quadrilateral, _ digits: Int) -> String {
        "\(string(q.point1, digits)), \(string(q.point2, digits)), \(string(q.point3, digits)), \(string(q.point4, digits))"
    }
    
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
}

/// Takes an array of points and returns an array of points representing the "rubberband border" of those points,
/// ordered from the leftmost bottom point and then around counterclockwise.
/// https://en.wikipedia.org/wiki/Convex_hull
/// https://en.wikipedia.org/wiki/Convex_hull_algorithms
func convexHull(_ points: [simd_float2]) -> [simd_float2] {
    if points.isEmpty {
        return[]
    }
    
    // populate list in current order
    var pts = points
    var hull: [simd_float2] = []
    
    //move (leftmost) point with lowest y from from pts to hull
    var n = 0
    
    for i in 1 ..< pts.count {
        //here use Float == operator
        if pts[i].y < pts[n].y || (pts[i].y == pts[n].y && pts[i].x < pts[n].x) {
            n = i
        }
    }
    
    hull.append(pts.remove(at: n))
    
    //of remaining points, find point for which last hull point to sample point is smallest positive angle
    let angle = {
        (p1: simd_float2, p2: simd_float2) -> Float in
        let a = atan2(p2.y - p1.y, p2.x - p1.x)
        return a < 0 ? a + 2 * Float.pi : a
    }
    
    while pts.count > 0 {
        var n = 0
        
        for i in 0 ..< pts.count {
            if angle(hull.last!, pts[i]) < angle(hull.last!, pts[n]) {
                n = i
            }
        }
        
        hull.append(pts.remove(at: n))
    }
    
    return hull
}

/// Quadrilaterial defined using terminology of Eberly.
/// NOTE: points must be defined in the correct order! There's currently no convex hull or other method to enforce the correct order.
/// "The first convex quadrilateral has vertices p00, p10, p11 and p01, listed in counterclockwise order."
///             p11 (3rd)
///   p01 (4th)
///                 p10 (2nd)
///     p00 (1st)
struct Quadrilateral: CustomStringConvertible {
    /// 1x3 vector for point1
    var v00: simd_float3

    /// 1x3 vector for point2
    var v10: simd_float3
    
    /// 1x3 vector for point3
    var v11: simd_float3
    
    /// 1x3 vector for point4
    var v01: simd_float3
    
    /// Dependent on NumberFormatter extension. Mildly convenient.
    var description: String {
        let f = NumberFormatter()
        return f.string(self, descriptionDigits)
    }
    
    /// Digits used in description (e.g. if digits = 1, point1 (2,3) will be displayed as "(2.0, 3.0)"
    var descriptionDigits = 1
    
    /// v00 as a 2D point
    var point1: simd_float2 {
        get { v00.toVector2() }
        set { v00 = newValue.toVector3() }
    }

    /// v10 as a 2D point
    var point2: simd_float2 {
        get { v10.toVector2() }
        set { v10 = newValue.toVector3() }
    }

    /// v11 as a 2D point
    var point3: simd_float2 {
        get { v11.toVector2() }
        set { v11 = newValue.toVector3() }
    }
    
    /// v01 as a 2D point
    var point4: simd_float2 {
        get { v01.toVector2() }
        set { v01 = newValue.toVector3() }
    }

    var points: [simd_float2] {
        [point1, point2, point3, point4]
    }
    
    /// Initialize Quadrilateral using Eberly's terminology.
    init(v00: simd_float3, v10: simd_float3, v11: simd_float3, v01: simd_float3) {
        self.v00 = v00
        self.v10 = v10
        self.v11 = v11
        self.v01 = v01
    }
    
    /// Initialize Quadrilateral with 2D points 1, 2, 3, 4 assigned to v00, v10, v11, v01
    init(_ point1: simd_float2, _ point2: simd_float2, _ point3: simd_float2, _ point4: simd_float2) {
        self.v00 = point1.toVector3()
        self.v10 = point2.toVector3()
        self.v11 = point3.toVector3()
        self.v01 = point4.toVector3()
    }
    
    /// Ensure points are ordered counterclosewise, with point1 (p00) at bottom left.
    /// This assumes CG coordinates, with the origin at bottom left, +x right, +y up
    /// A suitable ordering function would be a traditional convex hull.
    mutating func orderPoints(_ orderCounterclockwise: ([simd_float2]) -> [simd_float2], anchor: simd_float2 = simd_float2(0,0)) {
        if points.isEmpty {
            return
        }
        
        let ccw = orderCounterclockwise(points)

        /// for 0th index, select point closest to the anchor point
        var index = 0
        
        for i in 1 ..< ccw.count {
            if simd_length(ccw[i] - anchor) < simd_length(ccw[index] - anchor) {
                index = i
            }
        }
        
        var ordered: [simd_float2] = []
        
        for i in 0 ..< ccw.count {
            ordered.append(ccw[(index + i) % ccw.count])
        }

        //for quick move operations, see https://stackoverflow.com/questions/36541764/how-to-rearrange-item-of-an-array-to-new-position-in-swift
        
        point1 = ordered[0]
        point2 = ordered[1]
        point3 = ordered[2]
        point4 = ordered[3]
    }

    /// | p1.x   p2.x   p3.x   p4.x  |
    /// | p1.y   p2.y   p3.y   p4.y  |
    /// |     1        1        1        1   |
    func toMatrix() -> float4x3 {
        float4x3(v00, v10, v11, v01)
    }
    
    /// Generates a new Quadrilateral with points ordered according to a counterclockwise ordering function and an anchor point.
    func toOrderedQuadrilateral(_ orderCounterclockwise: ([simd_float2]) -> [simd_float2], anchor: simd_float2 = simd_float2(0,0)) -> Quadrilateral {
        var q = self
        q.orderPoints(orderCounterclockwise, anchor: anchor)
        return q
    }
    
    /// Generates a random quadrilateral with points in the range (-magnitude, -magniture) to (+magnitude, +magnitude).
    static func randomQuadrilateral(_ magnitude: Float = 10) -> Quadrilateral {
        let randomPoint = { (mag: Float) -> simd_float2 in
            simd_float2(Float.random(in: -magnitude...magnitude), Float.random(in: -magnitude...magnitude))
        }
        return Quadrilateral(randomPoint(magnitude), randomPoint(magnitude), randomPoint(magnitude), randomPoint(magnitude))
    }
}

/// Three points nominally defining a triangle, but possibly colinear.
/// Used as an argument to the function SAM.transform(t1:t2:)
struct Triangle: CustomStringConvertible {
    var point1: simd_float2
    var point2: simd_float2
    var point3: simd_float2
    
    /// Dependent on NumberFormatter extension. Mildly convenient.
    var description: String {
        let f = NumberFormatter()
        return f.string(self, descriptionDigits)
    }
    
    /// Digits used in description (e.g. if digits = 1, point1 (2,3) will be displayed as "(2.0, 3.0)"
    var descriptionDigits = 1
    
    init(_ point1: simd_float2, _ point2: simd_float2, _ point3: simd_float2) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
    }
    
    init(_ vector1: simd_float3, _ vector2: simd_float3, _ vector3: simd_float3) {
        point1 = vector1.toVector2()
        point2 = vector2.toVector2()
        point3 = vector3.toVector2()
    }

    /// Three points are colinear if their determinant is zero. We assume close to colinear might as well be colinear.
    ///    | x1  x2  x3 |
    /// det | y1  y2  y3 |  = 0     -->    abs( det(M) )  < tolerance ?
    ///    |1 1  1 |
    func colinear(tolerance: Float = 0.01) -> Bool {
        let m = toMatrix()
        return abs(m.determinant) < tolerance
    }
    
    /// | p1.x    p2.x      p3.x |
    /// | p1.y    p2.y      p3.y |
    /// |   1       1            1    |
    func toMatrix() -> float3x3 {
        float3x3(point1.toVector3(), point2.toVector3(), point3.toVector3())
    }
}

/* TEST */

/// Returns a Quadrilateral with points randomly reordered. Used to test ordering functions.
func jumbleOrder(_ q: Quadrilateral) -> Quadrilateral {
    var pts = q.points
    
    for _ in 0 ..< 10 {
        let oldIndex = Int.random(in: 0 ..< pts.count)
        let newIndex = Int.random(in: 0 ..< pts.count)
        pts.insert(pts.remove(at: oldIndex), at: newIndex)
    }
    
    return Quadrilateral(pts[0], pts[1], pts[2], pts[3])
}

/// Calculate the transform. Print the transform, the quadrilaterals, and transformed points.
func printTransform(from: Quadrilateral, to: Quadrilateral) {
    print("p (from): \(from)")
    print("q (to): \(to)")
    
    guard let results = perspectiveTransform(from: from, to: to) else {
        print("Could not find transform of p and q")
        return
    }
    
    let H = results.transform
    let p = results.pOrdered
    let q = results.qOrdered
    
    let f = NumberFormatter()
    
    print()
    print("\(#function)")
    print("homography (perspective transform): does H * p(vertex) == q(vertex)?\n\(f.string(H, 2))")
    
    //apply 3x3 homography transform to vertices of p as 1x3 homogeneous coordinates (x,y,1)
    let hp00 = H * p.v00
    let hp10 = H * p.v10
    let hp11 = H * p.v11
    let hp01 = H * p.v01
    
    //convert to 2D point
    let cp00 = hp00.toVector2()
    let cp10 = hp10.toVector2()
    let cp11 = hp11.toVector2()
    let cp01 = hp01.toVector2()
    
    //expected results: the vertices of q as 2D points
    let eq00 = q.v00.toVector2()
    let eq10 = q.v10.toVector2()
    let eq11 = q.v11.toVector2()
    let eq01 = q.v01.toVector2()
    
    print()
    print("H * p00:")
    print("\(f.string(p.v00.toVector2(), 2)) p vertex  ")
    print("\(f.string(cp00, 2)) transformed")
    print("\(f.string(eq00, 2)) expected q vertex")
    print()
    print("H * p10:")
    print("\(f.string(p.v10.toVector2(), 2)) p vertex  ")
    print("\(f.string(cp10, 2)) transformed")
    print("\(f.string(eq10, 2)) expected q vertex")
    print()
    print("H * p11:")
    print("\(f.string(p.v11.toVector2(), 2)) p vertex  ")
    print("\(f.string(cp11, 2)) transformed")
    print("\(f.string(eq11, 2)) expected q vertex")
    print()
    print("H * p01:")
    print("\(f.string(p.v01.toVector2(), 2)) p vertex  ")
    print("\(f.string(cp01, 2)) calculated q vertex: H * [p vertex]")
    print("\(f.string(eq01, 2)) expected q vertex")
}

/// Prints debug information for a number of runs of printTransform(from:to:).
/// For each run the transform is calculated
/// 1. From p to q
/// 2. From p to q, after first randomly jumbling the point orders of the quadrilaterals
/// 3. From q to p
/// The first run uses known points for the quadrilaterals.
/// After the first run, random points are selected.
func testPerspectiveTransforms(_ runs: Int = 5) {
    var p = Quadrilateral(
        simd_float2(2, 1),
        simd_float2(6, 2),
        simd_float2(4, 5),
        simd_float2(1, 4))
    
    var q = Quadrilateral(
        simd_float2(1, 2),
        simd_float2(6, 1),
        simd_float2(5, 4),
        simd_float2(2, 5))
    
    for i in 1 ... runs {
        print("\n*** Test \(i) of \(runs) ***")
        print("* Test \(i)a: Transform p -> q")
        printTransform(from: p, to: q)
        print()
        print("* Test \(i)b: Jumbled point order")
        printTransform(from: jumbleOrder(p), to: jumbleOrder(q))
        print()
        print("* Test \(i)c: Transform q -> p (swap quadrilaterals)")
        printTransform(from: q, to: p)
        
        //after first run, randomize points
        p = Quadrilateral.randomQuadrilateral()
        q = Quadrilateral.randomQuadrilateral()
    }
}

testPerspectiveTransforms(6)
