import Foundation

class ScanParams {
	let rawParams: [String: String]
	let words: [String]	// arguments with no parameter name attached
	init(_ args: [String]) {
		var rawParams: [String: String] = [:]
		var words: [String] = []
		for arg in args {
			if let separatorIndex = arg.firstIndex(of: ":") {
				let key = String(arg[..<separatorIndex])
				let valueStart = arg.index(after: separatorIndex)
				let value = String(arg[valueStart...])
				if key != "" {
					rawParams[key] = value
				}
			} else {
				words.append(arg)
			}
		}
		self.rawParams = rawParams
		self.words = words
	}

	subscript<T: LosslessStringConvertible>(key: String) -> T? {
		if let str = rawParams[key] {
			if let t = T(str) {
				return t
			}
			fputs("invalid parameter: \(key) = \(str)\n", stderr)
			exit(1)
		}
		return nil
	}
}
