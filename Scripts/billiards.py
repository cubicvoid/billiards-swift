import csv

class Coords2d:
  def __init__(self, x, y):
    self.x = x
    self.y = y

  def asOffsetFrom(self, coords):
    return OffsetCoords2d(self.x - coords.x, self.y - coords.y)

  def __repr__(self):
    return "Coords2d(" + str(self.x) + ", " + str(self.y) + ")"

class OffsetCoords2d:
  def __init__(self, dx, dy):
    self.dx = dx
    self.dy = dy

  def __repr__(self):
    return "OffsetCoords2d(" + str(self.dx) + ", " + str(self.dy) + ")"

  def dot(self, offset):
    return self.dx * offset.dx + self.dy * offset.dy

  # Compute the product of two offsets, treating them as complex numbers.
  def times(self, offset):
    return OffsetCoords2d(
      self.dx * offset.dx - self.dy * offset.dy,
      self.dx * offset.dy + self.dy * offset.dx)

  def __add__(self, offset):
    return OffsetCoords2d(self.dx + offset.dx, self.dy + offset.dy)

  def __radd__(self, other):
    if other == 0:
      return self
    return None

# Note that unlike the Swift equivalent of this code, BaseAngle can only
# represent the angle space of a base edge (because it stores multiples of
# 2a and 2b rather than a and b).
class BaseAngle:
  # coefficients: [ca, cb] = the integer coefficients of the angles
  #   2a and 2b.
  # reflected: boolean, represents whether the triangle's orientation
  #   is reflected from its original state.
  def __init__(self, coefficients, reflected):
    self.coefficients = [coefficients[0], coefficients[1]]
    self.reflected = reflected

  @staticmethod
  def zero():
    return BaseAngle([0, 0], False)

  def triangleEdge(self, edgeIndex):
    # Return a vector that points in the counterclockwise direction along the
    # triangle with this base angle.
    return EdgeVector(edgeIndex, self, False)

  def reflectThroughEdgeIndex(self, edgeIndex):
    sign = -1 if self.reflected else 1
    if edgeIndex == 0:
      return BaseAngle(self.coefficients, not self.reflected)
    elif edgeIndex == 1:
      return BaseAngle(
        [self.coefficients[0], self.coefficients[1] - sign], not self.reflected)
    # edgeIndex == 2
    return BaseAngle(
      [self.coefficients[0] + sign, self.coefficients[1]], not self.reflected)

  def __repr__(self):
    contentStr = str(self.coefficients[0]) + ", " + str(self.coefficients[1])
    if self.reflected:
      contentStr += ", reflected"
    return "BaseAngle(" + contentStr + ")"

# Encapsulates an edge index of the triangle, the BaseAngle of its base,
# and whether or not it is oriented clockwise relative to its
# containing triangle.
class EdgeVector:
  # edgeIndex: int (0-2)
  # baseAngle: BaseAngle
  # clockwise: bool
  def __init__(self, edgeIndex, baseAngle, clockwise):
    self.edgeIndex = edgeIndex
    self.baseAngle = baseAngle
    self.clockwise = clockwise

  def reverse(self):
    return EdgeVector(self.edgeIndex, self.baseAngle, not self.clockwise)

  def __repr__(self):
    contentStr = str(self.edgeIndex) + ", " + str(self.baseAngle)
    if self.clockwise:
      contentStr += ", clockwise"
    return "EdgeVector(" + contentStr + ")"

class BoundaryVertexPosition:
  # side: 0 for left, 1 for right
  # index: the 0-based index into the specified boundary side,
  #   starting from the base vertices of the original triangle.
  def __init__(self, side, index):
    self.side = side
    self.index = index

  @staticmethod
  def left(index):
    return BoundaryVertexPosition(0, index)

  @staticmethod
  def right(index):
    return BoundaryVertexPosition(1, index)

  def plus(self, offset):
    return BoundaryVertexPosition(self.side, self.index + offset)

  def equals(self, val):
    return self.side == val.side and self.index == val.index

  def __repr__(self):
    if self.side == 0:
      result = "LeftBoundaryVertex"
    elif self.side == 1:
      result = "RightBoundaryVertex"
    else:
      result = "UnknownBoundaryVertex"
    return "".join([result, "(", str(self.index), ")"])

