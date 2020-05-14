
public class PathSet {
	private var _nextID: Int = 0
	private var _root: TreeNode

	// Initializes an empty PathSet
	public init() {
		_root = TreeNode()
	}

	public func copy() -> PathSet {
		print("copy() isn't written yet")
		return self
	}

	/*public func add(_ path: TurnCycle) {
		
	}*/

	class TreeNode {
		// nil if this path set doesn't contain the path ending at this
		// node, otherwise a unique integer identifying this path. Path
		// IDs are stable under insertion, i.e. a single ID will never
		// change once it is chosen.
		var pathID: Int? = nil
		var children: [Child] = []

		class Child {
			let turnPrefix: [Int]
			let node: TreeNode

			init(turnPrefix: [Int], node: TreeNode) {
				self.turnPrefix = turnPrefix
				self.node = node
			}
		}
	}
}