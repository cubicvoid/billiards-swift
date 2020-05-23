import Foundation
import Logging
import Dispatch
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import BilliardLib

class Commands {
	let logger: Logger

	init(logger: Logger) {
		self.logger = logger
	}

	func run(_ args: [String]) {
		guard let command = args.first
		else {
			print("Usage: billiards [command]")
			exit(1)
		}
		switch command {
		case "pointset":
			let pointSetCommands = PointSetCommands(logger: logger)
			pointSetCommands.run(Array(args[1...]))
		case "repl":
			let repl = BilliardsRepl()
			repl.run()
		default:
			print("Unrecognized command '\(command)'")
		}
	}
}

class BilliardsRepl {
	public init() {
	}

	public func run() {

	}
}

extension Vec2: LosslessStringConvertible
	where R: LosslessStringConvertible
{
	public init?(_ description: String) {
		let components = description.split(separator: ",")
		if components.count != 2 {
			return nil
		}
		guard let x = R.self(String(components[0]))
		else { return nil }
		guard let y = R.self(String(components[1]))
		else { return nil }
		self.init(x, y)
	}

}

/*func colorForResult(_ result: PathFeasibility.Result) -> CGColor? {
	if result.feasible {
		return CGColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 0.4)
	} else if result.apexFeasible && result.baseFeasible {
		return CGColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 0.4)
	} else if result.apexFeasible {
		return CGColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 0.4)
	} else if result.baseFeasible {
		return CGColor(red: 0.1, green: 0.1, blue: 0.7, alpha: 0.4)
	}
	return nil
}*/

class PointSetCommands {
	let logger: Logger
	let dataManager: DataManager

	public init(logger: Logger) {
		self.logger = logger
		let path = FileManager.default.currentDirectoryPath
		let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
		dataManager = try! DataManager(
			rootURL: dataURL,
			logger: logger)
	}

	func cmd_create(_ args: [String]) {
		let params = ScanParams(args)

		guard let name: String = params["name"]
		else {
			fputs("pointset create: expected name\n", stderr)
			return
		}
		guard let count: Int = params["count"]
		else {
			fputs("pointset create: expected count\n", stderr)
			return
		}
		let gridDensity: UInt = params["gridDensity"] ?? 32

		let pointSet = RandomApexesWithGridDensity(
			gridDensity, count: count)
		logger.info("Generated point set with density: 2^\(gridDensity), count: \(count)")
		try! dataManager.savePointSet(pointSet, name: name)
	}

	func cmd_list() {
		let sets = try! dataManager.listPointSets()
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.locale = .current
		dateFormatter.timeZone = .current
		let sortedNames = sets.keys.sorted(by: { (a: String, b: String) -> Bool in
			return a.lowercased() < b.lowercased()
		})
		for name in sortedNames {
			guard let metadata = sets[name]
			else { continue }
			var line = name
			if let count = metadata.count {
				line += " (\(count))"
			}
			if let created = metadata.created {
				let localized = dateFormatter.string(from: created)
				line += " \(localized)"
			}
			print(line)
		}
	}

	func cmd_print(_ args: [String]) {
		let params = ScanParams(args)

		guard let name: String = params["name"]
		else {
			fputs("pointset print: expected name\n", stderr)
			return
		}
		let pointSet = try! dataManager.loadPointSet(name: name)
		for p in pointSet.elements {
			print("\(p.x),\(p.y)")
		}
	}

	func cmd_info(_ args: [String]) {
		let params = ScanParams(args)
		guard let name: String = params["name"]
		else {
			fputs("pointset info: expected name\n", stderr)
			return
		}
		let indexParam: Int? = params["index"]

		let pointSet = try! dataManager.loadPointSet(name: name)
		let knownCycles: [Int: TurnCycle] =
			(try? dataManager.loadPath(["pointset", name, "cycles"])) ?? [:]

		if let index = indexParam {
			pointSet.printPointIndex(
				index,
				knownCycles: knownCycles,
				precision: 8)
		} else {
			pointSet.summarize(name: name,
				knownCycles: knownCycles)
		}
	}