class BoundaryVertex:
  # pos: BoundaryVertexPosition
  def __init__(self, pos):
    self.pos = pos
    self.incomingEdges = []
    self.outgoingEdges = []
    self.spinePosition = None

  def __repr__(self):
    return str(self.pos)

class PathEdge:
  # edgeVector: EdgeVector
  # fromVert, toVert: BoundaryVertex
  def __init__(self, edgeVector, fromVert, toVert):
    self.edgeVector = edgeVector
    self.fromVert = fromVert
    self.toVert = toVert

  def reverse(self):
    return PathEdge(self.edgeVector.reverse(), self.toVert, self.fromVert)

  def __repr__(self):
    return "".join(["PathEdge(\n  ",
        str(self.edgeVector), ",\n  ",
        str(self.fromVert), ", ", str(self.toVert), ")"])

class SpinePosition:
  # index: integer
  # offset: PathEdge
  def __init__(self, index, offset):
    self.index = index
    self.offset = offset

class Complex:
  def __init__(self, x, y):
    self.x = x
    self.y = y

  def __repr__(self):
    return "Complex(" + str(self.x) + ", " + str(self.y) + ")"

  def times(self, z):
    return Complex(self.x * z.x - self.y * z.y, self.x * z.y + self.y * z.x)

  def timesScalar(self, s):
    return Complex(self.x * s, self.y * s)

  def __mul__(self, z):
    return self.times(z)

  def squaredLength(self):
    return self.x * self.x + self.y * self.y

# Computes / caches path geometry details when the scalars are part of a field.
class PathGeometryField:
  def __init__(self, apex):
    self.apex = apex
    z0 = Complex(apex.x, apex.y)
    z1 = Complex(1 - apex.x, apex.y)
    r0 = z0.times(z0)
    r1 = z1.times(z1)
    self.rotation = [r0, r1]
    self.norms = [z0.squaredLength(), z1.squaredLength()]
    self.cachedPowers = [[Complex(1, 0)], [Complex(1, 0)]]
    self.edges = [
        Complex(1, 0), Complex(apex.x - 1, apex.y), Complex(-apex.x, -apex.y)]

  def rotationForBaseAngle(self, baseAngle):
    result = Complex(1, 0)
    for i in range(2):
      cache = self.cachedPowers[i]
      r = self.rotation[i]
      inverseNorm = Complex(1.0 / self.norms[i], 0)
      coeff = r.times(inverseNorm)
      while len(cache) <= abs(baseAngle.coefficients[i]):
        cache.append(cache[-1].times(coeff))

      rotation = cache[abs(baseAngle.coefficients[i])]
      if baseAngle.coefficients[i] < 0:
        rotation = Complex(rotation.x, -rotation.y)
      result = result.times(rotation)
    return result

  def offsetForEdgeVector(self, edgeVector):
    rotation = self.rotationForBaseAngle(edgeVector.baseAngle)
    vec = self.edges[edgeVector.edgeIndex]
    if edgeVector.baseAngle.reflected:
      vec = Complex(vec.x, -vec.y)

    vec = vec.times(rotation)
    if edgeVector.baseAngle.reflected is not edgeVector.clockwise:
      vec = Complex(-vec.x, -vec.y)
    return OffsetCoords2d(vec.x, vec.y)

class PathGeometryRing:
  def __init__(self, apex, maxAngles):
    self.apex = apex
    self.maxAngles = maxAngles
    z0 = Complex(apex.x, apex.y)
    z1 = Complex(1 - apex.x, apex.y)
    r0 = z0.times(z0)
    r1 = z1.times(z1)
    self.rotation = [r0, r1]
    self.norms = [z0.squaredLength(), z1.squaredLength()]
    self.edges = [
        Complex(1, 0), Complex(apex.x - 1, apex.y), Complex(-apex.x, -apex.y)]

    normPowers = [[Complex(1, 0)], [Complex(1, 0)]]
    for i in range(2):
      normArray = normPowers[i]
      for _ in range(maxAngles[i]):
        normArray.append(normArray[-1].timesScalar(self.norms[i]))

    rotationPowers = [[Complex(1, 0)], [Complex(1, 0)]]
    for i in range(2):
      rotArray = rotationPowers[i]
      for _ in range(maxAngles[i]):
        rotArray.append(rotArray[-1].times(self.rotation[i]))

    cachedPowers = [[], []]
    for i in range(2):
      cacheArray = cachedPowers[i]
      for n in range(maxAngles[i] + 1):
        cacheArray.append(
            rotationPowers[i][n] * normPowers[i][maxAngles[i] - n])
    self.cachedPowers = cachedPowers

  def rotationForBaseAngle(self, baseAngle):
    result = Complex(1, 0)
    for i in range(2):
      rotation = self.cachedPowers[i][abs(baseAngle.coefficients[i])]
      if baseAngle.coefficients[i] < 0:
        rotation = Complex(rotation.x, -rotation.y)
      result = result.times(rotation)
    return result

  def offsetForEdgeVector(self, edgeVector):
    rotation = self.rotationForBaseAngle(edgeVector.baseAngle)
    vec = self.edges[edgeVector.edgeIndex]
    if edgeVector.baseAngle.reflected:
      vec = Complex(vec.x, -vec.y)

    vec = vec.times(rotation)
    if edgeVector.baseAngle.reflected is not edgeVector.clockwise:
      vec = Complex(-vec.x, -vec.y)
    return OffsetCoords2d(vec.x, vec.y)


