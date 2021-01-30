extension DataManager {
	public func knownCyclesForPointSet(name: String) -> [Int: Path] {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		let loaded: [Int: Path]? = try? loadPath(path)
		let cycles: [Int: Path] = loaded ?? [:]
		return cycles
	}

	public func saveKnownCycles(
		_ knownCycles: [Int: Path],
		pointSetName name: String
	) throws {
		let path: DataManager.Path = ["pointset", name, "cycles"]
		try save(knownCycles, toPath: path)
	}
}
