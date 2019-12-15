import Foundation

public class DegreeList: Codable {
  public var degrees: [Int]

  public init() {
    self.degrees = []
  }

  public init(degrees: [Int]) {
    self.degrees = degrees
  }

  public init(fromVarIndex varIndex: Int) {
    self.degrees = [Int](repeating: 0, count: varIndex+1)
    self.degrees[varIndex] = 1
  }

  public func copy() -> DegreeList {
    return DegreeList(degrees: self.degrees)
  }

  public func degree() -> Int {
    return degrees.reduce(0, +)
  }

  public static func *(_ left: DegreeList, _ right: DegreeList) -> DegreeList {
    var degrees: [Int]
    var dl: DegreeList
    if left.degrees.count < right.degrees.count {
      degrees = right.degrees
      dl = left
    } else {
      degrees = left.degrees
      dl = right
    }
    for i in 0..<dl.degrees.count {
      degrees[i] += dl.degrees[i]
    }
    return DegreeList(degrees: degrees)
  }

  public static func *=(
      _ left: inout DegreeList, _ right: DegreeList) {
    for i in 0..<min(left.degrees.count, right.degrees.count) {
      left.degrees[i] += right.degrees[i]
    }
    if left.degrees.count < right.degrees.count {
      left.degrees += right.degrees.suffix(left.degrees.count)
    }
  }

  public func mergeMax(_ dl: DegreeList) {
    for i in 0..<min(degrees.count, dl.degrees.count) {
      degrees[i] = max(degrees[i], dl.degrees[i])
    }
    if dl.degrees.count > degrees.count {
      degrees.append(contentsOf: dl.degrees[degrees.count..<dl.degrees.count])
    }
  }
}

extension DegreeList: Comparable {
  static func compare(_ left: DegreeList, _ right: DegreeList) -> Int {
    let dl = left.degree()
    let dr = right.degree()
    if dl != dr {
      // Highest degree comes first
      return dr - dl
    }
    // The total degree is equal, so if the individual degrees aren't, we are
    // guaranteed to find a difference in the first degreeCount entries.
    let degreeCount = min(left.degrees.count, right.degrees.count)
    for i in 0..<degreeCount {
      if left.degrees[i] != right.degrees[i] {
        return (right.degrees[i] - left.degrees[i])
      }
    }
    return 0
  }

  public static func ==(_ left: DegreeList, _ right: DegreeList) -> Bool {
    return (compare(left, right) == 0)
  }

  public static func <(_ left: DegreeList, _ right: DegreeList) -> Bool {
    return (compare(left, right) < 0)
  }
}

public final class Monomial<R: Ring>: Codable {
  public var coefficient: R
  public var degreeList: DegreeList

  public init(coefficient: R, degrees: [Int]) {
    self.coefficient = coefficient
    self.degreeList = DegreeList(degrees: degrees)
  }

  public init(coefficient: R, degreeList: DegreeList) {
    self.coefficient = coefficient
    self.degreeList = degreeList.copy()
  }

  public init(fromVarIndex varIndex: Int) {
    self.coefficient = R.one
    self.degreeList = DegreeList(fromVarIndex: varIndex)
  }

  public func copy() -> Monomial {
    return Monomial(coefficient: coefficient, degrees: degreeList.degrees)
  }

  public static func ==(_ left: Monomial, _ right: Monomial) -> Bool {
    return left.coefficient == right.coefficient &&
        left.degreeList == right.degreeList
  }

  public static func !=(_ left: Monomial, _ right: Monomial) -> Bool {
    return !(left == right)
  }
}

extension Monomial: CustomStringConvertible {
  public var description: String {
    var elements: [String] = []
    if degreeList.degree() == 0 || coefficient != R.one {
      elements.append(coefficient.description)
    }
    for i in 0..<degreeList.degrees.count {
      if degreeList.degrees[i] == 1 {
        elements.append("X\(i)")
      } else if degreeList.degrees[i] > 1 {
        elements.append("X\(i)^\(degreeList.degrees[i])")
      }
    }
    return elements.joined(separator: " ")
  }
}

public final class Interval<R: Ring & Comparable>: Algebra {
  public typealias BaseRing = R
  public var min: R
  public var max: R

  public init(_ min: R, _ max: R) {
    self.min = min.copy()
    self.max = max.copy()
  }

  public init(_ value: Int) {
    self.min = R(value)
    self.max = R(value)
  }

  public static var zero: Interval {
    return Interval(BaseRing.zero, BaseRing.zero)
  }

  public static var one: Interval {
    return Interval(BaseRing.one, BaseRing.one)
  }

  public func copy() -> Interval {
    return Interval(min, max)
  }