def CanonicalizeEdgePath(edgePath):
  candidates = []
  baseEdgeIndex = 0
  sign = 1
  lastTurn = edgePath[-1]
  for i in range(len(edgePath)):
    turn = edgePath[i]
    turnSign = -1 if turn == "L" else 1
    if baseEdgeIndex == 0 and sign == 1 and lastTurn == "L" and turn == "R":
      candidates.append(i)
    baseEdgeIndex = (baseEdgeIndex + turnSign * sign) % 3
    lastTurn = turn
    sign = -sign
  if len(candidates) == 0:
    print("CanonicalizeEdgePath failed: " + edgePath)
    return edgePath
  candidateStrings = [edgePath[i:] + edgePath[:i] for i in candidates]
  candidateStrings.sort()
  return candidateStrings[0]

class PathStudy:
  # Properties:
  # baseAngles : [BaseAngle] (the base angle of each triangle in the path)
  # leftVertices : [BoundaryVertex]
  # rightVertices : [BoundaryVertex]
  # leftEdges : [PathEdge]
  # rightEdges : [PathEdge]
  # internalEdges : [PathEdge]
  # baseEdges : [PathEdge]
  # maxAngles : [int, int]
  # spineEdges : [PathEdge]

  def __init__(self, path):
    self.path = path

    self.computePathMetadata()
    self.computeSpine()

  # pos: BoundaryVertexPosition
  def vertexAtPos(self, pos):
    if pos.side == 0:
      return self.leftVertices[pos.index]
    return self.rightVertices[pos.index]

  def computePathMetadata(self):
    baseAngle = BaseAngle.zero()
    baseAngles = [baseAngle]
    leftEdges = []
    rightEdges = []
    leftVertex = BoundaryVertex(BoundaryVertexPosition.left(0))
    rightVertex = BoundaryVertex(BoundaryVertexPosition.right(0))
    leftVertices = [leftVertex] # BoundaryVertex
    rightVertices = [rightVertex]
    baseEdge = PathEdge(baseAngle.triangleEdge(0), leftVertex, rightVertex)
    leftVertex.outgoingEdges.append(baseEdge)
    rightVertex.incomingEdges.append(baseEdge)
    baseEdges = [baseEdge]
    internalEdges = [ baseEdge ]
    maxAngles = [0, 0]
    sign = 1
    baseEdgeIndex = 0
    for turn in self.path:
      if turn == 'L':
        newBaseEdgeIndex = (baseEdgeIndex - sign + 3) % 3
        newBoundaryEdge = (baseEdgeIndex + sign + 3) % 3
        newRightVertex = BoundaryVertex(rightVertex.pos.plus(1))
        rightVertices.append(newRightVertex)
        pathEdge = PathEdge(
            baseAngle.triangleEdge(newBoundaryEdge),
            rightVertex, newRightVertex)
        rightEdges.append(pathEdge)
        rightVertex.outgoingEdges.append(pathEdge)
        newRightVertex.incomingEdges.append(pathEdge)
        if pathEdge.edgeVector.edgeIndex == 0:
          baseEdges.append(pathEdge)
        rightVertex = newRightVertex
      else:
        newBaseEdgeIndex = (baseEdgeIndex + sign + 3) % 3
        newBoundaryEdge = (baseEdgeIndex - sign + 3) % 3
        newLeftVertex = BoundaryVertex(leftVertex.pos.plus(1))
        leftVertices.append(newLeftVertex)
        pathEdge = PathEdge(
            baseAngle.triangleEdge(newBoundaryEdge).reverse(),
            leftVertex, newLeftVertex)
        leftEdges.append(pathEdge)
        leftVertex.outgoingEdges.append(pathEdge)
        newLeftVertex.incomingEdges.append(pathEdge)
        if pathEdge.edgeVector.edgeIndex == 0:
          baseEdges.append(pathEdge)
        leftVertex = newLeftVertex
      baseAngle = baseAngle.reflectThroughEdgeIndex(newBaseEdgeIndex)
      baseAngles.append(baseAngle)
      # By convention we point this edge from left to right, which is the
      # same as the counterclockwise orientation returned by baseAngle
      # since it's the base edge.
      internalEdge = PathEdge(
          baseAngle.triangleEdge(newBaseEdgeIndex), leftVertex, rightVertex)
      prevInternalEdge = internalEdges[len(internalEdges) - 1]
      if (internalEdge.toVert.pos.equals(prevInternalEdge.toVert.pos) or
          internalEdge.toVert.pos.equals(prevInternalEdge.fromVert.pos)):
        internalEdge = internalEdge.reverse()
      internalEdges.append(internalEdge)
      internalEdge.fromVert.outgoingEdges.append(internalEdge)
      internalEdge.toVert.incomingEdges.append(internalEdge)
      if internalEdge.edgeVector.edgeIndex == 0:
        baseEdges.append(internalEdge)
      maxAngles[0] = max(maxAngles[0], abs(baseAngle.coefficients[0]))
      maxAngles[1] = max(maxAngles[1], abs(baseAngle.coefficients[1]))
      sign = -sign
      baseEdgeIndex = newBaseEdgeIndex

    self.baseAngles = baseAngles
    self.leftVertices = leftVertices
    self.rightVertices = rightVertices
    self.leftEdges = leftEdges
    self.rightEdges = rightEdges
    self.internalEdges = internalEdges
    self.baseEdges = baseEdges
    self.maxAngles = maxAngles

  def computeSpine(self):
    baseEdges = self.baseEdges

    spineEdges = [] # PathEdge
    prevBaseEdge = baseEdges[0]
    for baseEdge in baseEdges[1:]:
      if baseEdge.fromVert.pos.equals(prevBaseEdge.toVert.pos):
        spineEdges.append(prevBaseEdge)
      prevBaseEdge = baseEdge

    if not spineEdges[-1].toVert.pos.equals(
        BoundaryVertexPosition.left(len(self.leftEdges))):
      # We want the base spine to always end at the last left boundary
      # vertex, so its total vector equals the path offset.
      spineEdges.append(prevBaseEdge)
      print("Base spine seems wrong? Remember to canonicalize your path")

    spineEdges[0].fromVert.spinePosition = SpinePosition(0, None)
    for i in range(len(spineEdges)):
      spineEdge = spineEdges[i]
      for edge in spineEdge.fromVert.outgoingEdges:
        edge.toVert.spinePosition = SpinePosition(i, edge)
      spineEdge.toVert.spinePosition = SpinePosition(i+1, None)

    # Handle outgoing of the last vertex.
    spineVertex = spineEdges[-1].toVert
    for edge in spineVertex.outgoingEdges:
      edge.toVert.spinePosition = SpinePosition(len(spineEdges), edge)

    # Check for errors.
    leftVertices = self.leftVertices
    rightVertices = self.rightVertices
    leftEdges = self.leftEdges
    rightEdges = self.rightEdges
    for i in range(len(leftEdges)):
      if leftVertices[i].spinePosition == None:
        print("Weird? left " + str(i) + " / " + str(len(leftVertices)))
    for i in range(len(rightEdges)):
      if rightVertices[i].spinePosition == None:
        print("Weird? right " + str(i) + " / " + str(len(rightVertices)))

    self.spineEdges = spineEdges

  # fromPos, toPos: BoundaryVertexPosition
  def spinePath(self, fromPos, toPos):
    path = []
    fromVert = self.vertexAtPos(fromPos)
    toVert = self.vertexAtPos(toPos)
    if fromVert.spinePosition.offset != None:
      path.append(fromVert.spinePosition.offset.reverse())
    fromIndex = fromVert.spinePosition.index
    toIndex = toVert.spinePosition.index
    minIndex = min(fromIndex, toIndex)
    maxIndex = max(fromIndex, toIndex)
    spineSlice = self.spineEdges[minIndex:maxIndex]
    if fromIndex > toIndex:
      spineSlice = [edge.reverse() for edge in reversed(spineSlice)]
    path += spineSlice
    if toVert.spinePosition.offset != None:
      path.append(toVert.spinePosition.offset)
    return path

  def constraintFunctions(self, apex):
    pg = PathGeometryRing(apex, self.maxAngles)
    spineOffsets = [
        pg.offsetForEdgeVector(edge.edgeVector) for edge in self.spineEdges]
    spineTotal = sum(spineOffsets)

    def constraint(leftIndex, rightIndex):
      path = self.spinePath(
          BoundaryVertexPosition.left(leftIndex),
          BoundaryVertexPosition.right(rightIndex))
      pathOffsets = [pg.offsetForEdgeVector(edge.edgeVector) for edge in path]
      pathTotal = sum(pathOffsets)
      pathRotated = OffsetCoords2d(-pathTotal.dy, pathTotal.dx)
      return pathRotated.dot(spineTotal)

    return constraint

  def countForm(self):
    results = []
    prevSpineEdge = self.spineEdges[0]
    for spineEdge in self.spineEdges[1:]:
      prevAngle = prevSpineEdge.edgeVector.baseAngle
      angle = spineEdge.edgeVector.baseAngle
      if prevAngle.coefficients[0] != angle.coefficients[0]:
        results.append(angle.coefficients[0] - prevAngle.coefficients[0])
      else:
        results.append(angle.coefficients[1] - prevAngle.coefficients[1])
      prevSpineEdge = spineEdge

    prevAngle = prevSpineEdge.edgeVector.baseAngle
    angle = self.spineEdges[0].edgeVector.baseAngle
    if prevAngle.coefficients[0] != angle.coefficients[0]:
      results.append(angle.coefficients[0] - prevAngle.coefficients[0])
    else:
      results.append(angle.coefficients[1] - prevAngle.coefficients[1])

    return PathCountForm(results)

