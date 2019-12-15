public class PhaseMapRegion<k: Field & Comparable & CustomStringConvertible> {
  public let polygon: SphericalPolygon<k>
  public let transform: Matrix3x3<k>
  public init(polygon: SphericalPolygon<k>, transform: Matrix3x3<k>) {
    self.polygon = polygon
    self.transform = transform
  }
}

public class MinimalTrianglePhaseMap<
    k: Field & Comparable & CustomStringConvertible> {

  public let apex: Vec2<k>
  //public let affineVertices: [Vec2<k>]
  //public let vertices: [Vec3<k>]
  //public let phasePolygon: SphericalPolygon<k> = SphericalPolygon<k>.fullSphere

  //public let edgeReflections: [Matrix3x3<k>]

  public let regions: [PhaseMapRegion<k>]

  public init(apex: Vec2<k>) {
    self.apex = apex

    let coords: [Vec2<k>] = [
      Vec2(x: k.zero, y: k.zero),
      Vec2(x: k.one, y: k.zero),
      apex
    ]
    let center: Vec2<k> = k(1, over: 3) * (
      coords[0] + coords[1] + coords[2]
    )
    // let affineCenter = Vec2(k(1, over: 2), k.zero)
    let affineVertices = coords.map { v in v - center }
    let vertices = affineVertices.map { v in Vec3(x: v.x, y: v.y, z: k.one) }

    let edgeReflections = (0..<3).map { i -> Matrix3x3<k> in
      let cur = affineVertices[i]
      let next = affineVertices[(i+1) % 3]
      let reflection = Matrix3x3<k>.identity()
          .translatedBy(-cur)
          .reflectedThru(lineThruOrigin: (next - cur).cross())
          .translatedBy(cur)
      print("reflection thru \(cur) -> \(next):")
      print("\(reflection)")
      print("squared: \(reflection * reflection)")
      return -reflection
    }

    regions = (0..<3).map { i in
      PhaseMapRegion(
          polygon: SphericalPolygon<k>.fullSphere.withConstraints([
              vertices[i], -vertices[(i+1) % 3]]),
          transform: edgeReflections[i])
    }

    /*self.affineVertices = affineVertices
    self.vertices = vertices
    self.edgeReflections = edgeReflections*/
  }
/*
  public func edgePairForLine(_ line: Vec3<k>) -> EdgePair? {
    //print("edgePairForLine \(line)")
    let offsets = vertices.map { v in line.dot(v) }
    print("offsets \(offsets)")
    var from: Int? = nil
    var to: Int? = nil
    for i in 0..<3 {
      if offsets[i] < k.zero && offsets[(i + 1) % 3] > k.zero {
        to = i
      } else if offsets[i] > k.zero && offsets[(i + 1) % 3] < k.zero {
        from = i
      }
    }
    if from == nil || to == nil {
      // the line goes thru a vertex, or does not intersect the triangle
      return nil
    }
    return EdgePair(from: from!, to: to!)
  }

  public class EdgePair: CustomStringConvertible {
    public let from: Int
    public let to: Int

    init(from: Int, to: Int) {
      self.from = from
      self.to = to
    }

    public static prefix func -(_ edgePair: EdgePair) -> EdgePair {
      return EdgePair(from: edgePair.to, to: edgePair.from)
    }

    public var description: String {
      return "(from: \(from), to: \(to))"
    }
  }*/
}

public class QuadPhaseMap<
    k: Field & Comparable & CustomStringConvertible> {
  public let apex: Vec2<k>
  public let regions: [PhaseMapRegion<k>]
  public let rightBoundaryVertices: [Vec3<k>]
  public let vertices: [Vec3<k>]

  public init(apex: Vec2<k>) {
    self.apex = apex

    let affineVertices: [Vec2<k>] = [
      Vec2<k>.origin,
      apex,
      Vec2(k.zero, k(2) * apex.y),
      Vec2(apex.x - k.one, apex.y)
    ]
    let vertices = affineVertices.map { v in Vec3(x: v.x, y: v.y, z: k.one) }

    regions = (0..<4).map { i in
      let polygon = SphericalPolygon.fullSphere.withConstraints([
          vertices[i], -vertices[(i+1)%4]])

      let cur = affineVertices[i]
      let next = affineVertices[(i + 1) % 4]
      let transform = -Matrix3x3<k>.identity()
          .translatedBy(-cur)
          .reflectedThru(lineThruOrigin: (next - cur).cross())
          .translatedBy(cur)
      return PhaseMapRegion(
          polygon: polygon, transform: transform)
    }
    self.vertices = vertices
    rightBoundaryVertices = Array(vertices[..<3])
  }

}