	func cmd_copyCycles(
		_ args: [String],
		shouldCancel: () -> Bool
	) {
		let params = ScanParams(args)
		guard let fromName: String = params["from"]
		else {
			fputs("pointset copyCycles: expected from\n", stderr)
			return
		}
		guard let toName: String = params["to"]
		else {
			fputs("pointset copyCycles: expected to\n", stderr)
			return
		}
		let neighborCount: Int = params["neighbors"] ?? 1

		let fromSet = try! dataManager.loadPointSet(name: fromName)
		let toSet = try! dataManager.loadPointSet(name: toName)
		let fromCycles = dataManager.knownCyclesForPointSet(
			name: fromName)
		var toCycles = dataManager.knownCyclesForPointSet(
			name: toName)

		let fromSortCoords = fromSet.elements.map {
			 polarFromCartesian($0.asDoubleVec()) }
		let toSortCoords = toSet.elements.map {
			polarFromCartesian($0.asDoubleVec()) }
		func distance(fromIndex: Int, toIndex: Int) -> Double {
			let coords = fromSortCoords[fromIndex]
			let center = toSortCoords[toIndex]
			let offset = coords - center
			return sqrt(offset.x * offset.x + offset.y * offset.y)
		}

		let copyQueue = DispatchQueue(
			label: "me.faec.billiards.copyQueue",
			attributes: .concurrent)
		let resultsQueue = DispatchQueue(
			label: "me.faec.billiards.resultsQueue")
		let copyGroup = DispatchGroup()

		var foundCount = 0
		var updatedCount = 0
		var unchangedCount = 0
		for targetIndex in toSet.elements.indices {
			if shouldCancel() { break}

			copyGroup.enter()
			copyQueue.async {
				defer { copyGroup.leave() }
				let apexCoords = toSet.elements[targetIndex]
				let apex = ApexData(coords: apexCoords)

				let candidates = Array(fromSet.elements.indices).sorted {
					distance(fromIndex: $0, toIndex: targetIndex) <
					distance(fromIndex: $1, toIndex: targetIndex)
				}.prefix(neighborCount).compactMap
				{ (index: Int) -> TurnCycle? in
					if let cycle = fromCycles[index] {
						if let knownCycle = toCycles[targetIndex] {
							if knownCycle.length <= cycle.length {
								return nil
							}
						}
						return cycle
					}
					return nil
				}.sorted { $0.length < $1.length }

				var foundCycle: TurnCycle? = nil
				var checked: Set<TurnCycle> = []
				for cycle in candidates {
					if checked.contains(cycle) { continue }
					checked.insert(cycle)

					let result = SimpleCycleFeasibilityForTurnPath(
						cycle.turnPath(), apex: apex)
					if result?.feasible == true {
						foundCycle = cycle
						break
					}
				}
				resultsQueue.sync(flags: .barrier) {
					var caption: String
					if let newCycle = foundCycle {
						if let oldCycle = toCycles[targetIndex] {
							updatedCount += 1
							caption = Magenta("updated ") +
								"length \(oldCycle.length) -> \(newCycle.length)"
						} else {
							foundCount += 1
							caption = "cycle found"
						}
						toCycles[targetIndex] = newCycle
						toSet.printPointIndex(
							targetIndex,
							knownCycles: toCycles,
							precision: 8,
							caption: caption)
					} else {
						unchangedCount += 1
					}
				}
			}
		}
		copyGroup.wait()
		if updatedCount > 0 {
			print("\(foundCount) found, \(updatedCount) updated, \(unchangedCount) unchanged")
			print("saving...")
			try! dataManager.saveKnownCycles(
				toCycles, pointSetName: toName)
		}
	}

