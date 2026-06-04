// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From BMBaseWidgetLib

import CoreGraphics

extension CGPath {
  /// Approximate total length by summing line segments and sampled curves.
  var length: CGFloat {
    let calculator = CGPathLengthCalculator()
    applyWithBlock { element in
      calculator.add(element: element.pointee)
    }
    return calculator.total
  }
}

private final class CGPathLengthCalculator {
  var total: CGFloat = 0
  private var currentPoint = CGPoint.zero
  private var startPoint = CGPoint.zero
  private let curveSamples = 24

  func add(element: CGPathElement) {
    let points = element.points

    switch element.type {
    case .moveToPoint:
      currentPoint = points[0]
      startPoint = currentPoint
    case .addLineToPoint:
      let end = points[0]
      total += distance(from: currentPoint, to: end)
      currentPoint = end
    case .addQuadCurveToPoint:
      let control = points[0]
      let end = points[1]
      total += quadCurveLength(from: currentPoint, control: control, to: end)
      currentPoint = end
    case .addCurveToPoint:
      let control1 = points[0]
      let control2 = points[1]
      let end = points[2]
      total += cubicCurveLength(from: currentPoint,
                                control1: control1,
                                control2: control2,
                                to: end)
      currentPoint = end
    case .closeSubpath:
      total += distance(from: currentPoint, to: startPoint)
      currentPoint = startPoint
    @unknown default:
      break
    }
  }

  private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
    hypot(end.x - start.x, end.y - start.y)
  }

  private func quadCurveLength(from start: CGPoint,
                               control: CGPoint,
                               to end: CGPoint) -> CGFloat {
    var segmentLength: CGFloat = 0
    var previous = start

    for index in 1...curveSamples {
      let t = CGFloat(index) / CGFloat(curveSamples)
      let oneMinusT = 1 - t
      let point = CGPoint(
        x: oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x,
        y: oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
      )
      segmentLength += distance(from: previous, to: point)
      previous = point
    }

    return segmentLength
  }

  private func cubicCurveLength(from start: CGPoint,
                                control1: CGPoint,
                                control2: CGPoint,
                                to end: CGPoint) -> CGFloat {
    var segmentLength: CGFloat = 0
    var previous = start

    for index in 1...curveSamples {
      let t = CGFloat(index) / CGFloat(curveSamples)
      let oneMinusT = 1 - t
      let oneMinusTSquared = oneMinusT * oneMinusT
      let tSquared = t * t
      let point = CGPoint(
        x: oneMinusTSquared * oneMinusT * start.x
          + 3 * oneMinusTSquared * t * control1.x
          + 3 * oneMinusT * tSquared * control2.x
          + tSquared * t * end.x,
        y: oneMinusTSquared * oneMinusT * start.y
          + 3 * oneMinusTSquared * t * control1.y
          + 3 * oneMinusT * tSquared * control2.y
          + tSquared * t * end.y
      )
      segmentLength += distance(from: previous, to: point)
      previous = point
    }

    return segmentLength
  }
}
