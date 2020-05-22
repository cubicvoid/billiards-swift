import Foundation

class ScanParams {
	var rawParams: [String: String]
	init(_ args: [String]) {
		var rawParams: [String: String] = [:]
		for arg in args {
			if let separatorIndex = arg.firstIndex(of: ":") {
				let key = String(arg[..<separatorIndex])
				let valueStart = arg.index(after: separatorIndex)
				let value = String(arg[valueStart...])
				if key != "" {
					rawParams[key] = value
				}
			}
		}
		self.rawParams = rawParams
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