	func cmd_search(
		_ args: [String],
		shouldCancel: (() -> Bool)?
	) {
		var searchOptions = TrajectorySearchOptions()

		let params = ScanParams(args)
		guard let name: String = params["name"]
		else {
			fputs("pointset search: expected name\n", stderr)
			return
		}
		if let attemptCount: Int = params["attemptCount"] {
			searchOptions.attemptCount = attemptCount
		}
		if let maxPathLength: Int = params["maxPathLength"] {
			searchOptions.maxPathLength = maxPathLength
		}
		if let stopAfterSuccess: Bool = params["stopAfterSuccess"] {
			searchOptions.stopAfterSuccess = stopAfterSuccess
		}
		if let skipKnownPoints: Bool = params["skipKnownPoints"] {
			searchOptions.skipKnownPoints = skipKnownPoints
		}
		let pointSet = try! dataManager.loadPointSet(name: name)
		var knownCycles = dataManager.knownCyclesForPointSet(name: name)
		
		let searchQueue = DispatchQueue(
			label: "me.faec.billiards.searchQueue",
			attributes: .concurrent)
		let resultsQueue = DispatchQueue(label: "me.faec.billiards.resultsQueue")
		let searchGroup = DispatchGroup()

		var activeSearches: [Int: Bool] = [:]
		var searchResults: [Int: TrajectorySearchResult] = [:]
		var foundCount = 0
		var updatedCount = 0
		for (index, point) in pointSet.elements.enumerated() {
			if shouldCancel?() == true { break }

			searchGroup.enter()
			searchQueue.async {
				defer { searchGroup.leave() }
				var options = searchOptions
				var skip = false

				resultsQueue.sync(flags: .barrier) {
					// starting search
					if let cycle = knownCycles[index] {
						if options.skipKnownPoints {
							skip = true
							return
						}
						options.maxPathLength = min(
							options.maxPathLength, cycle.length - 1)
					}
					activeSearches[index] = true
				}
				if skip || shouldCancel?() == true { return }

				let searchResult = TrajectorySearchForApexCoords(
					point, options: options, cancel: shouldCancel)
				resultsQueue.sync(flags: .barrier) {
					// search is finished
					activeSearches.removeValue(forKey: index)
					searchResults[index] = searchResult
					var caption = ""
					if let newCycle = searchResult.shortestCycle {
						if let oldCycle = knownCycles[index] {
							if newCycle.length < oldCycle.length {
								knownCycles[index] = newCycle
								caption = Magenta("found shorter cycle ") +
									"[\(oldCycle.length) -> \(newCycle.length)]"
								updatedCount += 1
							} else {
								caption = DarkGray("no change")
							}
						} else {
							knownCycles[index] = newCycle
							caption = "cycle found"
							foundCount += 1
						}
					} else if knownCycles[index] != nil {
						caption = DarkGray("no change")
					} else {
						caption = Red("no cycle found")
					}
					
					// reset the current line
					print(ClearCurrentLine(), terminator: "\r")

					pointSet.printPointIndex(
						index,
						knownCycles: knownCycles,
						precision: 4,
						caption: caption)
					
					let failedCount = searchResults.count -
						(foundCount + updatedCount)
					print("found \(foundCount), updated \(updatedCount),",
						"failed \(failedCount).",
						"still active:",
						Cyan("\(activeSearches.keys.sorted())"),
						"...",
						terminator: "")
					fflush(stdout)
				}
			}
		}
		searchGroup.wait()
		print(ClearCurrentLine(), terminator: "\r")
		let failedCount = searchResults.count -
			(foundCount + updatedCount)
		print("found \(foundCount), updated \(updatedCount),",
			"failed \(failedCount).")
		try! dataManager.saveKnownCycles(
			knownCycles, pointSetName: name)
	}

	func cmd_phaseplot(_ args: [String]) {
		let params = ScanParams(args)
		guard let name: String = params["name"]
		else {
			print("pointset phaseplot: expected name\n")
			return
		}
		//guard let 
	}


