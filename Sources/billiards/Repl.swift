import Foundation
import Logging

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
			
			//print("")
			//print("cancel: \(cancel())")
			//sleep(5)
			displayPrompt()
			guard let line = readLine(strippingNewline: true)
			else {
				// reached the end of stdin
				return
			}
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
				PathSetCopy(dataManager: dataManager, args: Array(words[2...]))
			} else {
				fputs("cyclset: unrecognized comand \"\(words[1])\"\n", stderr)
				return
			}
		}
		
	}
}

func PathSetCopy(dataManager: DataManager, args: [String]) {
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
	guard let knownCycles: [Int: TurnCycle] =
		(try? dataManager.loadPath(["pointset", from, "cycles"]))
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
