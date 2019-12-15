#if os(Linux)

import Clibbsd

public typealias CFTimeInterval = Double

func arc4random_uniform(_ upper_bound: UInt32) -> UInt32 {
  return Clibbsd.arc4random_uniform(upper_bound)
}

func arc4random() -> UInt32 {
  return Clibbsd.arc4random()
}

#endif