public class DiscPhaseMap<k: Field & Comparable & CustomStringConvertible> {
  public let apex: Vec2<k>
  public let base: Singularities<Vec2<k>>
  //public let maxTurn: Int
  public let regions: [Index: Region]
  
  public typealias Index = Singularity.Turn
  public typealias Region = PhaseMapRegion<k>

  public init(apexOverBase apex: Vec2<k>) {
    let billiards = BilliardsData(apex: apex)
    
    let maxTurns = billiards.maxTurnAroundSingularity
    
    
    let base = Singularities(
      Vec2(x: -apex.x / apex.y, y: k.zero),
      Vec2(x: (k.one - apex.x) / apex.y, y: k.zero))
      //Vec2.origin, Vec2(x: k.one, y: k.zero))
    
    var regions: [Index: Region] = [:]
    for singularity in Singularity.all {
      let baseEdge = DiscPathEdge(
          billiards: billiards, coords: base,
          orientation: Singularity.Orientation.to(singularity),
          rotationCounts: Singularities(s0: 0, s1: 0))
      let centerConstraints = [
        Vec3(affineXY: baseEdge.apexForSide(.right)),
        -Vec3(affineXY: baseEdge.apexForSide(.left))
      ]
      let incomingPolygon = SphericalPolygon<k>.fromConstraints(centerConstraints)
      /*let incomingPolygon = SphericalPolygon.fromConstraints([
        Vec3(affineXY: baseEdge.apexForSide(.right)),
        -Vec3(affineXY: baseEdge.apexForSide(.left))])*/
      for turnDegree in -maxTurns[singularity]...maxTurns[singularity] {
        guard let turnSign = Sign.of(turnDegree)
        else { continue }
        let turn = Singularity.Turn(around: singularity, by: turnDegree)

        let turnedEdge = baseEdge.reversed().turnedBy(turnDegree)
        let lowerBoundary = turnedEdge.apexForSide(.right)
        let upperBoundary = turnedEdge.apexForSide(.left)
        let singularityBoundary = turnedEdge.fromCoords()
        let polygon = incomingPolygon.withConstraints([
          Vec3(affineXY: lowerBoundary),
          -Vec3(affineXY: upperBoundary),
          (-turnSign) * Vec3(affineXY: singularityBoundary)
          ])
        let rotationVector = billiards.rotationVectorAroundTurn(turn)
        let transform = Matrix3x3<k>.identity()
          .translatedBy(-baseEdge.coords[singularity])
          .dividedByComplex(rotationVector)
          .translatedBy(baseEdge.coords[singularity])

        regions[turn] = Region(
          polygon: polygon,
          transform: transform)
      }
      
      
    }

    self.base = base
    self.apex = apex
    self.regions = regions
  }
  
}

public class MonoDiscPhaseMap<k: Field & Comparable & CustomStringConvertible> {
  /*public let base: Singularities<Vec2<k>>
  //public let maxTurn: Int
  public let regions: [Index: Region]
  
  public typealias Index = UInt
  public typealias Region = PhaseMapRegion<k>

  public init(apexOverBase apex: Vec2<k>) {
    let billiards = BilliardsData(apex: apex)
    
    let maxTurns = billiards.maxTurnAroundSingularity
    
    
    let base = Singularities(
      Vec2(x: -apex.x / apex.y, y: k.zero),
      Vec2(x: (k.one - apex.x) / apex.y, y: k.zero))
      //Vec2.origin, Vec2(x: k.one, y: k.zero))
    
    var regions: [Index: Region] = [:]
  }*/
}
