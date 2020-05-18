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

// ScanParams expects an array of string arguments of the form
// "key:value" and returns a dictionary with the corresponding
// keys and values.
func ScanParams(_ args: [String]) -> [String: String] {
	var results: [String: String] = [:]
	for arg in args {
		if let separatorIndex = arg.firstIndex(of: ":") {
			let key = String(arg[..<separatorIndex])
			let valueStart = arg.index(after: separatorIndex)
			let value = String(arg[valueStart...])
			if key != "" {
			results[key] = value
			}
		}
	}
	return results
}

func defaultPointSetName() -> String {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyyMMdd-HHmmss"
	let dateString = formatter.string(from: Date())
	return "points-\(dateString)"
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

		let name = params["name"] ?? defaultPointSetName()
		let countString = params["count"] ?? "100"
		let densityString = params["gridDensity"] ?? "32"

		let count = Int(countString)!
		let density = UInt(densityString)!
		let pointSet = RandomApexesWithGridDensity(density, count: count)
		logger.info("Generated point set with density: \(density), count: \(count)")
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

		guard let name = params["name"]
		else {
			fputs("pointset print: expected name\n", stderr)
			return
		}
		let pointSet = try! dataManager.loadPointSet(name: name)
		for p in pointSet.elements {
			print("\(p.x),\(p.y)")
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

	func summarize(name: String, pointSet: PointSet, cycles: [Int: TurnCycle]) {
		var aggregate = AggregateStats()
		var statsTable: [TurnCycle: CycleStats] = [:]
		for (pointID, cycle) in cycles {
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
			Double(aggregate.totalLength) / Double(cycles.count))
		let averageWeight = String(format: "%.2f",
			Double(aggregate.totalWeight) / Double(cycles.count))
		let averageSegments = String(format: "%.2f",
			Double(aggregate.totalSegments) / Double(cycles.count))
		print("pointset: \(name)")
		print("  known cycles: \(cycles.keys.count) / \(pointSet.elements.count)")
		print("  distinct cycles: \(statsTable.count)")
		print("  length: average \(averageLength), maximum \(aggregate.maxLength)")
		print("  weight: average \(averageWeight), maximum \(aggregate.maxWeight)")
		print("  segments: average \(averageSegments), maximum \(aggregate.maxSegments)")

	}

	func cmd_info(_ args: [String]) {
		let params = ScanParams(args)
		guard let name = params["name"]
		else {
			fputs("pointset info: expected name\n", stderr)
			return
		}

		let pointSet = try! dataManager.loadPointSet(name: name)
		var approxCycles: [Int: TurnCycle] =
			(try? dataManager.loadPath(["pointset", name, "cyclesApprox"])) ?? [:]
		var verifyCycles: [Int: TurnCycle] =
			(try? dataManager.loadPath(["pointset", name, "cycles"])) ?? [:]

		summarize(name: name, pointSet: pointSet, cycles: approxCycles)
	}

	func cmd_search(_ args: [String]) {
		print("search")

		signal(SIGINT, SIG_IGN)
		let signalQueue = DispatchQueue(label: "me.faec.billiards.signalQueue")
		var sigintCount = 0
		//sigintSrc.suspend()
		let sigintSrc = DispatchSource.makeSignalSource(
			signal: SIGINT,
			queue: signalQueue)
		sigintSrc.setEventHandler {
			print("Hi i got a sigint")
			sigintCount += 1
			if sigintCount > 1 {
				exit(0)
			}
		}
		sigintSrc.resume()
		func shouldCancel() -> Bool {
			return sigintCount > 0
		}

		var searchOptions = TrajectorySearchOptions()
		searchOptions.shouldCancel = shouldCancel
		/*searchOptions.attemptCount = 5000
		searchOptions.maxPathLength = 100
		searchOptions.skipExactCheck = true
		searchOptions.stopAfterSuccess = false
		searchOptions.skipKnownPoints = false*/

		let params = ScanParams(args)
		guard let name = params["name"]
		else {
			fputs("pointset search: expected name\n", stderr)
			return
		}
		if let attemptCountStr = params["attemptCount"] {
			if let attemptCount = Int(attemptCountStr) {
				searchOptions.attemptCount = attemptCount
			} else {
				fputs("pointset search: invalid attemptCount\n", stderr)
				return
			}
		}
		if let maxPathLengthStr = params["maxPathLength"] {
			if let maxPathLength = Int(maxPathLengthStr) {
				searchOptions.maxPathLength = maxPathLength
			} else {
				fputs("pointset search: invalid maxPathLength\n", stderr)
				return
			}
		}
		if let stopAfterSuccessStr = params["stopAfterSuccess"] {
			if let stopAfterSuccess = Bool(stopAfterSuccessStr) {
				searchOptions.stopAfterSuccess = stopAfterSuccess
			} else {
				fputs("pointset search: invalid stopAfterSuccess\n", stderr)
				return
			}
		}
		if let skipKnownPointsStr = params["skipKnownPoints"] {
			if let skipKnownPoints = Bool(skipKnownPointsStr) {
				searchOptions.skipKnownPoints = skipKnownPoints
			} else {
				fputs("pointset search: invalid skipKnownPoints\n", stderr)
				return
			}
		}
		if let skipExactCheckStr = params["skipExactCheck"] {
			if let skipExactCheck = Bool(skipExactCheckStr) {
				searchOptions.skipExactCheck = skipExactCheck
			} else {
				fputs("pointset search: invalid skipExactCheck\n", stderr)
				return
			}
		}
		let pointSet = try! dataManager.loadPointSet(name: name)
		let cyclesSuffix = searchOptions.skipExactCheck ? "cyclesApprox" : "cycles"
		let cyclesPath = ["pointset", name, cyclesSuffix]
		var shortestCycles: [Int: TurnCycle] =
			(try? dataManager.loadPath(cyclesPath)) ?? [:]
		
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
			if shouldCancel() { break }
			let pointApprox = point.asDoubleVec()
			let approxAngles = Singularities(
				s0: Double.pi / (2.0 * atan2(pointApprox.y, pointApprox.x)),
				s1: Double.pi / (2.0 * atan2(pointApprox.y, 1.0 - pointApprox.x))
			).map { String(format: "%.2f", $0)}
			let coordsStr = String(
				format: "(%.4f, %.4f)", pointApprox.x, pointApprox.y)
			let angleStrs = Singularities(
				s0: DarkGray("\(approxAngles[.S0])"),
				s1: "\(approxAngles[.S1])"
			)
			let angleStr = String(
				format: "(S0: \(approxAngles[.S0]), S1: \(approxAngles[.S1]))")

			searchGroup.enter()
			searchQueue.async {
				defer { searchGroup.leave() }
				var knownCycle: TurnCycle? = nil
				var options = searchOptions
				var skip = false

				resultsQueue.sync(flags: .barrier) {
					// starting search
					knownCycle = shortestCycles[index]
					if let lengthBound = knownCycle?.length {
						if options.skipKnownPoints {
							// We already have a cycle for this point
							//print(ClearCurrentLine(), terminator: "\r")
							//print("skipping:", Cyan("\(index)"), terminator: "")
							skip = true
							return
						}
						options.maxPathLength = min(
							options.maxPathLength, lengthBound - 1)
					}
					activeSearches[index] = true
				}
				if skip || shouldCancel() { return }

				let result = TrajectorySearchForApexCoords(
					point, options: options)
				resultsQueue.sync(flags: .barrier) {
					// search is finished
					activeSearches.removeValue(forKey: index)
					searchResults[index] = result
					
					// reset the current line
					print(ClearCurrentLine(), terminator: "\r")

					print(Cyan("[\(index)]"))
					print(Green("  cartesian coords"), coordsStr)
					print(Green("  angle bounds"))
					print(DarkGray("    S0: \(approxAngles[.S0])"))
					print("    S1: \(approxAngles[.S1])")
					if let oldCycle = knownCycle {
						if let newCycle = result.shortestCycle {
							print(DarkGray("  old cycle"), oldCycle)
							print(Magenta("  replaced with"), newCycle)
							shortestCycles[index] = newCycle
							updatedCount += 1
						} else {
							print(DarkGray("  existing cycle"), oldCycle)
						}
					} else if let cycle = result.shortestCycle {
						print(Green("  found cycle"), cycle)
						shortestCycles[index] = cycle
						foundCount += 1
					} else {
						print(Red("  no feasible path found"))
					}
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
		try! dataManager.save(shortestCycles, toPath: cyclesPath)
	}

	func cmd_plot(_ args: [String]) {
		let params = ScanParams(args)
		guard let name = params["name"]
		else {
			print("pointset plot: expected name\n")
			return
		}
		let pointSet = try! dataManager.loadPointSet(name: name)

		let outputURL = URL(fileURLWithPath: "plot.png")
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

		ContextRenderToURL(outputURL, width: width, height: height)
		{ (context: CGContext) in
			var i = 0
			for point in pointSet.elements {
				//print("point \(i)")
				i += 1
				let modelCoords = point//point.asDoubleVec()

				/*if !result.feasible {
				continue
				}*/
				let color = CGColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 0.6)
				/*guard let color: CGColor = colorForResult(result)
				else {
				//if !filter.includePoint(modelCoords) {//!filterPoint(modelCoords) {
				continue
				}*/
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
			print("pointset: expected command")
			exit(1)
		}
		switch command {
		case "list":
			cmd_list()
		case "print":
			cmd_print(Array(args[1...]))
		case "delete":
			cmd_delete(Array(args[1...]))
		case "create":
			cmd_create(Array(args[1...]))
		case "plot":
			cmd_plot(Array(args[1...]))
		case "search":
			cmd_search(Array(args[1...]))
		case "info":
			cmd_info(Array(args[1...]))
		default:
			print("Unrecognized command '\(command)'")
		}
	}
}
