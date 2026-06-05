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
      consumeQuadCurve(control: points[0], end: points[1])
      current = points[1]

    case .addCurveToPoint:
      consumeCubicCurve(control1: points[0], control2: points[1], end: points[2])
      current = points[2]

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

  private func consumeQuadCurve(control: CGPoint, end: CGPoint) {
    var previous = current
    for index in 1...curveSamples {
      let t = CGFloat(index) / CGFloat(curveSamples)
      let oneMinusT = 1 - t
      let point = CGPoint(
        x: oneMinusT * oneMinusT * current.x + 2 * oneMinusT * t * control.x + t * t * end.x,
        y: oneMinusT * oneMinusT * current.y + 2 * oneMinusT * t * control.y + t * t * end.y
      )
      consumeCurveStep(from: previous, to: point)
      previous = point
    }
    current = previous
  }

  private func consumeCubicCurve(control1: CGPoint, control2: CGPoint, end: CGPoint) {
    var previous = current
    for index in 1...curveSamples {
      let t = CGFloat(index) / CGFloat(curveSamples)
      let oneMinusT = 1 - t
      let oneMinusTSquared = oneMinusT * oneMinusT
      let tSquared = t * t
      let point = CGPoint(
        x: oneMinusTSquared * oneMinusT * current.x
          + 3 * oneMinusTSquared * t * control1.x
          + 3 * oneMinusT * tSquared * control2.x
          + tSquared * t * end.x,
        y: oneMinusTSquared * oneMinusT * current.y
          + 3 * oneMinusTSquared * t * control1.y
          + 3 * oneMinusT * tSquared * control2.y
          + tSquared * t * end.y
      )
      consumeCurveStep(from: previous, to: point)
      previous = point
    }
    current = previous
  }

  private func consumeCurveStep(from previous: CGPoint, to point: CGPoint) {
    let step = hypot(point.x - previous.x, point.y - previous.y)
    if traversed + step >= targetLength, result == nil {
      let local = step > 0 ? (targetLength - traversed) / step : 0
      result = CGPoint(
        x: previous.x + (point.x - previous.x) * local,
        y: previous.y + (point.y - previous.y) * local
      )
    }
    traversed += step
  }
}
