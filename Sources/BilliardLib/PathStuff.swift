
public class TurnCycleSet {
	private var _nextID: Int = 0
	private var _root: TreeNode
	private var _nodes: [TreeNode]

	// Initializes an empty TurnCycleSet
	public init() {
		_root = TreeNode()
		_nodes = []
	}

	public func add(_ cycle: TurnCycle) -> Index {
		return Index(turnCycleSet: self, nodeIndex: 0)
	}

	subscript(index: Index) -> TurnCycle? {
		if index.turnCycleSet !== self {
			return nil
		}
		return nil
	}

	public struct Index {
		weak var turnCycleSet: TurnCycleSet?
		let nodeIndex: Int
	}

	private class TreeNode {
		// nil if this path set doesn't contain the path ending at this
		// node, otherwise a unique integer identifying this path. Path
		// IDs are stable under insertion, i.e. a single ID will never
		// change once it is chosen.
		var cycle: Bool = false
		var children: [Child] = []

		init() {
		}

		struct Child {
			let turnPrefix: [Int]
			let nodeIndex: Int
		}
	}
}