def GCD(a, b):
  if b == 0:
    return abs(a)
  return GCD(b, a % b)

def ArrayGCD(arr):
  gcd = 0
  for v in arr:
    gcd = GCD(v, gcd)
    if gcd == 1:
      break
  return gcd

class PathCountForm:
  def __init__(self, counts):
    self.counts = counts

  def __repr__(self):
    return " ".join([str(c) for c in self.counts])

  def minimalAncestor(self):
    evens = self.counts[::2]
    odds = self.counts[1::2]
    evenGCD = ArrayGCD(evens)
    oddGCD = ArrayGCD(odds)

    if evenGCD == 1 and oddGCD == 1:
      return self
    newCounts = []
    for i in range(len(self.counts)):
      if i % 2 == 0:
        newCounts.append(self.counts[i] / evenGCD)
      else:
        newCounts.append(self.counts[i] / oddGCD)
    return PathCountForm(newCounts)

# /Users/fae/Programming/code/swift/BilliardSearch/Data/pathlength-24.txt

class Fan:
  def __init__(self, pathIndex, angleIndex, orientation, startsOnBaseEdge):
    self.pathIndex = pathIndex
    self.angleIndex = angleIndex
    self.orientation = orientation
    self.startsOnBaseEdge = startsOnBaseEdge
    self.length = 1

