// Copyright (c) 2026, YKFingerFlow — path sampling for master-clock driven dot position.

import CoreGraphics
import UIKit

extension CGPath {

  /// Point at normalized arc length `fraction` in 0...1 along the path.
  func point(atFraction fraction: CGFloat) -> CGPoint {
    let clamped = min(max(fraction, 0), 1)
    let target = length * clamped
    let sampler = CGPathPointSampler(targetLength: target)
    applyWithBlock { element in
      sampler.add(element: element.pointee)
    }
    return sampler.result ?? .zero
  }
}

private final class CGPathPointSampler {
  private let targetLength: CGFloat
  private var traversed: CGFloat = 0
  private(set) var result: CGPoint?
  private var current = CGPoint.zero
  private var start = CGPoint.zero
  private let curveSamples = 24

  init(targetLength: CGFloat) {
    self.targetLength = targetLength
  }

  func add(element: CGPathElement) {
    guard result == nil else { return }
    let points = element.points

    switch element.type {
    case .moveToPoint:
      current = points[0]
      start = current
      if targetLength == 0 { result = current }

    case .addLineToPoint:
      let end = points[0]
      consumeSegment(from: current, to: end) { t in
        CGPoint(
          x: current.x + (end.x - current.x) * t,
          y: current.y + (end.y - current.y) * t
        )
      }
      current = end

    case .addQuadCurveToPoint:
      let control = points[0]
      let end = points[1]
      consumeCurve(samples: curveSamples) { t in
        let omt = 1 - t
        return CGPoint(
          x: omt * omt * current.x + 2 * omt * t * control.x + t * t * end.x,
          y: omt * omt * current.y + 2 * omt * t * control.y + t * t * end.y
        )
      }
      current = end

    case .addCurveToPoint:
      let c1 = points[0]
      let c2 = points[1]
      let end = points[2]
      consumeCurve(samples: curveSamples) { t in
        let omt = 1 - t
        let omt2 = omt * omt
        let t2 = t * t
        return CGPoint(
          x: omt2 * omt * current.x + 3 * omt2 * t * c1.x + 3 * omt * t2 * c2.x + t2 * t * end.x,
          y: omt2 * omt * current.y + 3 * omt2 * t * c1.y + 3 * omt * t2 * c2.y + t2 * t * end.y
        )
      }
      current = end

    case .closeSubpath:
      consumeSegment(from: current, to: start) { t in
        CGPoint(
          x: current.x + (start.x - current.x) * t,
          y: current.y + (start.y - current.y) * t
        )
      }
      current = start

    @unknown default:
      break
    }
  }

  private func consumeSegment(
    from startPoint: CGPoint,
    to end: CGPoint,
    interpolate: (CGFloat) -> CGPoint
  ) {
    let segment = hypot(end.x - startPoint.x, end.y - startPoint.y)
    if traversed + segment >= targetLength, result == nil {
      let local = segment > 0 ? (targetLength - traversed) / segment : 0
      result = interpolate(local)
    }
    traversed += segment
  }

  private func consumeCurve(samples: Int, pointAt: (CGFloat) -> CGPoint) {
    var previous = current
    for index in 1...samples {
      let t = CGFloat(index) / CGFloat(samples)
      let point = pointAt(t)
      let step = hypot(point.x - previous.x, point.y - previous.y)
      if traversed + step >= targetLength, result == nil {
        let local = step > 0 ? (targetLength - traversed) / step : 0
        let prevT = CGFloat(index - 1) / CGFloat(samples)
        result = CGPoint(
          x: previous.x + (point.x - previous.x) * local,
          y: previous.y + (point.y - previous.y) * local
        )
        _ = prevT
      }
      traversed += step
      previous = point
    }
    current = previous
  }
}
