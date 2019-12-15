public class Matrix3x3<k: Field> {
  public let elements: [k]

  public init?(_ elements: [k]) {
    if elements.count != 9 {
      return nil
    }
    self.elements = elements
  }

  public func row(_ index: Int) -> Vec3<k> {
    let r = Mod3(index)
    return Vec3(x: elements[r*3], y: elements[r*3 + 1], z: elements[r*3 + 2])
  }

  public func column(_ index: Int) -> Vec3<k> {
    let c = Mod3(index)
    return Vec3(x: elements[c], y: elements[3 + c], z: elements[6 + c])
  }

  subscript(row: Int, column: Int) -> k {
    return elements[3 * Mod3(row) + Mod3(column)]
  }

  public static func *(_ m0: Matrix3x3, _ m1: Matrix3x3) -> Matrix3x3 {
    let m0Elements = m0.elements
    let m1Elements = m1.elements
    var productElements = [k](repeating: k.zero, count: 9)
    for row in 0..<3 {
      for column in 0..<3 {
        productElements[row*3 + column] = (
            m0Elements[row*3 + 0] * m1Elements[0*3 + column] +
            m0Elements[row*3 + 1] * m1Elements[1*3 + column] +
            m0Elements[row*3 + 2] * m1Elements[2*3 + column])
      }
    }
    return Matrix3x3(productElements)!
  }

  public static func *(_ v: Vec3<k>, _ m: Matrix3x3) -> Vec3<k> {
    //return Vec3((0..<3).map { i in v.dot(m.column(i)) })
    let elements = m.elements
    return Vec3<k>(
      x: v[0] * elements[0] + v[1] * elements[3] + v[2] * elements[6],
      y: v[0] * elements[1] + v[1] * elements[4] + v[2] * elements[7],
      z: v[0] * elements[2] + v[1] * elements[5] + v[2] * elements[8])
  }

  public static func *(_ m: Matrix3x3, _ v: Vec3<k>) -> Vec3<k> {
    let elements = m.elements
    return Vec3<k>(
        x: elements[0] * v[0] + elements[1] * v[1] + elements[2] * v[2],
        y: elements[3] * v[0] + elements[4] * v[1] + elements[5] * v[2],
        z: elements[6] * v[0] + elements[7] * v[1] + elements[8] * v[2])
  }

  public static func /(_ m: Matrix3x3, _ scalar: k) -> Matrix3x3 {
    return Matrix3x3(m.elements.map { x in x / scalar })!
  }

  public static func +(_ m0: Matrix3x3, _ m1: Matrix3x3) -> Matrix3x3 {
    return Matrix3x3((0..<9).map { i in
      m0.elements[i] + m1.elements[i]
    })!
  }

  public static func -(_ m0: Matrix3x3, _ m1: Matrix3x3) -> Matrix3x3 {
    return Matrix3x3((0..<9).map { i in
      m0.elements[i] - m1.elements[i]
    })!
  }

  public static prefix func -(_ m: Matrix3x3) -> Matrix3x3 {
    return Matrix3x3(m.elements.map { x in -x })!
  }

  public static func *(_ scalar: k, _ m: Matrix3x3) -> Matrix3x3 {
    return Matrix3x3(m.elements.map { x in scalar * x })!
  }

  public static func *(_ m: Matrix3x3, _ scalar: k) -> Matrix3x3 {
    return Matrix3x3(m.elements.map { x in scalar * x })!
  }
  
  // computes the determinant of the 2x2 minor induced by removing the
  // given row and column
  private func _minor(row: Int, column: Int) -> k {
    let r0 = (row + 1) % 3
    let r1 = (row + 2) % 3
    let c0 = (column + 1) % 3
    let c1 = (column + 2) % 3
    return (
      elements[3 * r0 + c0] * elements[3 * r1 + c1] -
        elements[3 * r1 + c0] * elements[3 * r0 + c1])
  }
  
  public func determinant() -> k {
    let components = (0..<3).map { row in
      self[row, 0] * _minor(row: row, column: 0)
    }
    return components.reduce(k.zero, +)
  }
  
  public func inverse() -> Matrix3x3? {
    let det = determinant()
    if det == k.zero {
      // there is no inverse
      return nil
    }
    var inverseElements = [k](repeating: k.zero, count: 9)
    for row in 0..<3 {
      for column in 0..<3 {
        inverseElements[row*3 + column] = _minor(row: column, column: row) / det
      }
    }
    return Matrix3x3(inverseElements)!
  }
}

extension Matrix3x3: CustomStringConvertible {
  public var description: String {
    let descs = elements.map { e in e.description }
    let rows = (0..<3).map { r in
      descs[r * 3..<(r+1) * 3].joined(separator: " ")
    }
    return "[" + rows.joined(separator: " | ") + "]"
  }
}

public extension Matrix3x3 {

  static func identity() -> Matrix3x3<k> {
    return Matrix3x3([
        k.one, k.zero, k.zero,
        k.zero, k.one, k.zero,
        k.zero, k.zero, k.one])!
  }

  // affine translation in the xy plane
  static func translation(_ t: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3([
        k.one, k.zero, t.x,
        k.zero, k.one, t.y,
        k.zero, k.zero, k.one])!
  }

  // reflects thru a line (ax + by = 0) expressed as (a, b)
  static func reflectionThru(lineThruOrigin line: Vec2<k>) -> Matrix3x3<k> {
    let squaredNorm = line.x * line.x + line.y * line.y
    // the
    let projectionOffset = Matrix3x3([
        line.x * line.x, line.x * line.y, k.zero,
        line.x * line.y, line.y * line.y, k.zero,
        k.zero, k.zero, k.zero
    ])!
    return Matrix3x3.identity() - k(2) * projectionOffset / squaredNorm
  }

  // complex multiplication by the given value in the affine xy plane
  static func complexMultiplication(_ z: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3([
        z.x, -z.y, k.zero,
        z.y, z.x, k.zero,
        k.zero, k.zero, k.one])!
  }

  static func complexDivision(_ z: Vec2<k>) -> Matrix3x3<k> {
    return complexMultiplication(z.complexInverse())
  }

  /*static func reflectionThruX() -> Matrix3x3<k> {
    return Matrix3x3([
      k.one, k.zero, k.zero,
      k.zero, -k.one, k.zero,
      k.zero, k.zero, k.one])!
  }*/

  func reflectedThru(lineThruOrigin line: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3<k>.reflectionThru(lineThruOrigin: line) * self
  }

  func translatedBy(_ t: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3<k>.translation(t) * self
  }

/*  func reflectedThruX() -> Matrix3x3<k> {
    return Matrix3x3<k>.reflectionThruX() * self
  }*/

  func timesComplex(_ z: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3<k>.complexMultiplication(z) * self
  }

  func dividedByComplex(_ z: Vec2<k>) -> Matrix3x3<k> {
    return Matrix3x3<k>.complexDivision(z) * self
  }
}
