// Copyright (c) 2023, Bongmi — reuses legacy `UIBezierPath.subPaths` from FingerFlowExtension.swift.

import UIKit

struct NewFingerFlowPathLayout {
  let startPath: UIBezierPath
  let startPoint: CGPoint
  let startCenter: CGPoint
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
      drawArea: drawArea
    )
  }

  func buildProgressPath(duration: TimeInterval) -> (path: CGPath, strokeStartFraction: CGFloat) {
    let lengthNeeded = duration * speedPerSecond
    let safe = CGRect(
      x: drawArea.minX + dotRadius,
      y: drawArea.minY + dotRadius,
      width: drawArea.width - dotRadius * 2,
      height: drawArea.height - dotRadius * 2
    )

    var segments = [startPath]
    var leftPaths: [UIBezierPath]?
    repeat {
      leftPaths = startPath.subPaths(
        startClockWise: true,
        startCenter: startCenter,
        wholeLengthWithoutStart: lengthNeeded,
        pointSafeArea: safe
      )
    } while leftPaths == nil

    segments.append(contentsOf: leftPaths!)
    let combined = UIBezierPath()
    segments.forEach { combined.append($0) }

    let total = combined.cgPath.length
    let strokeStart = total > 0 ? startPath.cgPath.length / total : 0
    return (combined.cgPath, strokeStart)
  }
}
