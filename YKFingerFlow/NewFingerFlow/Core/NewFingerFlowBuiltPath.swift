// Copyright (c) 2026, YKFingerFlow — 单次路径构建结果。

import CoreGraphics
import UIKit

struct NewFingerFlowBuiltPath {
  let cgPath: CGPath
  /// 线动画起点：`strokeEnd` 的弧长比例（起始 120° 弧结束处），非时间进度。
  let strokeStartFraction: CGFloat
  /// 圆点摆位查表；`point(atFraction:)` 的 fraction 为弧长比例，须由 `elapsed` 先换算为 `dotT`。
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
