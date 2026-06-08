// Copyright (c) 2026, YKFingerFlow — seeded path generation with analytical arc length (New-only).

import UIKit

enum NewFingerFlowSubPathGenerator {
  private static let maxAttempts = 32
  private static let angleOptions: [CGFloat] = [180, 210, 240, 270, 300]
  private static let radiusOptions: [CGFloat] = [
    FrameGuide.screenWidth / 4,
    FrameGuide.screenWidth / 3,
    FrameGuide.screenWidth / 10,
    FrameGuide.screenWidth / 12,
  ]

  static func generate(
    startPath: UIBezierPath,
    startCenter: CGPoint,
    wholeLengthWithoutStart: CGFloat,
    pointSafeArea: CGRect,
    seed: UInt64
  ) -> [UIBezierPath]? {
    for attempt in 0..<maxAttempts {
      var rng = SeededRNG(seed: seed &+ UInt64(attempt))
      if let paths = attemptGenerate(
        startPath: startPath,
        startCenter: startCenter,
        wholeLengthWithoutStart: wholeLengthWithoutStart,
        pointSafeArea: pointSafeArea,
        rng: &rng
      ) {
        return paths
      }
    }
    return nil
  }

  private static func attemptGenerate(
    startPath: UIBezierPath,
    startCenter: CGPoint,
    wholeLengthWithoutStart: CGFloat,
    pointSafeArea: CGRect,
    rng: inout SeededRNG
  ) -> [UIBezierPath]? {
    var result = [UIBezierPath]()
    var tempPath = startPath
    var clockwise = true
    var previousCenter = startCenter
    var currentLength: CGFloat = 0

    while currentLength < wholeLengthWithoutStart {
      let segmentStart = tempPath.currentPoint
      var radius = radiusOptions.random(using: &rng) ?? radiusOptions[0]
      clockwise.toggle()

      var fitsSafeArea = true
      var center = previousCenter.calDestination(pastPoint: segmentStart, nextRadius: radius)
      while !pointSafeArea.rangeJudgeLegal(center: center, radius: radius) {
        fitsSafeArea = false
        radius /= 2
        center = previousCenter.calDestination(pastPoint: segmentStart, nextRadius: radius)
      }

      let remaining = wholeLengthWithoutStart - currentLength
      let fullAngle = fitsSafeArea ? (angleOptions.random(using: &rng) ?? 240) : 330
      let segmentLength = radius * fullAngle / 180 * .pi

      let angle: CGFloat
      if currentLength + segmentLength > wholeLengthWithoutStart {
        angle = max(remaining / radius * 180 / .pi, 1)
      } else {
        angle = fullAngle
      }

      let path = UIBezierPath(
        start: segmentStart,
        center: center,
        radius: radius,
        clockWise: clockwise,
        angle: angle
      )

      if path.currentPoint.x.isNaN {
        return nil
      }

      let actualLength = radius * angle / 180 * .pi
      result.append(path)
      currentLength += actualLength
      tempPath = path
      previousCenter = center

      if currentLength >= wholeLengthWithoutStart {
        break
      }
    }

    return result
  }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

private extension Array where Element == CGFloat {
  func random(using rng: inout SeededRNG) -> CGFloat? {
    guard !isEmpty else { return nil }
    let index = Int.random(in: 0..<count, using: &rng)
    return self[index]
  }
}
