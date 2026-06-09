// Copyright (c) 2026, YKFingerFlow — 带种子生成器与预计算弧长表的路径构建。

import UIKit

struct NewFingerFlowPathLayout {
  let startPath: UIBezierPath
  let startPoint: CGPoint
  let startCenter: CGPoint
  let startRadius: CGFloat
  let drawArea: CGRect
  let dotRadius: CGFloat = 50
  let speedPerSecond: Double = 15

  static func make() -> NewFingerFlowPathLayout {
    let startPoint = CGPoint(
      x: 80,
      y: UIDevice.isIPhoneXSeries ? 628 : 517
    )
    let startRadius = 80 * 3 / 2 / Double.pi
    let startCenter = CGPoint(x: startPoint.x + startRadius, y: startPoint.y)
    let startPath = UIBezierPath(
      start: startPoint,
      center: startCenter,
      radius: startRadius,
      clockWise: true,
      angle: 120
    )
    let drawArea = CGRect(
      x: 0,
      y: UIDevice.isIPhoneXSeries ? 174 : 164,
      width: FrameGuide.screenWidth,
      height: UIDevice.isIPhoneXSeries ? 574 : 473
    )
    return NewFingerFlowPathLayout(
      startPath: startPath,
      startPoint: startPoint,
      startCenter: startCenter,
      startRadius: startRadius,
      drawArea: drawArea
    )
  }

  func buildProgressPath(duration: TimeInterval, seed: UInt64) -> NewFingerFlowBuiltPath {
    let lengthNeeded = CGFloat(duration * speedPerSecond)
    let safe = CGRect(
      x: drawArea.minX + dotRadius,
      y: drawArea.minY + dotRadius,
      width: drawArea.width - dotRadius * 2,
      height: drawArea.height - dotRadius * 2
    )

    let leftPaths: [UIBezierPath]
    if let generated = NewFingerFlowSubPathGenerator.generate(
      startPath: startPath,
      startCenter: startCenter,
      wholeLengthWithoutStart: lengthNeeded,
      pointSafeArea: safe,
      seed: seed
    ) {
      leftPaths = generated
    } else if let fallback = legacySubPaths(lengthNeeded: lengthNeeded, safe: safe) {
      leftPaths = fallback
    } else {
      return .empty(pathOrigin: startPoint)
    }

    let combined = UIBezierPath()
    combined.append(startPath)
    leftPaths.forEach { combined.append($0) }

    let cgPath = combined.cgPath
    // 构建期一次性建立「弧长 → 坐标」映射，运行时只用 fraction 查表，避免每帧按贝塞尔 t 采样导致速度不均
    let arcLengthPath = NewFingerFlowArcLengthPath.make(from: cgPath, pathOrigin: startPoint)
    let startArcLength = startRadius * 120 / 180 * .pi
    let total = arcLengthPath.totalLength
    // strokeStart 也是弧长比例：起始弧占整条路径的实际长度比（非时间、非贝塞尔 t）
    let strokeStart = total > 0 ? startArcLength / total : 0

    return NewFingerFlowBuiltPath(
      cgPath: cgPath,
      strokeStartFraction: strokeStart,
      arcLengthPath: arcLengthPath
    )
  }

  private func legacySubPaths(lengthNeeded: CGFloat, safe: CGRect) -> [UIBezierPath]? {
    for _ in 0..<32 {
      if let paths = startPath.subPaths(
        startClockWise: true,
        startCenter: startCenter,
        wholeLengthWithoutStart: lengthNeeded,
        pointSafeArea: safe
      ) {
        return paths
      }
    }
    return nil
  }
}