	func cmd_plot(_ args: [String]) {
		let params = ScanParams(args)
		guard let name: String = params["name"]
		else {
			print("pointset plot: expected name\n")
			return
		}
		let pointSet = try! dataManager.loadPointSet(name: name)

		//let outputURL = URL(fileURLWithPath: "plot.png")
		let width = 2000
		let height = 1000
		let scale = Double(width) * 0.9
		let imageCenter = Vec2(Double(width) / 2, Double(height) / 2)
		let modelCenter = Vec2(0.5, 0.25)
		let pointRadius = CGFloat(4)

		func toImageCoords(_ v: Vec2<Double>) -> Vec2<Double> {
			return (v - modelCenter) * scale + imageCenter
		}

		//let filter = PathFilter(path: [-2, 2, 2, -2])
		//let feasibility = PathFeasibility(path: [-2, 2, 2, -2])
		//let path = [-2, 2, 2, -2]
		//let path = [4, -3, -5, 3, -4, -4, 5, 4]
		//let turns = [3, -1, 1, -1, -3, 1, -2, 1, -3, -1, 1, -1, 3, 2]
		//let feasibility = SimpleCycleFeasibility(turns: turns)

		/*ContextRenderToURL(outputURL, width: width, height: height)
		{ (context: CGContext) in
			var i = 0
			for point in pointSet.elements {
				//print("point \(i)")
				i += 1
				let modelCoords = point//point.asDoubleVec()

				let color = CGColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 0.6)
				let imageCoords = toImageCoords(modelCoords.asDoubleVec())
				
				context.beginPath()
				//print("point: \(imageCoords.x), \(imageCoords.y)")
				context.addArc(
					center: CGPoint(x: imageCoords.x, y: imageCoords.y),
					radius: pointRadius,
					startAngle: 0.0,
					endAngle: CGFloat.pi * 2.0,
					clockwise: false
				)
				context.closePath()
				context.setFillColor(color)
				context.drawPath(using: .fill)
			}

			// draw the containing half-circle
			context.beginPath()
			let circleCenter = toImageCoords(Vec2(0.5, 0.0))
			context.addArc(center: CGPoint(x: circleCenter.x, y: circleCenter.y),
				radius: CGFloat(0.5 * scale),
				startAngle: 0.0,
				endAngle: CGFloat.pi,
				clockwise: false
			)
			context.closePath()
			context.setStrokeColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)
			context.setLineWidth(2.0)
			context.drawPath(using: .stroke)
		}*/
	}

	enum CoordinateSystem: String, LosslessStringConvertible {
		case euclidean
		case polar

		public init?(_ str: String) {
			self.init(rawValue: str)
		}

		public var description: String {
			return self.rawValue
		}
	}


	func cmd_probe(_ args: [String]) {
		let params = ScanParams(args)
		guard let name: String = params["name"]
		else {
			fputs("pointset probe: expected name\n", stderr)
			return
		}
		guard let targetCoords: Vec2<Double> = params["coords"]
		else {
			fputs("pointset probe: expected coords\n", stderr)
			return
		}
		let metric: CoordinateSystem =
			params["metric"] ?? .euclidean
		let count: Int = params["count"] ?? 1
		let pointSet = try! dataManager.loadPointSet(name: name)
		let knownCycles = dataManager.knownCyclesForPointSet(name: name)
		let distance: [Double] = pointSet.elements.indices.map { index in
			let point = pointSet.elements[index].asDoubleVec()
			var coords: Vec2<Double>
			switch metric {
				case .euclidean:
					coords = point
				case .polar:
					let angle0 = atan2(point.y, point.x)
					let angle1 = atan2(point.y, 1.0 - point.x)
					coords = Vec2(
						Double.pi / (2.0 * angle0),
						Double.pi / (2.0 * angle1)
					)

			}
			let offset = coords - targetCoords
			return sqrt(offset.x * offset.x + offset.y * offset.y)
		}
		let sortedIndices = pointSet.elements.indices.sorted {
			distance[$0] < distance[$1]
		}

		for index in sortedIndices.prefix(count) {
			let distanceStr = String(format: "%.6f", distance[index])
			pointSet.printPointIndex(index,
				knownCycles: knownCycles,
				precision: 6,
				caption: "(distance \(distanceStr))")
		}
	}

	func cmd_delete(_ args: [String]) {
		guard let name = args.first
		else {
			print("pointset delete: expected point set name")
			exit(1)
		}
		do {
			try dataManager.deletePath(["pointset", name])
			logger.info("Deleted point set '\(name)'")
		} catch {
			logger.error("Couldn't delete point set '\(name)': \(error)")
		}
	}

	func run(_ args: [String]) {
		guard let command = args.first
		else {
			fputs("pointset: expected command", stderr)
			exit(1)
		}
		signal(SIGINT, SIG_IGN)
		let signalQueue = DispatchQueue(label: "me.faec.billiards.signalQueue")
		var sigintCount = 0
		//sigintSrc.suspend()
		let sigintSrc = DispatchSource.makeSignalSource(
			signal: SIGINT,
			queue: signalQueue)
		sigintSrc.setEventHandler {
			print(White("Shutting down..."))
			sigintCount += 1
			if sigintCount > 1 {
				exit(0)
			}
		}
		sigintSrc.resume()
		func shouldCancel() -> Bool {
			return sigintCount > 0
		}

		switch command {
		case "copyCycles":
			cmd_copyCycles(Array(args[1...]),
				shouldCancel: shouldCancel)
		case "create":
			cmd_create(Array(args[1...]))
		case "delete":
			cmd_delete(Array(args[1...]))
		case "info":
			cmd_info(Array(args[1...]))
		case "list":
			cmd_list()
		case "plot":
			cmd_plot(Array(args[1...]))
		case "print":
			cmd_print(Array(args[1...]))
		case "probe":
			cmd_probe(Array(args[1...]))
		case "search":
			cmd_search(Array(args[1...]),
				shouldCancel: shouldCancel)
		default:
			print("Unrecognized command '\(command)'")
		}
	}
}



