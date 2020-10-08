import Foundation

// a continued fraction with digits a, so:
// value = a[0] + 1 / (a[1] + 1 / (...))
public class ContinuedFrac {
	let a: [GmpInt]
	
	public init(_ value: GmpRational) {
		var cur = value
		var a: [GmpInt] = []
		while !cur.isZero() {
			let floor = cur.floor()
			a.append(floor)
			cur = cur - GmpRational(floor)
			if !cur.isZero() {
				cur = cur.inverse()
			}
		}
		self.a = a
	}
	
	// Warning: the accuracy of this transformation degrades faster
	// than you'd think, even if you already think it degrades really
	// fast.
	public init(_ value: Double, length: Int) {
		var remainder = value
		var a: [Int] = []
		for _ in 1...length {
			if remainder == 0.0 {
				break
			}
			let f = floor(remainder)
			a.append(Int(f))
			remainder = 1.0 / (remainder - f)
		}
		self.a = a.map { GmpInt($0) }
	}
	
	public func approximation(degree: Int) -> GmpRational {
		guard degree <= a.count
		else {
			return approximation(degree: a.count)
		}
		if degree == 1 {
			return GmpRational(a[0])
		}
		var cur = GmpRational.zero
		let prefix = Array(a[..<degree])
		for step in prefix.reversed() {
			cur = cur + GmpRational(step)
			if !cur.isZero() {
				cur = cur.inverse()
			}
		}
		if !cur.isZero() {
			cur = cur.inverse()
		}
		return cur
	}
	
	public func approximations() -> [GmpRational] {
		return (1...a.count).map(approximation)
		/*{
			approximation(degree: $0)
		}*/
	}
}

