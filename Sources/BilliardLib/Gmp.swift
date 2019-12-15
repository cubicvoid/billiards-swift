import Foundation
import CGmp

public final class GmpInt: Codable {
  var n: __mpz_struct

  private init() {
    n = __mpz_struct()
    __gmpz_init(&n)
  }

  public init(_ value: Int) {
    n = __mpz_struct()
    __gmpz_init(&n)
    __gmpz_set_si(&n, value)
  }

  public init(fromString str: String) {
    n = __mpz_struct()
    __gmpz_init(&n)
    __gmpz_set_str(&n, str, 10)
  }

  public func copy() -> GmpInt {
    let result = GmpInt()
    __gmpz_set(&result.n, &n)
    return result
  }

  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    self.init(fromString: str)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.description)
  }

  deinit {
    __gmpz_clear(&n)
  }
}

extension GmpInt: Ring {
  public static var zero: GmpInt {
    return GmpInt()
  }

  public static var one: GmpInt {
    return GmpInt(1)
  }

  public static func +(_ left : GmpInt, _ right : GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_add(&result.n, &left.n, &right.n)
    return result
  }

  public static func -(_ left: GmpInt, _ right: GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_sub(&result.n, &left.n, &right.n)
    return result
  }

  public static prefix func -(_ i: GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_neg(&result.n, &i.n)
    return result
  }

  public static func *(_ left: GmpInt, _ right: GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_mul(&result.n, &left.n, &right.n)
    return result
  }

  public func equals(_ v: GmpInt) -> Bool {
    return (__gmpz_cmp(&self.n, &v.n) == 0)
  }
}

extension GmpInt: Comparable {
  public static func ==(lhs: GmpInt, rhs: GmpInt) -> Bool {
    return lhs.equals(rhs)
  }

  public static func <(_ left: GmpInt, _ right: GmpInt) -> Bool {
    return (__gmpz_cmp(&left.n, &right.n) < 0)
  }
}


extension GmpInt: CustomStringConvertible {
  public var description: String {
    let desc = __gmpz_get_str(UnsafeMutablePointer<Int8>(bitPattern: 0), 10, &n)
    return String(cString: desc!)
  }

}

extension GmpInt {
  public static func GCD(_ a: GmpInt, _ b: GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_gcd(&result.n, &a.n, &b.n)
    return result
  }

  public static func LCM(_ a: GmpInt, _ b: GmpInt) -> GmpInt {
    let result = GmpInt()
    __gmpz_lcm(&result.n, &a.n, &b.n)
    return result
  }
}

public final class GmpRational: Codable {
  private var q: __mpq_struct

  private static let _zero = GmpRational()
  private static let _one = GmpRational(1)

  private init() {
    q = __mpq_struct()
    __gmpq_init(&q)
  }

  public init(_ value: Int, over: UInt) {
    q = __mpq_struct()
    __gmpq_init(&q)
    __gmpq_set_si(&q, value, over)
    __gmpq_canonicalize(&q)
  }

  public init(_ value: UInt, over: UInt) {
    q = __mpq_struct()
    __gmpq_init(&q)
    __gmpq_set_ui(&q, value, over)
    __gmpq_canonicalize(&q)
  }

  public init(fromString str: String) {
    q = __mpq_struct()
    __gmpq_init(&q)
    __gmpq_set_str(&q, str, 10)
  }

  public convenience init(_ value: Int) {
    self.init(value, over: 1)
  }

  public convenience init(_ value: UInt) {
    self.init(value, over: 1)
  }

  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    self.init(fromString: str)
  }

  public func encode(to encoder: Encoder) throws {
    let s = String(self.description)
    var container = encoder.singleValueContainer()
    try container.encode(s)
  }

  deinit {
    __gmpq_clear(&q)
  }
}

extension GmpRational: Ring {
  public static var zero: GmpRational {
    return _zero
  }

  public static var one: GmpRational {
    return _one
  }

  public func copy() -> GmpRational {
    let result = GmpRational()
    __gmpq_set(&result.q, &q)
    return result
  }

  public static func +(
      _ left: GmpRational, _ right: GmpRational) -> GmpRational {
    let result = GmpRational()
    __gmpq_add(&result.q, &left.q, &right.q)
    return result
  }

  /*public static func +=(
    _ left: inout GmpRational, _ right: GmpRational) {
    __gmpq_add(&left.q, &left.q, &right.q)
  }*/

  public static func -(
      _ left: GmpRational, _ right: GmpRational) -> GmpRational {
    let result = GmpRational()
    __gmpq_sub(&result.q, &left.q, &right.q)
    return result
  }

  /*public static func -=(
    _ left: inout GmpRational, _ right: GmpRational) {
    __gmpq_sub(&left.q, &left.q, &right.q)
  }*/

  public static prefix func -(_ i: GmpRational) -> GmpRational {
    let result = GmpRational()
    __gmpq_neg(&result.q, &i.q)
    return result
  }

  public static func *(
      _ left: GmpRational, _ right: GmpRational) -> GmpRational {
    let result = GmpRational()
    __gmpq_mul(&result.q, &left.q, &right.q)
    return result
  }

  public func equals(_ v: GmpRational) -> Bool {
    return (__gmpq_cmp(&self.q, &v.q) == 0)
  }
}

extension GmpRational: Field {
  public static func /(
      _ left: GmpRational, _ right: GmpRational) -> GmpRational {
    let result = GmpRational()
    __gmpq_div(&result.q, &left.q, &right.q)
    return result
  }

  public func inverse() -> GmpRational {
    let result = GmpRational()
    __gmpq_inv(&result.q, &q)
    return result
  }
}

extension GmpRational: Numeric {
  public func asDouble() -> Double {
    return __gmpq_get_d(&self.q)
  }
}

extension GmpRational: Comparable {
  public static func ==(_ left: GmpRational, _ right: GmpRational) -> Bool {
    return left.equals(right)
  }

  public static func <(_ left: GmpRational, _ right: GmpRational) -> Bool {
    return (__gmpq_cmp(&left.q, &right.q) < 0)
  }
}

extension GmpRational: CustomStringConvertible {
  public var description: String {
    let desc = __gmpq_get_str(UnsafeMutablePointer<Int8>(bitPattern: 0), 10, &q)
    return String(cString: desc!)
  }

}
