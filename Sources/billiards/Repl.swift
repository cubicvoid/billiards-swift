import Foundation

import BilliardLib

// This handler
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
	public init() {
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
		}
	}
}

