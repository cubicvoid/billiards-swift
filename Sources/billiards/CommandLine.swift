import Foundation
import Logging

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
		default:
			print("Unrecognized command '\(command)'")
		}
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
	let pointSetManager: PointSetManager

	public init(logger: Logger) {
		self.logger = logger
		let path = FileManager.default.currentDirectoryPath
		let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
		pointSetManager = try! PointSetManager(
			rootURL: dataURL.appendingPathComponent("pointset"),
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
		try! pointSetManager.save(pointSet, name: name)
	}

	func cmd_list() {
		let sets = try! pointSetManager.list()
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
			print("pointset print: expected name\n")
			return
		}
		let pointSet = try! pointSetManager.load(name: name)
		for p in pointSet.elements {
			print("\(p.x),\(p.y)")
		}
	}

	func cmd_search(_ args: [String]) {
		print("search")
		let params = ScanParams(args)
		guard let name = params["name"]
		else {
			print("pointset search: expected name\n")
			return
		}
		//let ts = TrajectorySearch<GmpRational>()
		let pointSet = try! pointSetManager.load(name: name)
		//var pathSet = PathSet()
		var searchResults: [TrajectorySearchResult] = []
		var feasibleCount = 0
		let apexQueue = DispatchQueue(
			label: "me.faec.billiards.apexQueue",
			attributes: .concurrent)
		let resultsQueue = DispatchQueue(label: "me.faec.billiards.resultsQueue")
		let apexGroup = DispatchGroup()
		var searchOptions = TrajectorySearchOptions()
		searchOptions.attemptCount = 25000
		searchOptions.maxPathLength = 2500
		searchOptions.skipExactCheck = true
		for point in pointSet.elements {
			apexGroup.enter()
			apexQueue.async {
				let result = TrajectorySearchForApexCoords(
					point, options: searchOptions)
				resultsQueue.sync(flags: .barrier) {
					if result.paths.count > 0 {
						feasibleCount += 1
					}
					searchResults.append(result)
					print("found \(feasibleCount) / \(searchResults.count) so far")
				}
				apexGroup.leave()
			}
		}
		apexGroup.wait()
		print("found \(feasibleCount) / \(pointSet.elements.count)")
	}

	func cmd_plot(_ args: [String]) {
		let params = ScanParams(args)
		guard let name = params["name"]
		else {
			print("pointset plot: expected name\n")
			return
		}
		let pointSet = try! pointSetManager.load(name: name)

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
		let turns = [3, -1, 1, -1, -3, 1, -2, 1, -3, -1, 1, -1, 3, 2]
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
			try pointSetManager.delete(name: name)
			logger.info("Deleted apex set '\(name)'")
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
		default:
			print("Unrecognized command '\(command)'")
		}
	}
}
