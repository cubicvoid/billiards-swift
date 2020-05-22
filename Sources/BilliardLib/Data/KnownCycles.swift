extension DataManager {
	public func knownCyclesForPointSet(name: String) -> [Int: TurnCycle] {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		let loaded: [Int: TurnCycle]? = try? loadPath(path)
		let cycles: [Int: TurnCycle] = loaded ?? [:]
		return cycles
	}

	public func saveKnownCycles(
		_ knownCycles: [Int: TurnCycle],
		pointSetName name: String
	) throws {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		try save(knownCycles, toPath: path)
	}
}