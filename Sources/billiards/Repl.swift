import Foundation
import Logging

import Clibedit

import BilliardLib

// This handler:
// - should only be created once at a time
// - will stop working if it goes out of scope
class SigintHandler {
	private let signalQueue: DispatchQueue
	private let sigintSrc: DispatchSourceSignal
	var sigintCount: Int = 0
	var cancel: Bool = false
	
	init() {
		signal(SIGINT, SIG_IGN)
		signalQueue = DispatchQueue(
			label: "me.faec.billiards.signalQueue")
		sigintSrc = DispatchSource.makeSignalSource(
			signal: SIGINT,
			queue: signalQueue)
		sigintSrc.setEventHandler {
			print(White("Shutting down..."))
			self.sigintCount += 1
			self.cancel = true
			
			if self.sigintCount >= 5 {
				exit(-1)
			}
		}
		sigintSrc.resume()
	}
	
	func reset() {
		signalQueue.sync {
			sigintCount = 0
			cancel = false
		}
	}
}

func captureSigint() -> () -> Bool {
	let handler = SigintHandler()
	return { () -> Bool in handler.cancel }
}



class BilliardsRepl {
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
	
	func displayPrompt() {
		print(ClearCurrentLine(), terminator: "\r")
		print("> ", terminator: "")
	}

	public func run() {
		let handler = SigintHandler()


		while true {
			handler.reset()
			guard let cString = readline("> ")
			else {
				break
			}
			add_history(cString)
			let line = String(cString: cString)
			free(cString)

			//print("")
			//print("cancel: \(cancel())")
			//sleep(5)
			//displayPrompt()
			//guard let line = readLine(strippingNewline: true)
			//else {
				// reached the end of stdin
				//return
			//}
			execLine(line)
		}
	}
	
	public func execLine(_ line: String) {
		// just convert to strings, we aren't fancy enough to benefit from
		// substrings yet
		let words = line.split(separator: " ").map { String($0) }
		if words.count == 0 {
			return
		}
		if words[0] == "cycleset" {
			if words.count <= 1 {
				fputs("cycleset: expected command\n", stderr)
				return
			}
			if words[1] == "copy" {
				CycleSetCopy(dataManager: dataManager, args: Array(words[2...]))
			} else if words[1] == "plot" {
				CycleSetPlot(dataManager: dataManager, args: Array(words[2...]))
			} else if words[1] == "print" {
				CycleSetPrint(dataManager: dataManager, args: Array(words[2...]))
			} else if words[1] == "checkerplot" {
				CycleSetCheckerPlot(dataManager: dataManager, args: Array(words[2...]))
			} else {
				fputs("cycleset: unrecognized comand \"\(words[1])\"\n", stderr)
				return
			}
		}
		
	}
}

func CycleSetPrint(dataManager: DataManager, args: [String]) {
	let params = ScanParams(args)
	guard let name: String = params["name"]
	else {
		fputs("cycleset print: expected 'name'\n", stderr)
		return
	}
	guard let cycleSet = try? dataManager.loadCycleSet(name: name)
	else {
		fputs("cycleset print: couldn't load cycle name '\(name)'", stderr)
		return
	}
	for e in cycleSet.elements {
		print("\(e.id): \(e.cycle)")
	}
	
}

