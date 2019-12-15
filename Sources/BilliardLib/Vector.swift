import Foundation

public struct Vec2<R : Ring>: Codable, CanonicalNegation, Equatable {
  public let x : R
  public let y : R

  public init(x: R, y: R) {
    self.x = x
    self.y = y
  }

  public init(_ x: R, _ y: R) {
    self.x = x
    self.y = y
  }

  public static var origin: Vec2 {
    return Vec2(x: R.zero, y: R.zero)
  }

  public subscript(index: Int) -> R {
    if index % 2 == 0 {
      return x
    }
    return y
  }

  public func complexConjugate() -> Vec2 {
    return Vec2(x: x, y: -y)
  }

  public func complexConjugateBySign(_ s: Sign) -> Vec2 {
    switch s {
    case .positive: return self
    case .negative: return self.complexConjugate()
    }
  }

  public func complexMul(_ offset: Vec2) -> Vec2 {
    return Vec2(
      x: x * offset.x - y * offset.y, y: x * offset.y + y * offset.x)
  }

  public func dot(_ tc : Vec2) -> R {
    return self.x * tc.x + y * tc.y
  }

  public static func ==(_ left : Vec2, _ right : Vec2) -> Bool {
    return (left.x == right.x && left.y == right.y)
  }

  public func cross() -> Vec2 {
    return Vec2(x: -y, y: x)
  }

  public func squaredLength() -> R {
    return x * x + y * y
  }
}

public extension Vec2 {
  static func +(_ left: Vec2, _ right: Vec2) -> Vec2 {
    return Vec2(x: left.x + right.x, y: left.y + right.y)
  }

  static func -(_ left : Vec2, _ right : Vec2) -> Vec2 {
    return Vec2(x: left.x - right.x, y: left.y - right.y)
  }

  static prefix func -(_ v: Vec2) -> Vec2 {
    return Vec2(x: -v.x, y: -v.y)
  }

  static func *(_ r: R, _ v: Vec2) -> Vec2 {
    return Vec2(x: r * v.x, y: r * v.y)
  }

  static func *(_ v: Vec2, _ r: R) -> Vec2 {
    return Vec2(x: v.x * r, y: v.y * r)
  }

  static func *(_ s: Sign, _ v: Vec2) -> Vec2 {
    switch s {
    case .positive: return v
    case .negative: return -v
    }
  }

  static func *(_ v: Vec2, _ s: Sign) -> Vec2 {
    return s * v
  }
}

extension Vec2: CustomStringConvertible {
  public var description: String {
    return "(x: \(x) y: \(y))"
  }
}

public extension Vec2 where R: Field {
  func complexInverse() -> Vec2 {
    return self.complexConjugate() * self.squaredLength().inverse()
  }

  func complexDividedBy(_ offset: Vec2) -> Vec2 {
    return self.complexMul(offset.complexInverse())
  }

  func reflectThroughLine(from: Vec2, to: Vec2) -> Vec2 {
    let lv_x: R = to.x - from.x
    let lv_y: R = to.y - from.y

    let cv_x: R = self.x - from.x
    let cv_y: R = self.y - from.y

    let num: R = cv_x * lv_x + cv_y * lv_y
    let den: R = lv_x * lv_x + lv_y * lv_y
    let projectionCoeff: R = num / den

    let pv_x = projectionCoeff * lv_x
    let pv_y = projectionCoeff * lv_y
    let pc_x = from.x + pv_x
    let pc_y = from.y + pv_y
    return Vec2(x: pc_x + pv_x - cv_x, y: pc_y + pv_y - cv_y)
  }
}

public final class Vec3<R: Ring>: CanonicalNegation, Equatable {
  private let _v: [R]

  public init(x: R, y: R, z: R) {
    _v = [x, y, z]
  }

  public init(_ x: R, _ y: R, _ z: R) {
    _v = [x, y, z]
  }

  public init(affineXY v: Vec2<R>) {
    _v = [v.x, v.y, R.one]
  }

  public convenience init(_ v: [R]) {
    self.init(x: v[0], y: v[1], z: v[2])
  }

  public var x: R {
    return _v[0]
  }

  public var y: R {
    return _v[1]
  }

  public var z: R {
    return _v[2]
  }

  public subscript(index: Int) -> R {
    return _v[Mod3(index)]
  }

  public static var origin: Vec3 {
    return Vec3(x: R.zero, y: R.zero, z: R.zero)
  }

  public func rotatedBy(offset: Int) -> Vec3 {
    return Vec3(x: self[offset], y: self[offset + 1], z: self[offset + 2])
  }

  public static func ==(
      _ left : Vec3, _ right : Vec3) -> Bool {
    return (left.x == right.x && left.y == right.y && left.z == right.z)
  }
}

public extension Vec3 {
  static func +(_ left: Vec3, _ right: Vec3) -> Vec3 {
    return Vec3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
  }

  static func -(_ left : Vec3, _ right : Vec3) -> Vec3 {
    return Vec3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
  }

  static prefix func -(_ v: Vec3) -> Vec3 {
    return Vec3(x: -v.x, y: -v.y, z: -v.z)
  }

  static func *(_ r: R, _ v: Vec3) -> Vec3 {
    return Vec3(x: r * v.x, y: r * v.y, z: r * v.z)
  }

  static func *(_ v: Vec3, _ r: R) -> Vec3 {
    return Vec3(x: v.x * r, y: v.y * r, z: v.z * r)
  }
}

public extension Vec3 {
  func dot(_ v: Vec3) -> R {
    return x * v.x + y * v.y + z * v.z
  }

  func cross(_ v: Vec3) -> Vec3 {
    return Vec3(
      x: y * v.z - v.y * z,
      y: z * v.x - v.z * x,
      z: x * v.y - v.x * y)
  }
}

extension Vec3: CustomStringConvertible {
  public var description: String {
    return "Vec3(\(x.description), \(y.description), \(z.description))"
  }
}

public class TangentCoords2d<R : Ring> {
  let _base: Vec2<R>
  let _vector: Vec2<R>

  public init(base: Vec2<R>, vector: Vec2<R>) {
    _base = base
    _vector = vector
  }

  public init(from: Vec2<R>, to: Vec2<R>) {
    _base = from
    _vector = to - from
  }

  var base: Vec2<R> {
    return _base
  }
  var vector: Vec2<R> {
    return _vector
  }
}
