import BilliardLib

// a subdivision tree on the sphere.
// if children != nil, then polygon =
public class Tree<NodeData> {
  private weak var _parent: Tree<NodeData>?
  private var _children: [Tree<NodeData>]?
  public let data: NodeData

  public init(data: NodeData, parent: Tree? = nil) {
    self.data = data
    self._parent = parent
  }

  public var parent: Tree? {
    return _parent
  }

  public var children: [Tree]? {
    return _children
  }
  
  public func subdivide(_ childFactory: (Tree) -> [NodeData]?) {
    if self.children == nil {
      // If we're a leaf, check whether to add children
      guard let childData = childFactory(self) else { return }
      _children = childData.map {
        data in Tree(data: data, parent: self)
      }
    }
    guard let children = self.children else { return }
    for child in children {
      child.subdivide(childFactory)
    }
  }

  public func subdivideLeafs(
      _ childFactory: (Tree) -> [NodeData]?) {
    if let children = self.children {
      for child in children {
        child.subdivideLeafs(childFactory)
      }
      return
    }
    guard let childData = childFactory(self) else { return }
    _children = childData.map {
      data in Tree(data: data, parent: self)
    }
  }



  public func leafs() -> [Tree] {
    guard let children = self.children
    else {
      // no children, this node is a leaf
      return [self]
    }

    let subtreeLeafs = children.map { child in child.leafs() }
    let empty: [Tree<NodeData>] = []
    return subtreeLeafs.reduce(empty, +)
  }
}

extension Tree where NodeData: CustomStringConvertible {
  public func descriptionToLevel(_ level: UInt) -> String {
    if level == 0 {
      return "[...]"
    }
    guard let children = self.children else {
      return "Leaf(\(data))"
    }
    let childrenDescriptions = children.map { child in
      child.descriptionToLevel(level - 1)
    }
    let childrenStr = childrenDescriptions.joined(separator: ", ")
    return "Tree(\(data), [\(childrenStr)]"
  }
}
