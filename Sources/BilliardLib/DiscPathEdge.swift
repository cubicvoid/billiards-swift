public enum Side: CanonicalNegation {
  case left
  case right

  public static prefix func -(s: Side) -> Side {
    switch s {
      case .left: return .right
      case .right: return .left
    }
  }
}

public class FanPathEdgeDeprecated<k: Field & Comparable> {
  public var coords: Singularities<Vec2<k>>
  public var orientation: Singularity.Orientation
  public var rotationCounts: Singularities<Int>

  let params: BilliardsParamsDeprecated<k>

  public init(
      params: BilliardsParamsDeprecated<k>, coords: Singularities<Vec2<k>>,
      orientation: Singularity.Orientation, rotationCounts: Singularities<Int>) {
    self.params = params
    self.coords = coords
    self.orientation = orientation
    self.rotationCounts = rotationCounts
  }

  public convenience init(
      fromParams params: BilliardsParamsDeprecated<k>,
      orientation: Singularity.Orientation) {
    let origin = Vec2<k>.origin
    let coords = Singularities(
        origin - params.apexFromBase[.S0] * Sign(of: orientation),
        origin - params.apexFromBase[.S1] * Sign(of: orientation))
    self.init(params: params, coords: coords, orientation: orientation,
        rotationCounts: Singularities(0, 0))
  }

  public func copy() -> FanPathEdgeDeprecated<k> {
    return FanPathEdgeDeprecated(
        params: params, coords: coords, orientation: orientation,
        rotationCounts: rotationCounts)
  }

  public func fromCoords() -> Vec2<k> {
    return coords[orientation.from]
  }

  public func toCoords() -> Vec2<k> {
    return coords[orientation.to]
  }

  public func apexForSide(_ side: Side) -> Vec2<k> {
    // the apex on the left (widdershins) side of this edge in its starting
    // position at the origin.
    let baseCoords = coords[.S0]
    let baseOffset = coords[.S1] - coords[.S0]
    let leftApex = params
        .apexFromBase[.S0]
        .complexConjugateBySign(Sign(of: orientation))
    switch side {
    case .left:
      return baseCoords + baseOffset.complexMul(leftApex)
    case .right:
      return baseCoords + baseOffset.complexMul(leftApex.complexConjugate())
    }
  }

  public func turnBy(_ turnDegree: Int) -> FanPathEdgeDeprecated<k> {
    // We rotate around the singularity we're pointing at
    /*let turn: Singularity.Turn = orientation.to.turnBy(turnDegree)
    let rotationCoeff = params.vectorForTurn(turn)
    let baseOffset = coords[orientation.from] - coords[orientation.to]
    let newCoords = -Sign(of: orientation) * Singularities(
        s0: coords[orientation.to],
        s1: coords[orientation.to] + baseOffset.complexMul(rotationCoeff))

    let newCount = rotationCounts[orientation.to] + turnDegree
    let newRotationCounts =
        rotationCounts.withValue(newCount, forSingularity: orientation.to)*/

    return FanPathEdgeDeprecated(
        params: params,
        coords: coords,//newCoords,
        orientation: -orientation,
        rotationCounts: rotationCounts)//newRotationCounts)
  }

  public func isAngleZero() -> Bool {
    return (rotationCounts[.S0] == 0 && rotationCounts[.S1] == 0)
  }
}

public class DiscPathEdge<k: Field & Comparable> {
  public var coords: Singularities<Vec2<k>>
  public var orientation: Singularity.Orientation
  public var rotationCounts: Singularities<Int>
  
  let billiards: BilliardsData<k>
  
  public init(
    billiards: BilliardsData<k>, coords: Singularities<Vec2<k>>,
    orientation: Singularity.Orientation, rotationCounts: Singularities<Int>) {
    self.billiards = billiards
    self.coords = coords
    self.orientation = orientation
    self.rotationCounts = rotationCounts
  }
  
  public convenience init(
    billiards: BilliardsData<k>, coords: Singularities<Vec2<k>>) {
    self.init(billiards: billiards, coords: coords, orientation: .forward,
              rotationCounts: Singularities(0, 0))
  }
  
  public func fromCoords() -> Vec2<k> {
    return coords[orientation.from]
  }
  
  public func toCoords() -> Vec2<k> {
    return coords[orientation.to]
  }
  
  private func _apexForSide(
      _ side: Side, orientation: Singularity.Orientation) -> Vec2<k> {
    if orientation == .backward {
      return _apexForSide(-side, orientation: .forward)
    }
    let baseCoords = coords[.S0]
    let offset = coords[.S1] - coords[.S0]
    var apexCoeff = billiards.apexOverBase[.S0]
    if side == .right {
      apexCoeff = apexCoeff.complexConjugate()
    }
    return baseCoords + offset.complexMul(apexCoeff)
  }
  
  public func apexForSide(_ side: Side) -> Vec2<k> {
    return _apexForSide(side, orientation: orientation)
  }
  
  public func turnedBy(_ turnDegree: Int, angleBound: AngleBound) -> DiscPathEdge<k>? {
    guard let rotationCoeff =
        billiards.rotation[orientation.from].pow(turnDegree, angleBound: angleBound)
    else { return nil }
    let initialOffset = coords[orientation.to] - coords[orientation.from]
    let newOffset = initialOffset.complexMul(rotationCoeff)
    let newCoords = coords.withValue(coords[orientation.from] + newOffset, forSingularity: orientation.to)
    
    let newCount = rotationCounts[orientation.from] + turnDegree
    let newRotationCounts =
      rotationCounts.withValue(newCount, forSingularity: orientation.from)
    
    return DiscPathEdge(
      billiards: billiards,
      coords: newCoords,
      orientation: orientation,
      rotationCounts: newRotationCounts)
  }
  
  public func reversed() -> DiscPathEdge<k> {
    return DiscPathEdge(
        billiards: billiards,
        coords: coords,
        orientation: -orientation,
        rotationCounts: rotationCounts)
  }
  
  public func isAngleZero() -> Bool {
    return (rotationCounts[.S0] == 0 && rotationCounts[.S1] == 0)
  }
}
