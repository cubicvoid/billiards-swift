def Choose(n, k):
  num = 1
  den = 1
  for i in range(k):
    num *= (n - i)
    den *= (k - i)
  return num / den

# The probability of getting >= successCount successes out of trialCount trials
# if the probability of success is p.
def SuccessProbability(trialCount, successCount, p):
  probabilitySum = 0
  for i in range(successCount, trialCount+1):
# Add the probability of 
    probabilitySum += (
      Choose(trialCount, i) * (p ** i) * ((1-p) ** (trialCount-i)))
  return probabilitySum

prob = SuccessProbability(2500, 2479, 0.98)
print prob
print (1-prob)
