
import Foundation

public struct Bound<T: Codable>: Codable {
	let min: T
	let max: T
}

public typealias CycleId = Int64

public struct CycleMetadata: Codable {
	public var feasiblePoint: Point
	
	public var annotation: [String]?
	public var apexBounds: Vec2<Bound<GmpRational>>?
	public var cotangentBounds: S2<Bound<GmpRational>>?
	public var angleRatio: Bound<Double>?
}

//public typealias CycleSet = [TurnCycle: CycleMetadata]

public class CycleSet {
	public var elements: [Element]
	public var cycleLookup: [TurnCycle: Int]
	public var idLookup: [CycleId: Int]
	public var nextId: CycleId
	
	public struct Element: Codable {
		public let id: CycleId
		public let cycle: TurnCycle
		public var metadata: CycleMetadata
	}
	
	public init() {
		self.elements = []
		self.cycleLookup = [:]
		self.idLookup = [:]
		self.nextId = 0
	}
	
	public init(elements: [Element]) {
		var cycleLookup: [TurnCycle: Int] = [:]
		var idLookup: [CycleId: Int] = [:]
		var nextId = Int64(0)
		for (index, element) in elements.enumerated() {
			cycleLookup[element.cycle] = index
			idLookup[element.id] = index
			nextId = max(nextId, element.id + 1)
		}
		self.elements = elements
		self.cycleLookup = cycleLookup
		self.idLookup = idLookup
		self.nextId = nextId
	}

	// returns true if the cycle was added to the set, false if it already
	// exists
	public func add(cycle: TurnCycle, feasiblePoint: Point) -> Bool {
		if let index = cycleLookup[cycle] {
			// TODO: integrate data from feasiblePoint into aggregate?
			return false
			//return elements[index]
		}
		let id = nextId
		let index = elements.count
		nextId += 1
		idLookup[id] = index
		cycleLookup[cycle] = index
		let metadata = CycleMetadata(feasiblePoint: feasiblePoint)
		let element = Element(id: id, cycle: cycle, metadata: metadata)
		elements.append(element)
		return true
		//return element
	}
	
	public subscript(_ id: CycleId) -> Element? {
		guard let index = idLookup[id]
		else {
			return nil
		}
		return elements[index]
	}
}


extension DataManager {
	public func loadCycleSet(name: String) throws -> CycleSet {
		do {
			let elements: [CycleSet.Element] =
				try loadPath(["cycleset", name, "elements.json"])
			return CycleSet(elements: elements)
		} catch {
			logger.error("Couldn't load cycle set '\(name)': \(error)")
			throw error
		}
	}

	public func saveCycleSet(_ cycleSet: CycleSet, name: String) throws {
		try save(cycleSet.elements, toPath: ["cycleset", name, "elements.json"])
	}
}