def FansForEdgePath(edgePath):
  curFan = None
  fans = []
  prevTurn = edgePath[-1]
  prevReflectingEdgeIndex = 0
  paritySign = 1
  for i, turn in enumerate(edgePath):
    turnSign = -1 if turn == "L" else 1
    reflectingEdgeIndex = (prevReflectingEdgeIndex + turnSign * paritySign) % 3
    if reflectingEdgeIndex != 0 and prevReflectingEdgeIndex != 0:
      if curFan:
        curFan.length += 1
        fans.append(curFan)
      curFan = Fan(i, reflectingEdgeIndex % 2, turnSign, True)
    elif prevTurn == turn or reflectingEdgeIndex == 0:
      if curFan:
        curFan.length += 1
    else:
      if curFan:
        curFan.length += 1
        fans.append(curFan)
      curFan = Fan(i, reflectingEdgeIndex  % 2, -turnSign, False)
      curFan.length += 1
    prevTurn = turn
    paritySign = -paritySign
    prevReflectingEdgeIndex = reflectingEdgeIndex
  if curFan:
    if len(fans) > 0:
      curFan.length += fans[0].pathIndex + 1
    fans.append(curFan)
  return fans

def PickCanonicalCountIndex(counts, indices):
  curOffset = 0
  def countForIndex(i):
    return counts[(indices[i] + curOffset) % len(counts)]
  remaining = range(len(indices))
  while len(remaining) != 1:
    if curOffset >= abs(indices[remaining[0]] - indices[remaining[1]]):
      break
    minVal = None
    for r in remaining:
      if not minVal or countForIndex(r) < minVal:
        minVal = countForIndex(r)
    remaining = [r for r in remaining if countForIndex(r) == minVal]
    curOffset += 1
  return indices[remaining[0]]

