import Foundation

func commonPrefixLength(_ a: [Int], _ b: [Int]) -> Int {
  let minCount = min(a.count, b.count)
  for i in 0..<minCount {
    if a[i] != b[i] {
      return i
    }
  }
  return minCount
}

// PathTree is a tree-based data structure that represents a set of
// closed (net angle zero) combinatorial paths. It provides a
// persistent index mapping between integers and paths.
class PathTree {
  var root: Node

  public init() {
    root = Node(segment: [], children: [], isPath: false)
  }

  public func addPath(_ path: [Int]) {
    //root = root.addPath(path)
  }

  // invariants:
  // - the root node has an empty segment
  // - all other nodes have nonempty segments
  // - every non-root leaf is a path
  // - every non-root node with only one child is a path
  class Node {
    weak var parent: Node?
    var segment: [Int]
    var isPath: Bool
    var children: [Node]

    init(segment: [Int], children: [Node], isPath: Bool) {
      self.segment = segment
      self.children = children
      self.isPath = isPath
    }

    func childIndexStartingWith(_ value: Int) -> Int? {
      for (index, child) in children.enumerated() {
        if child.segment.first! == value {
          return index
        }
      }
      return nil
    }

    func addPath(_ path: [Int]) {
      let prefixLength = commonPrefixLength(path, segment)
      if prefixLength == segment.count {
        if path.count == segment.count {
          // the path being added points to the current node
          isPath = true
        } else {
          // path matches segment completely and extends
          // beyond it, so it must be added as a child.
          let pathTail = path[prefixLength...]
          if let index = childIndexStartingWith(pathTail.first!) {

          } else {
            //children.append(Node(segment: pathTail, ))
          }
        }
      } else {
        // this node needs to be split.
        // it is guaranteed that prefixLength > 0, because
        // the root's segment length is zero and the recursion
        // case only passes it through if there's a match.

      }
    }
  }

}