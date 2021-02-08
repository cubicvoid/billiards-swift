extension DataManager {
	public func knownCyclesForPointSet(name: String) -> [Int: TurnPath] {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		let loaded: [Int: TurnPath]? = try? loadPath(path)
		let cycles: [Int: TurnPath] = loaded ?? [:]
		return cycles
	}

	public func saveKnownCycles(
		_ knownCycles: [Int: TurnPath],
		pointSetName name: String
	) throws {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		try save(knownCycles, toPath: path)
	}
}
