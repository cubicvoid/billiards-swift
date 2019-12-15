with open("stats.merged.csv") as f:
  for line in f.readlines():
    entries = line.split(',')
    print entries[2]
