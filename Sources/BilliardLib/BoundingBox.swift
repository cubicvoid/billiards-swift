public class Dimensions {
  public let width: Double
  public let height: Double

  public init(width: Double, height: Double) {
    self.width = width
    self.height = height
  }
}

public class AxisRect: CustomStringConvertible {
  public let origin: Vec2<Double>
  public let dimensions: Dimensions

  public init(origin: Vec2<Double>, dimensions: Dimensions) {
    self.origin = origin
    self.dimensions = dimensions
  }

  public var description: String {
    return "(\(origin.x),\(origin.y) - (\(origin.x+dimensions.width),\(origin.y+dimensions.height))"
  }
}

public func BoundingBoxForCoords<k: Numeric>(
    _ coords: Array<Vec2<k>>) -> AxisRect? {
  if coords.count == 0 {
    return nil
  }
  var xMin = coords[0].x.asDouble(), xMax = coords[0].x.asDouble()
  var yMin = coords[0].y.asDouble(), yMax = coords[0].y.asDouble()
  for c in coords {
    let x = c.x.asDouble()
    let y = c.y.asDouble()
    xMin = min(x, xMin)
    xMax = max(x, xMax)
    yMin = min(y, yMin)
    yMax = max(y, yMax)
  }
  return AxisRect(
    origin: Vec2(x: xMin, y: yMin),
    dimensions: Dimensions(width: xMax - xMin, height: yMax - yMin))
}