func CycleSetCopy(dataManager: DataManager, args: [String]) {
	let params = ScanParams(args)
	guard let from: String = params["from"]
	else {
		fputs("cycleset copy: expected 'from'\n", stderr)
		return
	}
	guard let to: String = params["to"]
	else {
		fputs("cycleset copy: expected 'to'\n", stderr)
		return
	}

	let pointSet = try! dataManager.loadPointSet(name: from)
	guard let knownCycles: [Int: TurnPath] =
		(try! dataManager.loadPath(["pointset", from, "cycles"]))
	else {
		fputs("cycleset copy: couldn't find known cycles for pointset '\(from)'\n", stderr)
		return
	}

	let cycleSet = (try? dataManager.loadCycleSet(name: to)) ?? CycleSet()
	print("Copying paths from pointset '\(from)' (\(knownCycles.count) entries) " +
		"to cycleset '\(to)' (\(cycleSet.elements.count) entries)")
	
	var added = 0
	for (pointIndex, cycle) in knownCycles {
		let point = pointSet.elements[pointIndex]
		if cycleSet.add(cycle: cycle, feasiblePoint: point) {
			added += 1
		}
	}
	try! dataManager.saveCycleSet(cycleSet, name: to)
	
	print("\(added) cycles copied")
}

func CycleSetPlot(dataManager: DataManager, args: [String]) {
	if args.count < 1 {
		fputs("cycleset plot: expected cycle\n", stderr)
		return
	}
	
	switch LoadCycleSpec(args[0], dataManager: dataManager) {
	case .success(let element):
		let apex = element.metadata.feasiblePoint.asDoubleVec()
		print("plotting cycle: \(element.cycle)")
		print("feasible point: \(apex)")
		PlotCycle(element.cycle, knownApex: apex)
	case .failure(let error):
		print("cycleset plot: \(error.description)")
	}
}

func CycleSetCheckerPlot(dataManager: DataManager, args: [String]) {
	let params = ScanParams(args)
	if params.words.count < 1 {
		fputs("cycleset checkerplot: expected cycle\n", stderr)
		return
	}
	let imageWidth: Int = params["w"] ?? 500
	let imageHeight: Int = params["h"] ?? 500
	let viewWidth: Int = params["vw"] ?? 3
	let viewHeight: Int = params["vh"] ?? 3
	
	switch LoadCycleSpec(params.words[0], dataManager: dataManager) {
	case .success(let element):

		let apex = element.metadata.feasiblePoint
		print("plotting cycle: \(element.cycle)")
		print("feasible point: \(apex)")
		//PlotCycle(element.cycle, knownApex: apex)
		CheckerPlotCycle(element.cycle, knownApex: apex,
			imageWidth: imageWidth, imageHeight: imageHeight,
			viewWidth: viewWidth, viewHeight: viewHeight)
	case .failure(let error):
		print("cycleset plot: \(error.description)")
	}
}

public struct ReplError: Error {
	let description: String
}

func LoadCycleSpec(
	_ spec: String, dataManager: DataManager
) -> Result<CycleSet.Element, ReplError> {
	// match specs like "cyclesetname[5]"
	let pattern = #"^(\w+)\[(\d+)\]$"#
	let regex = try! NSRegularExpression(pattern: pattern)
	let nsrange = NSRange(spec.startIndex..<spec.endIndex, in: spec)
	/*guard let match = regex.firstMatch(in: spec, range: nsrange)
	else {
		return .failure(ReplError(description: "couldn't parse cycle '\(spec)'"))
	}*/
	if
		let match = regex.firstMatch(in: spec, range: nsrange),
		match.numberOfRanges == 3,
	  let nameRange = Range(match.range(at: 1), in: spec),
		let indexRange = Range(match.range(at: 2), in: spec),
		let index = Int(spec[indexRange])
	{
		let name = String(spec[nameRange])
		guard let cycleSet = try? dataManager.loadCycleSet(name: name)
		else {
			return .failure(ReplError(description: "couldn't load cycleset '\(name)'"))
		}
		guard let entry = cycleSet[CycleId(index)]
		else {
			return .failure(ReplError(description: "cycleset '\(name)' has no entry at index \(index)"))
		}
		return .success(entry)
		//print("cycle set \(name) index \(index)")
	}
	return .failure(ReplError(description: "couldn't parse cycle '\(spec)'"))
}

public func Thing() {
	while let cString = readline("> ") {
		add_history(cString)
		let line = String(cString: cString)
		free(cString)
		print(line)
	}
}