def CountsForEdgePath(edgePath):
  counts = []
  startIndices = []
  bestLength = 0
  fans = FansForEdgePath(edgePath)
  paritySign = 1
  for fan in fans:
    if (
        fan.orientation == 1 and fan.angleIndex == 0 or
        fan.orientation == -1 and fan.angleIndex == 1):
      if fan.length > bestLength:
        bestLength = fan.length
        startIndices = [len(counts)]
      elif fan.length == bestLength:
        startIndices.append(len(counts))
    offset = 0 if fan.startsOnBaseEdge else -1
    baseLength = (fan.length + offset) / 2
    counts.append(paritySign * fan.orientation * baseLength)
    paritySign = -paritySign
  cf = PathCountForm(counts)
  ancestor = cf.minimalAncestor()
  sliceIndex = PickCanonicalCountIndex(ancestor.counts, startIndices)
  return counts[sliceIndex:] + counts[:sliceIndex]


#PathStats(
#    "/Users/fae/Programming/code/swift/BilliardSearch/Data/pathlength-all.txt")
"""R.<x,y> = QQ['x', 'y']

def PathBoundaryPolynomials(path):
    apex = Coords2d(x, y)
    b = apex.asOffsetFrom(Coords2d(R(1), R(0)))
    b2 = b.times(b)
    c = Coords2d(R(0), R(0)).asOffsetFrom(apex)
    c2 = c.times(c)
    squaredEdgeLengths = [R(1), b.dot(b), c.dot(c)]

    # All rotations of the base edge are now integer powers of
    # b2/squaredEdgeLengths[1] and c2/squaredEdgeLengths[2]. To avoid having to
    # take polynomial quotients, we instead compute the maximum power of each
    # of these that will appear, then multiply all results by the edge lengths
    # to that power, so all final terms are simple polynomials.

    # To avoid having to track this during intermediate states, we actually
    # compute all the appropriate rotation powers this way, then compute any
    # particular coordinate as the sum of simple edge rotations (i.e. we no
    # longer actually "reflect" any particular coordinates). This has the side
    # benefit that every path is computed from the same basic terms (which may
    # be cached), and only the particular terms being summed differ between
    # paths.
    bpow = [R(1), b2]
    cpow = [R(1), c2]

    #curTri = ReflectedTriangle(BaseAngle.zero())

"""

#f = x * y / ibs + y
#f.factor()

"""
pathStudy = PathStudy("RLRLRL")
f = PathGeometryField(Coords2d(0.45, 0.5))
cf = pathStudy.constraintFunctions(Coords2d(0.45, 0.6))
"""
# f.offsetForEdgeVector(pathStudy.spineEdges[1].edgeVector)

# Current sketchy-looking output:
"""
R.<x,y> = QQ['x', 'y']
f = PathGeometryField(Coords2d(x, y))
f.offsetForEdgeVector(pathStudy.spineEdges[2].edgeVector)
"""
# Ok, it was just cause polynomial arithmetic doesn't reduce terms, so it was
# cross-multiplying everything even though they already had the same
# denominators.

"""
R.<x,y> = QQ['x', 'y']
f = PathGeometryRing(Coords2d(x, y), [1, 1])
f.offsetForEdgeVector(pathStudy.spineEdges[2].edgeVector)
"""

"""
# Top center triangle
# -2, -2, 2, 2
R.<x,y> = QQ['x', 'y']
pathStudy = PathStudy("RRRLRRRLLLRLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(2, 4).factor() # the extremal pair for the lower boundary
"-3*x^4 - 2*x^2*y^2 + y^4 + 6*x^3 + 2*x*y^2 - 3*x^2 + y^2"
cf(7, 1).factor() # left boundary
cf(6, 0).factor() # right boundary
"""

