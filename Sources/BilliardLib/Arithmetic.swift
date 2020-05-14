import Foundation

public protocol Signed {
	func sign() -> Sign?
}

public protocol Negatable {
	static prefix func -(v: Self) -> Self
}

extension Int: Signed, Negatable {
	public func sign() -> Sign? {
		if self > 0 {
			return .positive
		}
		if self < 0 {
			return .negative
		}
		return nil
	}
}

/*extension
	Nonzero: Signed
	where R: Signed
{
	public static func sign() -> Sign? {
		if self.value < 0 {
			return .negative
		}
		return .positive
	}
}
*/

public enum Sign {
	case positive
	case negative

	public init?(of v: Signed) {
		if let sign = v.sign() {
			self = sign
		} else {
			return nil
		}
	}

	public func isPositive() -> Bool {
		return self == .positive
	}

	public func isNegative() -> Bool {
		return self == .negative
	}

	public static func *(_ a: Sign, _ b: Sign) -> Sign {
		return (a == b) ? .positive : .negative
	}

	public static func *<T: Negatable>(_ v: T, _ s: Sign) -> T {
		return (s == .positive) ? v : -v
	}

	public static func *<T: Negatable>(_ s: Sign, _ v: T) -> T {
		return (s == .positive) ? v : -v
	}

	public static prefix func -(_ s: Sign) -> Sign {
		switch s {
			case .positive: return .negative
			case .negative: return .positive
		}
	}
	
	public static func of(_ i: Int) -> Sign? {
		if i > 0 {
			return .positive
		}
		if i < 0 {
			return .negative
		}
		return nil
	}

	public static func of(_ i: Nonzero<Int>) -> Sign {
		if i.value < 0 {
			return .negative
		}
		return .positive
	}
	
	public func ifPositive<T>(_ positive: T, negative: T) -> T {
		switch self {
			case .positive:
				return positive
			case .negative:
				return negative
		}
	}
}

public protocol Ring: CustomStringConvertible & Codable & Negatable & Equatable {
	init(_: Int)
	//static func zero() -> Self
	//static func one() -> Self
	static var zero: Self { get }
	static var one: Self { get }
	func copy() -> Self
	static prefix func -(_ : Self) -> Self
	static func +(_ : Self, _ : Self) -> Self
	static func +=(_ : inout Self, _ : Self)
	static func -(_ : Self, _ : Self) -> Self
	static func -=(_ : inout Self, _ : Self)
	static func *(_ : Self, _ : Self) -> Self
	static func *=(_ : inout Self, _ : Self)
	static func ==(_ : Self, _ : Self) -> Bool
	//func equals(_ : Self) -> Bool
}

extension Ring {
	public static func +=(_ left: inout Self, _ right: Self) {
		left = left + right
	}
	public static func -=(_ left: inout Self, _ right: Self) {
		left = left - right
	}
	public static func *=(_ left: inout Self, _ right: Self) {
		left = left * right
	}
	public func isZero() -> Bool {
		return self == Self.zero
	}
}

public protocol Field : Ring {
	static func /(_ : Self, _ : Self) -> Self
	func inverse() -> Self
	init(_: Int, over: UInt)
	init(_: UInt, over: UInt)
}

public protocol Algebra: Ring {
	associatedtype BaseRing: Ring

	func times(_ : BaseRing) -> Self
}

public protocol Numeric {
	func asDouble() -> Double
}

public extension Numeric {
	func asCGFloat() -> CGFloat {
		return CGFloat(self.asDouble())
	}
}

extension Int: Ring {
	public static var zero: Int {
		return 0
	}
	public static var one: Int {
		return 1
	}
	public func copy() -> Int {
		return Int(self)
	}
	public func equals(_ value: Int) -> Bool {
		return self == value
	}
}

extension Double: Ring {
	public static var zero: Double {
		return 0.0
	}
	public static var one: Double {
		return 1.0
	}
	public func copy() -> Double {
		return Double(self)
	}
	public func equals(_ value: Double) -> Bool {
		return self == value
	}
}

extension Double: Field {
	public func inverse() -> Double {
		return 1.0 / self
	}
	public init(_ value: Int, over: UInt) {
		self.init(Double(value)/Double(over))
	}
	public init(_ value: UInt, over: UInt) {
		self.init(Double(value)/Double(over))
	}
}

extension Double: Numeric {
	public func asDouble() -> Double {
		return self
	}
}

public class Nonzero<R: Ring> {
	public typealias valueType = R
	public let value: R

	public init?(_ value: R) {
		if value == R.zero {
			return nil
		}
		self.value = value
	}
}

extension Nonzero: Equatable where valueType: Equatable {
	public static func == (lhs: Nonzero, rhs: Nonzero) -> Bool {
		return lhs.value == rhs.value
	}
}

extension Nonzero: Hashable where valueType: Hashable {
	public func hash(into hasher: inout Hasher) {
		value.hash(into: &hasher)
	}
}
