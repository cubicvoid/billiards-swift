import sys

def ParityStringForPath(p):
  divided = p.replace("LR", "L.R").replace("RL", "R.L")
  return "".join([str(len(s) % 2) for s in divided.split(".")])

def WindingNumberForParityString(ps):
  position = 0
  direction = 1
  for p in ps:
    if p == '1':
      position += direction

def WindingNumberForPath(p):
  high = 0
  low = 0
  position = 0
  direction = 1
  turn = p[-1]
  for t in p:
    if t == turn:
      direction = -direction
    else:
      position += direction
      turn = t
    if position > high:
      high = position
    if position < low:
      low = position
  return (position / 6, low, high)

def Mod3(n):
  return ((n % 3) + 3) % 3

def SignForTurn(t):
  if t == 'L':
    return -1
  if t == 'R':
    return 1
  print "Invalid turn"
  sys.exit(1)

def SignForIndex(n):
  if n % 2 == 0:
    return 1
  return -1

# Chooses a mostly arbitrary (for now) but consistent ordering of the path,
# so path equality can be checked via string equality.
def CanonicalFormForPath(p):
  # A list of indices into p that are turning from the base edge.
  baseEdgeIndices = []
  base = 0
  for i in range(len(p)):
    t = p[i]
    if base == 0:
      baseEdgeIndices.append(i)
    base += SignForTurn(t) * SignForIndex(i)

  # A list of equivalent rotations of the original path starting at each base
  # edge index.
  rotations = [p[i:] + p[:i] for i in baseEdgeIndices]
  rotations.sort()
  return rotations[0]


totals = {}
all_lows = {}
all_highs = {}
all_paths = {}

if len(sys.argv) < 2:
  print "Expected path file"
  sys.exit(1)

with open(sys.argv[1]) as f:
  for line in f.readlines():
    #print ParityStringForPath(line.strip())
    s = line.strip()
    if len(s) > 0:
      canonical = CanonicalFormForPath(s)
      all_paths[canonical] = True
      (w, low, high) = WindingNumberForPath(line.strip())
      totals[w] = totals.get(w, 0) + 1
      lows = all_lows.get(w, {})
      highs = all_highs.get(w, {})
      lows[low] = lows.get(low, 0) + 1
      highs[high] = highs.get(high, 0) + 1
      all_lows[w] = lows
      all_highs[w] = highs
  print str(len(all_paths)) + " distinct paths"
  print totals
  print all_lows[0]
  print all_highs[0]