"""
# Left child
# -3, -2, 3, 2
pathStudy = PathStudy("RRRRRLRRRLLLLLRLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(5, 6).factor() # lower
"-2*x^5 + 2*x*y^4 + 6*x^4 + x^2*y^2 - y^4 - 6*x^3 + 2*x^2 - y^2"
cf(0, 1).factor() # left
"-x + y"
cf(8, 0).factor() # right
"-x^2 + 3*y^2 + 2*x - 1" # (...a quadratic straight line?)
# Yes, because its expression as a line includes an irrational coefficient
# (sqrt(3))
"""

"""
# Leftmost grandchild
# -4, -2, 4, 2
pathStudy = PathStudy("RRRRRRRLRRRLLLLLLLRLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(7, 8).factor() # lower
"5*x^6 - 5*x^4*y^2 - 9*x^2*y^4 + y^6 - 20*x^5 + 8*x^3*y^2 + 12*x*y^4 + 30*x^4 - 4*x^2*y^2 - 2*y^4 - 20*x^3 + 4*x*y^2 + 5*x^2 - 3*y^2"
cf(0, 1).factor() # left
"-x + y"
cf(10, 0).factor() # right
"-x^2 - 2*x*y + y^2 + 2*x + 2*y - 1"
"""

"""
pathStudy = PathStudy("RRRRRRRRRLRRRLLLLLLLLLRLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(9, 10).factor() # lower
"3*x^7 - 7*x^5*y^2 - 7*x^3*y^4 + 3*x*y^6 - 15*x^6 + 20*x^4*y^2 + 17*x^2*y^4 - 2*y^6 + 30*x^5 - 20*x^3*y^2 - 10*x*y^4 - 30*x^4 + 10*x^2*y^2 + 15*x^3 - 5*x*y^2 - 3*x^2 + 2*y^2"
cf(0, 1).factor() # left
cf(12, 0).factor() # right
"x^4 - 10*x^2*y^2 + 5*y^4 - 4*x^3 + 20*x*y^2 + 6*x^2 - 10*y^2 - 4*x + 1"
# four lines meeting at an irrational point! gosh
"""

"""
# Second center peak
# -3, -3, 3, 3
pathStudy = PathStudy("RRRRRLRRRRRLLLLLRLLLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(5, 6).factor() # lower
"5*x^6 - 5*x^4*y^2 - 9*x^2*y^4 + y^6 - 15*x^5 + 10*x^3*y^2 + 9*x*y^4 + 15*x^4 - 12*x^2*y^2 - 3*y^4 - 5*x^3 + 7*x*y^2"
cf(0, 1).factor() # left
"-x^2 + 3*y^2"
cf(10, 0).factor() # right
"-x^2 + 3*y^2 + 2*x - 1"
"""

"""
# Left child of second center peak
# -4, -3, 4, 3
pathStudy = PathStudy("RRRRRRRLRRRRRLLLLLLLRLLLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(7, 8).factor() # bottom
"3*x^7 - 7*x^5*y^2 - 7*x^3*y^4 + 3*x*y^6 - 12*x^6 + 18*x^4*y^2 + 12*x^2*y^4 - 2*y^6 + 18*x^5 - 20*x^3*y^2 - 6*x*y^4 - 12*x^4 + 14*x^2*y^2 + 2*y^4 + 3*x^3 - 5*x*y^2"
cf(0, 1).factor() # left
"-x^2 + 3*y^2"
cf(12, 0).factor() # right
"-x^2 - 2*x*y + y^2 + 2*x + 2*y - 1"
"""

"""
# Left grandchild of second center peak
# -5, -3, 5, 3
pathStudy = PathStudy("RRRRRRRRRLRRRRRLLLLLLLLLRLLLLL")
cf = pathStudy.constraintFunctions(Coords2d(x,y))
cf(9, 10).factor() # bottom
"-7*x^8 + 28*x^6*y^2 + 14*x^4*y^4 - 20*x^2*y^6 + y^8 + 35*x^7 - 95*x^5*y^2 - 39*x^3*y^4 + 27*x*y^6 - 70*x^6 + 130*x^4*y^2 + 30*x^2*y^4 - 10*y^6 + 70*x^5 - 100*x^3*y^2 - 10*x*y^4 - 35*x^4 + 50*x^2*y^2 + 5*y^4 + 7*x^3 - 13*x*y^2"
cf(0, 1).factor() # left
"-x^2 + 3*y^2"
cf(14, 0).factor() # right

"""
allPathStats = {}

