public class Triangle<R : Ring> {
  public var v : [Vec2<R>]
  public init(_ v1: Vec2<R>, _ v2 : Vec2<R>, _ v3 : Vec2<R>) {
    self.v = [v1, v2, v3]
  }
  public func copy() -> Triangle {
    return Triangle(v[0], v[1], v[2])
  }

  public func edge(index : Int) -> Vec2<R> {
    return v[Mod3(index + 1)] - v[Mod3(index)]
  }
}

extension Triangle: CustomStringConvertible {
  public var description: String {
    return "Triangle[\(self.v[0]) \(self.v[1]) \(self.v[2])]"
  }
} 

extension Triangle where R : Field {
  public func reflectThrough(edgeIndex : Int) {
    let vertexIndex = (edgeIndex + 2) % 3
    let edgeVector = self.edge(index: edgeIndex)
    let vertexVector = -self.edge(index: edgeIndex - 1)
    let projectionCoeff =
        vertexVector.dot(edgeVector) / edgeVector.dot(edgeVector)
    let delta = projectionCoeff * edgeVector - vertexVector
    self.v[vertexIndex] = self.v[vertexIndex] + (delta + delta)
  }
}