class CycleStats {
	let cycle: TurnCycle
	var pointCount = 0
	init(_ cycle: TurnCycle) {
		self.cycle = cycle
	}
}

struct AggregateStats {
	var totalLength: Int = 0
	var totalWeight: Int = 0
	var totalSegments: Int = 0

	var maxLength: Int = 0
	var maxWeight: Int = 0
	var maxSegments: Int = 0
}

extension Vec2 where R: Numeric {
	func asBiphase() -> Singularities<Double> {
		let xApprox = x.asDouble()
		let yApprox = y.asDouble()
		return Singularities(
			s0: Double.pi / (2.0 * atan2(yApprox, xApprox)),
			s1: Double.pi / (2.0 * atan2(yApprox, 1.0 - xApprox)))
	}
}

func polarFromCartesian(_ coords: Vec2<Double>) -> Vec2<Double> {
	return Vec2(
		Double.pi / (2.0 * atan2(coords.y, coords.x)),
		Double.pi / (2.0 * atan2(coords.y, 1.0 - coords.x)))
}

/*func cartesianFromPolar(_ coords: Vec2<Double>) -> Vec2<Double> {
}*/

extension PointSet {
	func printPointIndex(
		_ index: Int,
		knownCycles: [Int: TurnCycle],
		precision: Int = 6,
		caption: String = ""
	) {
		let point = self.elements[index]
		let pointApprox = point.asDoubleVec()
		let approxAngles = pointApprox.asBiphase().map {
			String(format: "%.\(precision)f", $0) }
		let coordsStr = String(
			format: "(%.\(precision)f, %.\(precision)f)", pointApprox.x, pointApprox.y)
		print(Cyan("[\(index)]"), caption)
		print(Green("  cartesian coords"), coordsStr)
		print(Green("  biphase coords"))
		print(DarkGray("    S0: \(approxAngles[.S0])"))
		print("    S1: \(approxAngles[.S1])")
		if let cycle = knownCycles[index] {
			print(Green("  cycle"), cycle)
		}
	}

	func summarize(name: String, knownCycles: [Int: TurnCycle]) {
		var aggregate = AggregateStats()
		var statsTable: [TurnCycle: CycleStats] = [:]
		for (_, cycle) in knownCycles {
			aggregate.totalLength += cycle.length
			aggregate.maxLength = max(aggregate.maxLength, cycle.length)

			aggregate.totalWeight += cycle.weight
			aggregate.maxWeight = max(aggregate.maxWeight, cycle.weight)

			aggregate.totalSegments += cycle.segments.count
			aggregate.maxSegments = max(aggregate.maxSegments, cycle.segments.count)
			
			var curStats: CycleStats
			if let entry = statsTable[cycle] {
				curStats = entry
			} else {
				curStats = CycleStats(cycle)
				statsTable[cycle] = curStats
			}
			curStats.pointCount += 1
		}
		let averageLength = String(format: "%.2f",
			Double(aggregate.totalLength) / Double(knownCycles.count))
		let averageWeight = String(format: "%.2f",
			Double(aggregate.totalWeight) / Double(knownCycles.count))
		let averageSegments = String(format: "%.2f",
			Double(aggregate.totalSegments) / Double(knownCycles.count))
		print("pointset: \(name)")
		print("  known cycles: \(knownCycles.keys.count) / \(self.elements.count)")
		print("  distinct cycles: \(statsTable.count)")
		print("  length: average \(averageLength), maximum \(aggregate.maxLength)")
		print("  weight: average \(averageWeight), maximum \(aggregate.maxWeight)")
		print("  segments: average \(averageSegments), maximum \(aggregate.maxSegments)")
	}
}
