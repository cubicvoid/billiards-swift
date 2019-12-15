import Foundation

/*
func VerifyPaths(paths: [String]) -> String {
  typealias k = GmpRational
  let grid = RestoreEvalGrid()
  var newAreaSum = k.zero()
  var totalArea = k.zero()
  for p in paths {
    if !PathIsAbstractCycle(p.asEdgePath()) {
      NSLog("Bad path, skipping: \(p)")
      continue
    }
    let (newVerifiedArea, totalVerifiedArea) =
      grid.testPath(
        pathString: p, minDepth: 7, maxDepth: 8)
    newAreaSum += newVerifiedArea
    totalArea = totalVerifiedArea
  }
  SaveEvalGrid(grid)
  let (verified, total) = grid.totalCoverage()
  // TODO: This might be wrong i don't really understand what testPath returns.
  return "\(newAreaSum / totalArea) (\(verified / total))"
}

class PathInfo<R: Ring> {
  var edgePath: EdgePath
  var pathString: String
  
  // Upper and lower bound polynomials in the x/y coords of the apex.
  var _lowerBounds: [Polynomial<R>]?
  var _upperBounds: [Polynomial<R>]?
  
  // Left and right coordinate boundaries in the x/y coords of the apex.
  var _leftBoundary: [Coords2d<Polynomial<R>>]?
  var _rightBoundary: [Coords2d<Polynomial<R>>]?
  
  public init(pathString: String) {
    self.pathString = pathString
    self.edgePath = pathString.asEdgePath()
  }
  
  func _cache() {
    if _leftBoundary == nil || _rightBoundary == nil {
      NSLog("Computing bounds for path: \(pathString)")
      let (left, right) =
        PathBoundaryPolynomials(path: edgePath, ringElement: R.one())
      _leftBoundary = left
      _rightBoundary = right
      NSLog("Done")
    }
  }
  public var upperBounds: [Polynomial<R>] {
    self._cache()
    return _upperBounds!
  }
  public var lowerBounds: [Polynomial<R>] {
    self._cache()
    return _lowerBounds!
  }
  
  public var leftBoundary: [Coords2d<Polynomial<R>>] {
    self._cache()
    return _leftBoundary!
  }
  public var rightBoundary: [Coords2d<Polynomial<R>>] {
    self._cache()
    return _rightBoundary!
  }
}

protocol JSON {
  init(fromJSONObject: Any)
  func asJSONObject() -> Any
}

extension GmpRational: JSON {
  public convenience init(fromJSONObject json: Any) {
    self.init(fromString: json as! String)
  }
  
  public func asJSONObject() -> Any {
    return self.description
  }
}


final class EvalGrid<k: Field & Comparable & JSON & Numeric> {
  let xInterval: Interval<k>
  let yInterval: Interval<k>
  // A filter on x and y intervals that returns false iff the given intervals
  // have *zero* intersection with the target area.
  let filter: (Interval<k>, Interval<k>) -> Bool
  var _pathCache: [String: PathInfo<k>]
  
  var _root: EvalSquare<k>?
  var _jsonRoot: Any?
  
  public init(xInterval: Interval<k>, yInterval: Interval<k>,
              filter: @escaping (Interval<k>, Interval<k>) -> Bool) {
    self.xInterval = xInterval
    self.yInterval = yInterval
    self.filter = filter
    self._pathCache = [:]
  }
  
  public init(fromJSONObject json: Any,
              filter: @escaping (Interval<k>, Interval<k>) -> Bool) {
    self.filter = filter
    self._pathCache = [:]
    let dict = json as! [String: Any]
    let xmin = k(fromJSONObject: dict["xmin"]!)
    let xmax = k(fromJSONObject: dict["xmax"]!)
    let ymin = k(fromJSONObject: dict["ymin"]!)
    let ymax = k(fromJSONObject: dict["ymax"]!)
    self.xInterval = Interval<k>(xmin, xmax)
    self.yInterval = Interval<k>(ymin, ymax)
    self._jsonRoot = dict["root"]!
  }
  
  public var root: EvalSquare<k> {
    if _root == nil {
      if _jsonRoot == nil {
        _root = EvalSquare(grid: self,
                           xInterval: xInterval,
                           yInterval: yInterval,
                           level: 0)
      } else {
        _root = EvalSquare(fromJSONObject: _jsonRoot!, grid: self)
        _jsonRoot = nil
      }
    }
    return _root!
  }
  
  public func testPath(pathString: String, minDepth: Int, maxDepth: Int)
      -> (k, k) {
    if _pathCache[pathString] == nil {
      _pathCache[pathString] = PathInfo<k>(pathString: pathString)
    }
    return root.testPath(
        path: _pathCache[pathString]!, minDepth: minDepth, maxDepth: maxDepth)
  }
  
  public func asJSONObject() -> Any {
    return [
      "root": root.asJSONObject(),
      "xmin": xInterval.min.asJSONObject(),
      "xmax": xInterval.max.asJSONObject(),
      "ymin": yInterval.min.asJSONObject(),
      "ymax": yInterval.max.asJSONObject()]
  }
  
  public func totalCoverage() -> (k, k) {
    return root.coverage()
  }
}

class EvalSquare<k: Field & Comparable & JSON & Numeric> {
  let grid: EvalGrid<k>
  let xInterval: Interval<k>
  let yInterval: Interval<k>
  let level: Int  // The degree of recursion, or -log_2 of the square size
  
  var verifiedPath: String?
  var _children: [EvalSquare<k>]?
  public init(grid: EvalGrid<k>,
              xInterval: Interval<k>,
              yInterval: Interval<k>,
              level: Int) {
    self.grid = grid
    self.xInterval = xInterval
    self.yInterval = yInterval
    self.level = level
  }
  
  public init(fromJSONObject json: Any, grid: EvalGrid<k>) {
    self.grid = grid
    let dict = json as! [String: Any]
    let xmin = k(fromJSONObject: dict["xmin"]!)
    let xmax = k(fromJSONObject: dict["xmax"]!)
    let ymin = k(fromJSONObject: dict["ymin"]!)
    let ymax = k(fromJSONObject: dict["ymax"]!)
    self.xInterval = Interval<k>(xmin, xmax)
    self.yInterval = Interval<k>(ymin, ymax)
    self.level = Int(dict["level"] as! String)!
    self.verifiedPath = dict["verifiedPath"] as? String
    let jsonChildren = dict["children"] as? [Any]
    if jsonChildren != nil {
      _children =
          jsonChildren!.map {EvalSquare<k>(fromJSONObject: $0, grid: grid)}
    }
  }
  
  public func asJSONObject() -> Any {
    var result: [String: Any] = [
      "xmin": xInterval.min.description,
      "xmax": xInterval.max.description,
      "ymin": yInterval.min.description,
      "ymax": yInterval.max.description,
      "level": level.description
    ]
    if verifiedPath != nil {
      result["verifiedPath"] = verifiedPath!
    }
    if _children != nil {
      let childArray = _children!.map {$0.asJSONObject()}
      result["children"] = childArray
    }
    return result
  }
  
  static func _childIndex(xIndex: Int, yIndex: Int) -> Int {
    return yIndex * 2 + xIndex
  }
  
  func _cornerCount(path: EdgePath) -> Int {
    var count = 0
    for x in [xInterval.min, xInterval.max] {
      for y in [yInterval.min, yInterval.max] {
        if VerifiedRadiusForPath(path, withApex: Coords2d(x: x, y: y)) != nil {
          count += 1
        }
      }
    }
    return count
  }
  
  public func center() -> Coords2d<k> {
    return Coords2d(x: xInterval.center(), y: yInterval.center())
  }
  
  func _split() {
    if _children != nil {
      return
    }
    let center = self.center()
    let xIntervals = [
      Interval(xInterval.min, center.x),
      Interval(center.x, xInterval.max)
    ]
    let yIntervals = [
      Interval(yInterval.min, center.y),
      Interval(center.y, yInterval.max)
    ]
    var children: [EvalSquare] = []
    for xi in 0...1 {
      for yi in 0...1 {
        children.append(EvalSquare(
          grid: grid,
          xInterval: xIntervals[xi],
          yInterval: yIntervals[yi],
          level: level + 1))
      }
    }
    _children = children
  }
  
  // Counts expected gains only by direct eval, doesn't construct polys
  // or check rigorous bounds.
  func estimatePath(path: PathInfo<k>, minDepth: Int, maxDepth: Int) -> (k, k) {
    if !grid.filter(xInterval, yInterval) {
      return (k.zero(), k.zero())
    }
    if verifiedPath != nil {
      return (k.zero(), k.one())
    }
    let cornerCount = self._cornerCount(path: path.edgePath)
    if cornerCount == 4 {
      return (k.one(), k.one())
    }
    if level < minDepth || (level < maxDepth && cornerCount > 0) {
      self._split()
      var verifiedSum = k.zero()
      var totalSum = k.zero()
      for c in _children! {
        let (verified, total) =
          c.testPath(path: path, minDepth: minDepth, maxDepth: maxDepth)
        verifiedSum = verifiedSum + verified
        totalSum = totalSum + total
      }
      verifiedSum = verifiedSum / k(4)
      totalSum = totalSum / k(4)
      return (verifiedSum, totalSum)
    }
    return (k.zero(), k.one())
  }
  
  public func coverage() -> (k, k) {
    if !grid.filter(xInterval, yInterval) {
      return (k.zero(), k.zero())
    }
    if verifiedPath != nil {
      return (k.one(), k.one())
    }
    if _children != nil {
      var verifiedSum = k.zero()
      var totalSum = k.zero()
      for c in _children! {
        let (verified, total) = c.coverage()
        verifiedSum = verifiedSum + verified
        totalSum = totalSum + total
      }
      verifiedSum = verifiedSum / k(4)
      totalSum = totalSum / k(4)
      return (verifiedSum, totalSum)
    }
    return (k.zero(), k.one())
  }
  
  func unsolved() -> [EvalSquare<k>] {
    if verifiedPath != nil {
      return []
    }
    if _children != nil {
      var result: [EvalSquare<k>] = []
      for c in _children!.reversed() {
        result.append(contentsOf: c.unsolved())
      }
      return result
    }
    return [self]
  }
  
  func testPath(path: PathInfo<k>, minDepth: Int, maxDepth: Int) -> (k, k) {
    if !grid.filter(xInterval, yInterval) {
      return (k.zero(), k.zero())
    }
    if verifiedPath != nil {
      return (k.zero(), k.one())
    }
    let center = self.center()
    let rx = xInterval.max - center.x
    let ry = yInterval.max - center.y
    let cornerCount = self._cornerCount(path: path.edgePath)
    if cornerCount == 4 {
      NSLog("Possible match found (\(center.x), \(center.y)), radius (\(rx), \(ry)), checking...")
      var curBound = 1
      let vars = [
          Polynomial(fromVarIndex: 0) + Polynomial(fromScalar: center.x),
          Polynomial(fromVarIndex: 1) + Polynomial(fromScalar: center.y)
      ]
      let centeredLeftBoundary: [Coords2d<Polynomial<k>>] = path.leftBoundary.map
      { (b: Coords2d<Polynomial<k>>) in
        NSLog("Centering bound \(curBound)")
        curBound += 1
        return Coords2d(x: b.x.evaluate(vars: vars),
                        y: b.y.evaluate(vars: vars))
      }
      let centeredRightBoundary: [Coords2d<Polynomial<k>>] = path.rightBoundary.map
      { (b: Coords2d<Polynomial<k>>) in
        NSLog("Centering bound \(curBound)")
        curBound += 1
        return Coords2d(x: b.x.evaluate(vars: vars),
                        y: b.y.evaluate(vars: vars))
      }
      let (centeredLowerBounds, centeredUpperBounds) =
          BoundsForPathBoundaries(leftBoundary: centeredLeftBoundary,
                                  rightBoundary: centeredRightBoundary)
      var allMargins: [Polynomial<k>] = []
      for u in centeredUpperBounds {
        for l in centeredLowerBounds {
          allMargins.append(u - l)
        }
      }
      var cornerMins: [k] = []
      for dx in [-rx, rx] {
        for dy in [-ry, ry] {
          let corner = [dx, dy]
          let cornerValues = allMargins.map {
            $0.evaluate(vars: corner)
          }
          cornerMins.append(cornerValues.min()!)
        }
      }
      let cornerMin = cornerMins.min()!
      NSLog("Projected margin \(cornerMin.asDouble())")
      let xRadius = xInterval.width() / k(2)
      let yRadius = yInterval.width() / k(2)
      // Extract a little more precision by splitting the variable ranges
      // into quadrants.
      let xIntervals = [
          Interval<k>(-xRadius, k.zero()),
          Interval<k>(k.zero(), xRadius)
      ]
      let yIntervals = [
          Interval<k>(-yRadius, k.zero()),
          Interval<k>(k.zero(), yRadius)
      ]
      var minMargin: k? = nil
      for localX in xIntervals {
        for localY in yIntervals {
          let values = allMargins.map {
            $0.evalInterval(vars: [localX, localY]).min
          }
          let min = values.min()!
          if minMargin == nil || min < minMargin! {
            minMargin = min
          }
        }
      }
      //let localX = Interval<k>(-xRadius, xRadius)
      //let localY = Interval<k>(-yRadius, yRadius)
      if minMargin! > k.zero() {
        // Success!
        NSLog("Match, margin \(minMargin!.asDouble())")
        self.verifiedPath = path.pathString
        return (k.one(), k.one())
      } else {
        NSLog("No match, margin \(minMargin!.asDouble())")
      }
    }
    if level < minDepth || (level < maxDepth && cornerCount > 0) {
      self._split()
      //NSLog("Recursing at level \(level)")
      // Recurse
      var verifiedSum = k.zero()
      var totalSum = k.zero()
      for c in _children! {
        let (verified, total) =
          c.testPath(path: path, minDepth: minDepth, maxDepth: maxDepth)
        verifiedSum = verifiedSum + verified
        totalSum = totalSum + total
      }
      verifiedSum = verifiedSum / k(4)
      totalSum = totalSum / k(4)
      return (verifiedSum, totalSum)
    }
    return (k.zero(), k.one())
  }
}

func RestoreEvalGrid() -> EvalGrid<GmpRational> {
  typealias k = GmpRational
  let basePath = NSSearchPathForDirectoriesInDomains(
    FileManager.SearchPathDirectory.applicationSupportDirectory,
    FileManager.SearchPathDomainMask.userDomainMask, true)[0]
  
  let baseUrl = URL(fileURLWithPath: basePath)
  let appUrl = baseUrl.appendingPathComponent("Billiards")
  let fileUrl = appUrl.appendingPathComponent("grid")
  let filter = { (xInterval: Interval<k>, yInterval: Interval<k>) -> Bool in
    // Filter anything with the bottom-right corner outside the
    // radius-1/2 circle centered at (1/2, 0), since either the triangle
    // is acute or the base is not the longest edge.
    let dx = xInterval.max - k(1, over: 2)
    let dy = yInterval.min
    let cutoff = k(1, over: 4)
    return (dx * dx + dy * dy < cutoff)
  }
  NSLog("Trying to restore eval grid from \(fileUrl)")
  let input = InputStream(url: fileUrl)
  if input != nil {
    do {
      NSLog("Trying to load data")
      input!.open()
      let json = try JSONSerialization.jsonObject(with: input!)
      input!.close()
      return EvalGrid(fromJSONObject: json, filter: filter)
    } catch let error as NSError {
      NSLog("Couldn't restore data: \(error)")
    }
  } else {
    NSLog("No data found, starting fresh")
  }
  return EvalGrid(
    xInterval: Interval<k>(k(0), k(1, over: 2)),
    yInterval: Interval(k(0), k(1, over: 2)),
    filter: filter)
}

func SaveEvalGrid(_ grid: EvalGrid<GmpRational>) {
  let basePath = NSSearchPathForDirectoriesInDomains(
    FileManager.SearchPathDirectory.applicationSupportDirectory,
    FileManager.SearchPathDomainMask.userDomainMask, true)[0]
  
  let baseUrl = URL(fileURLWithPath: basePath)
  let appUrl = baseUrl.appendingPathComponent("Billiards")
  let fileUrl = appUrl.appendingPathComponent("grid")
  do {
    try FileManager.default.createDirectory(
      at: appUrl, withIntermediateDirectories: true, attributes: nil)
    let out = OutputStream(url: fileUrl, append: false)!
    out.open()
    JSONSerialization.writeJSONObject(
      grid.asJSONObject(),
      to: out,
      options:JSONSerialization.WritingOptions.prettyPrinted,
      error: nil)//&error)
    out.close()
    
  } catch let error as NSError {
    NSLog("Couldn't save: \(error)")
  }
}
*/