  public static func +(_ left: Interval, _ right: Interval) -> Interval {
    return Interval(left.min + right.min, left.max + right.max)
  }

  public static prefix func -(_ interval: Interval) -> Interval {
    return Interval(-interval.max, -interval.min)
  }

  public static func -(_ left: Interval, _ right: Interval) -> Interval {
    return left + (-right)
  }

  public static func *(_ left: Interval, _ right: Interval) -> Interval {
    let vals = [left.min * right.min, left.min * right.max,
                left.max * right.min, left.max * right.max]
    return Interval(vals.min()!, vals.max()!)
  }

  public static func ==(_ left: Interval, _ right: Interval) -> Bool {
    return (left.min == right.min && left.max == right.max)
  }

  public func times(_ v: BaseRing) -> Interval {
    if v < BaseRing.zero {
      return Interval(v * self.max, v * self.min)
    }
    return Interval(v * self.min, v * self.max)
  }

  public func width() -> R {
    return max - min
  }

  public var description: String {
    return "Interval[\(min), \(max)]"
  }
}

public extension Interval where R: Field {
  func center() -> R {
    return (self.min + self.max) / R(2)
  }
}

enum PolynomialError: Error {
  case inversionError
}

public final class
    Polynomial<R: Ring>: Codable, Algebra, CustomStringConvertible {
  public typealias BaseRing = R
  var terms: [Monomial<R>]  // Invariant: sorted

  public init(terms: [Monomial<R>]) {
    self.terms = terms
  }

  public init(fromScalar scalar: R) {
    if scalar == R.zero {
      self.terms = []
    } else {
      self.terms = [Monomial(coefficient: scalar, degrees: [])]
    }
  }

  public init (fromVarIndex varIndex: Int) {
    self.terms = [Monomial(fromVarIndex: varIndex)]
  }

  public convenience init(_ value: Int) {
    self.init(fromScalar: R(value))
  }

  public static var zero: Polynomial {
    return Polynomial(terms: [])
  }

  public static var one: Polynomial {
    return Polynomial(terms: [Monomial(coefficient: R.one, degrees: [])])
  }

  public func copy() -> Polynomial {
    return Polynomial(terms: terms.map {$0.copy()})
  }

  public static func +(_ left: Polynomial, _ right: Polynomial) -> Polynomial {
    var newTerms: [Monomial<R>] = []
    var li = 0
    var ri = 0
    while li < left.terms.count || ri < right.terms.count {
      if li >= left.terms.count {
        newTerms.append(right.terms[ri])
        ri += 1
      } else if ri >= right.terms.count {
        newTerms.append(left.terms[li])
        li += 1
      } else if left.terms[li].degreeList < right.terms[ri].degreeList {
        newTerms.append(left.terms[li])
        li += 1
      } else if right.terms[ri].degreeList < left.terms[li].degreeList {
        newTerms.append(right.terms[ri])
        ri += 1
      } else {
        let newCoefficient =
            left.terms[li].coefficient + right.terms[ri].coefficient
        if newCoefficient != R.zero {
          newTerms.append(Monomial(
              coefficient: newCoefficient,
              degreeList: left.terms[li].degreeList))
        }
        li += 1
        ri += 1
      }
    }
    return Polynomial(terms: newTerms)
  }

  public static prefix func -(_ poly: Polynomial) -> Polynomial {
    let result = poly.copy()
    for t in result.terms {
      t.coefficient = -t.coefficient
    }
    return result
  }

  public func times(_ r: R) -> Polynomial {
    if r == R.zero {
      return Polynomial.zero
    }
    let result = self.copy()
    for t in result.terms {
      t.coefficient = r * t.coefficient
    }
    return result
  }

  public func timesMonomial(_ m: Monomial<R>) -> Polynomial {
    if m.coefficient == R.zero {
      return Polynomial.zero
    }
    let result = self.copy()
    for t in result.terms {
      t.coefficient = m.coefficient * t.coefficient
      t.degreeList = m.degreeList * t.degreeList
    }
    return result
  }

  public static func -(_ left: Polynomial, _ right: Polynomial) -> Polynomial {
    return left + (-right)
  }

  public static func *(_ left: Polynomial, _ right: Polynomial) -> Polynomial {
    if left.terms.count <= 5 || right.terms.count <= 5 {
      var total = Polynomial.zero
      for t in left.terms {
        total += right.timesMonomial(t)
      }
      return total
    }
    let maxDegrees = left.termCeiling() * right.termCeiling()
    // This wouldn't work for high-degree polys, but we don't need those
    // right now.
    var curStride = 1
    var stride: [Int] = [curStride]
    for i in 0..<maxDegrees.degrees.count {
      curStride *= maxDegrees.degrees[i] + 1
      stride.append(curStride)
    }
    let bufferSize = curStride
    var resultCoeffs = [R](repeating: R.zero, count: bufferSize)
    for lt in left.terms {
      for rt in right.terms {
        var index = 0
        for (i, d) in lt.degreeList.degrees.enumerated() {
          index += d * stride[i]
        }
        for (i, d) in rt.degreeList.degrees.enumerated() {
          index += d * stride[i]
        }
        resultCoeffs[index] += lt.coefficient * rt.coefficient
      }
    }
    var newTerms: [Monomial<R>] = []
    for i in 0..<bufferSize {
    if resultCoeffs[i] != R.zero {
        var degrees: [Int] = []
        for j in 0..<maxDegrees.degrees.count {
          degrees.append((i % stride[j+1]) / stride[j])
        }
        newTerms.append(
            Monomial(coefficient: resultCoeffs[i], degrees: degrees))
      }
    }
    newTerms.sort(by: {$0.degreeList < $1.degreeList})
    return Polynomial(terms: newTerms)
  }

  public static func ==(_ left: Polynomial, _ right: Polynomial) -> Bool {
    if left.terms.count != right.terms.count {
      return false
    }
    for i in 0..<left.terms.count {
      if left.terms[i] != right.terms[i] {
        return false
      }
    }
    return true
  }

  public func degree() -> Int {
    let degrees = terms.map {$0.degreeList.degree()}
    if degrees.count == 0 {
      return 0
    }
    return degrees.max()!
  }

  public var description: String {
    if terms.isEmpty {
      return "0"
    }
    let termDescriptions: [String] = terms.map {$0.description}
    return termDescriptions.joined(separator: " + ")
  }

  public func termCeiling() -> DegreeList {
    let dl = DegreeList()
    for term in terms {
      dl.mergeMax(term.degreeList)
    }
    return dl
  }

  public func invertThrough(zeroTerm: DegreeList) -> Polynomial {
    let result = self.copy()
    for t in result.terms {
      for i in 0..<min(t.degreeList.degrees.count, zeroTerm.degrees.count) {
        if t.degreeList.degrees[i] > zeroTerm.degrees[i] {
          NSLog("Uh-oh")
        }
        t.degreeList.degrees[i] =
            zeroTerm.degrees[i] - t.degreeList.degrees[i]
      }
      if zeroTerm.degrees.count > t.degreeList.degrees.count {
        for i in t.degreeList.degrees.count..<zeroTerm.degrees.count {
          t.degreeList.degrees.append(zeroTerm.degrees[i])
        }
      }
    }
    result.terms.sort { (m1, m2) -> Bool in
      m1.degreeList < m2.degreeList
    }
    return result
  }

  public func evaluate(vars: [R]) -> R {
    var total = R.zero
    var values = [[R]](repeating: [R.one], count: vars.count)
    for t in self.terms {
      var termTotal = t.coefficient
      for i in 0..<t.degreeList.degrees.count {
        let degree = t.degreeList.degrees[i]
        while values[i].count <= degree {
          values[i].append(values[i][values[i].count - 1] * vars[i])
        }
        termTotal = termTotal * values[i][degree]
      }
      total = total + termTotal
    }
    return total
  }

  public func evaluate<A: Algebra>(vars: [A]) -> A where A.BaseRing == R {
    var total = A.zero
    var values = [[A]](repeating: [A.one], count: vars.count)
    for t in self.terms {
      var termTotal = A.one
      for i in 0..<t.degreeList.degrees.count {
        let degree = t.degreeList.degrees[i]
        while values[i].count <= degree {
          values[i].append(values[i][values[i].count - 1] * vars[i])
        }
        termTotal = termTotal * values[i][degree]
      }
      total = total + termTotal.times(t.coefficient)
    }
    return total
  }
}

extension Polynomial where R: Comparable {
  public func evalInterval(vars: [Interval<R>]) -> Interval<R> {
    typealias I = Interval<R>
    var total = I.zero
    var values = [[I]](repeating: [I.one], count: vars.count)
    for t in self.terms {
      var termTotal = I.one
      for i in 0..<t.degreeList.degrees.count {
        let degree = t.degreeList.degrees[i]
        while values[i].count <= degree {
          let v = values[i][values[i].count - 1] * vars[i]
          if values[i].count % 2 == 0 {
            v.min = R.zero
          }
          values[i].append(v)
        }
        termTotal = termTotal * values[i][degree]
      }
      total = total + termTotal.times(t.coefficient)
    }
    return total
  }
}
