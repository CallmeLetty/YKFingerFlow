// Copyright (c) 2026, YKFingerFlow — result of one-off path construction.

import CoreGraphics
import UIKit

struct NewFingerFlowBuiltPath {
  let cgPath: CGPath
  let strokeStartFraction: CGFloat
  let arcLengthPath: NewFingerFlowArcLengthPath

  static func empty(pathOrigin: CGPoint) -> NewFingerFlowBuiltPath {
    let path = CGPath(rect: .zero, transform: nil)
    return NewFingerFlowBuiltPath(
      cgPath: path,
      strokeStartFraction: 0,
      arcLengthPath: .make(from: path, pathOrigin: pathOrigin)
    )
  }
}