class PathStats:
  def __init__(self, counts):
    self.path = PathCountForm(counts)
    self.pathStr = str(self.path)

    ancestorPath = self.path.minimalAncestor()
    if self.path != ancestorPath:
      self.ancestor = PathStats.statsForPath(ancestorPath)
    else:
      self.ancestor = None

    self.dataPoints = 0
    self.coordsList = []
    self.descendantDataPoints = 0

    flipCount = 0
    for i in range(len(counts)):
      if counts[i] * counts[(i + 1) % len(counts)] < 0:
        flipCount += 1
    self.flipCount = flipCount

  @staticmethod
  def statsForPath(path):
    pathStr = str(path)

    if pathStr not in allPathStats:
      allPathStats[pathStr] = PathStats(path.counts)
    return allPathStats[pathStr]


def PathStatsForTextFile(filename):
  with open(filename) as f:
    for line in f:
      # Because we accidentally printed a garbage trailing ')' at the end of the
      # path in many data files >_<
      pathStr = "".join([c for c in edgePath if c == 'L' or c == 'R'])
      counts = CountsForEdgePath(pathStr)
      cf = PathCountForm(counts)
      stats = PathStats.statsForPath(cf)
      stats.dataPoints += 1
      if stats.ancestor:
        stats.ancestor.descendantDataPoints += 1

      #minimalPaths[str(mf)] = 1
  paths = sorted(
      allPathStats.values(), key=lambda ps: ps.dataPoints, reverse=True)
  print("All paths (" + str(len(paths)) + "):")
  for p in paths:
    print(p.pathStr + "," + str(p.dataPoints))
  minimalPaths = [
      ps for ps in allPathStats.values() if ps.descendantDataPoints > 0]
  minimalPaths.sort(
      key=lambda ps: ps.dataPoints + ps.descendantDataPoints, reverse=True)
  print("Minimal paths (" + str(len(minimalPaths)) + "):")
  for p in minimalPaths:
    print(p.pathStr + "," + str(p.dataPoints + p.descendantDataPoints))

# Expects a CSV whose first three columns are the x,y coords of the datapoint
# and the path string that worked at those coords.
# Outputs a CSV with the same datapoints (in unspecified order) and the
# following columns:
# x coord, y coord, path in fan-length form, fan count, flip count
def PathStatsForCsvFile(filename):
  with open(filename) as f:
    reader = csv.reader(f)
    for row in reader:
      try:
        x = float(row[0])
        y = float(row[1])
      except:
        continue
      # Because we accidentally printed a garbage trailing ')' at the end of the
      # path in many data files >_<
      pathStr = "".join([c for c in row[2] if c == 'L' or c == 'R'])
      counts = CountsForEdgePath(pathStr)
      cf = PathCountForm(counts)
      stats = PathStats.statsForPath(cf)
      stats.dataPoints += 1
      stats.coordsList.append(Coords2d(x, y))
      if stats.ancestor:
        stats.ancestor.descendantDataPoints += 1
  """
      #minimalPaths[str(mf)] = 1
  paths = sorted(
      allPathStats.values(), key=lambda ps: ps.dataPoints, reverse=True)
  print("All paths (" + str(len(paths)) + "):")
  for p in paths:
    print(p.pathStr + "," + str(p.dataPoints))
  minimalPaths = [
      ps for ps in allPathStats.values() if ps.descendantDataPoints > 0]
  minimalPaths.sort(
      key=lambda ps: ps.dataPoints + ps.descendantDataPoints, reverse=True)
  print("Minimal paths (" + str(len(minimalPaths)) + "):")
  for p in minimalPaths:
    print(p.pathStr + "," + str(p.dataPoints + p.descendantDataPoints))
  """
  for k in allPathStats:
    stats = allPathStats[k]
    pathStr = str(stats.path)
    fanCountStr = str(len(stats.path.counts))
    flipCountStr = str(stats.flipCount)
    for coords in stats.coordsList:
      print str(coords.x) + "," + str(coords.y) + "," + pathStr + \
        "," + fanCountStr + "," + flipCountStr

PathStatsForCsvFile("Data/pathlength-all.csv")
