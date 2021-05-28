import Foundation
//import CoreGraphics

typealias k = GmpRational

/*let colors = [
  CGColor(red: 0.975, green: 0.510, blue: 0.557, alpha: 1.0),
  CGColor(red: 0.843, green: 0.486, blue: 0.631, alpha: 1.0),
  CGColor(red: 0.667, green: 0.486, blue: 0.663, alpha: 1.0),
  CGColor(red: 0.471, green: 0.482, blue: 0.643, alpha: 1.0),
  CGColor(red: 0.278, green: 0.467, blue: 0.572, alpha: 1.0),
  CGColor(red: 0.125, green: 0.435, blue: 0.466, alpha: 1.0),
]
*/
extension Vec2 where R: Numeric {
  public func asCGPoint() -> CGPoint {
		return CGPoint(x: x.asDouble(), y: y.asDouble())
  }
}

extension Double {
  public func clamp(min: Double, max: Double) -> Double {
    if self <= min {
      return min
    }
    if self >= max {
      return max
    }
    return self
  }
}
