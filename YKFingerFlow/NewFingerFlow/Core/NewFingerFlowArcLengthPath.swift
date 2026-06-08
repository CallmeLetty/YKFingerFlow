// Copyright (c) 2026, YKFingerFlow — 预计算弧长表，运行时 O(log n) 采样。

import CoreGraphics
import UIKit

/// 每局路径构建一次；`applyPlayback` 查表而非每帧重走 `CGPath`。
struct NewFingerFlowArcLengthPath {
  let pathOrigin: CGPoint
  let totalLength: CGFloat
  private let knots: [(arcLength: CGFloat, point: CGPoint)]

  static func make(
    from path: CGPath,
    pathOrigin: CGPoint,
    curveSamples: Int = 24
  ) -> NewFingerFlowArcLengthPath {
    var builder = KnotBuilder(curveSamples: curveSamples)
    path.applyWithBlock { element in
      builder.add(element: element.pointee)
    }
    var knots = builder.knots
    if knots.isEmpty {
      knots = [(0, pathOrigin)]
    } else if hypot(knots[0].point.x - pathOrigin.x, knots[0].point.y - pathOrigin.y) > 1 {
      knots[0] = (0, pathOrigin)
    }
    return NewFingerFlowArcLengthPath(
      pathOrigin: pathOrigin,
      totalLength: builder.total,
      knots: knots
    )
  }

  func point(atFraction fraction: CGFloat) -> CGPoint {
    var hint = 0
    return point(atFraction: fraction, hintIndex: &hint)
  }

  /// 单调播放时传入持久 `hintIndex`，近似 O(1) 查找。
  func point(atFraction fraction: CGFloat, hintIndex: inout Int) -> CGPoint {
    let clamped = min(max(fraction, 0), 1)
    guard totalLength > 0, let first = knots.first else { return pathOrigin }
    if clamped <= 0 { return pathOrigin }
    if clamped >= 1 { return knots.last?.point ?? pathOrigin }

    let target = totalLength * clamped
    if target <= first.arcLength { return pathOrigin }

    hintIndex = min(max(hintIndex, 0), knots.count - 1)
    while hintIndex < knots.count - 1, knots[hintIndex + 1].arcLength < target {
      hintIndex += 1
    }
    while hintIndex > 0, knots[hintIndex].arcLength > target {
      hintIndex -= 1
    }

    let upperIndex = min(hintIndex + 1, knots.count - 1)
    let lower = knots[hintIndex]
    let upper = knots[upperIndex]
    let span = upper.arcLength - lower.arcLength
    let local = span > 0 ? (target - lower.arcLength) / span : 0
    return CGPoint(
      x: lower.point.x + (upper.point.x - lower.point.x) * local,
      y: lower.point.y + (upper.point.y - lower.point.y) * local
    )
  }
}

// MARK: - 单次遍历收集结点

private struct KnotBuilder {
  private(set) var total: CGFloat = 0
  private(set) var knots: [(arcLength: CGFloat, point: CGPoint)] = []
  private var current = CGPoint.zero
  private var start = CGPoint.zero
  private let curveSamples: Int

  init(curveSamples: Int) {
    self.curveSamples = curveSamples
  }

  mutating func add(element: CGPathElement) {
    let points = element.points

    switch element.type {
    case .moveToPoint:
      current = points[0]
      start = current
      if knots.isEmpty {
        knots.append((0, current))
      } else {
        knots[0] = (0, current)
      }

    case .addLineToPoint:
      let end = points[0]
      appendSegment(from: current, to: end)
      current = end

    case .addQuadCurveToPoint:
      appendQuadCurve(control: points[0], end: points[1])
      current = points[1]

    case .addCurveToPoint:
      appendCubicCurve(control1: points[0], control2: points[1], end: points[2])
      current = points[2]

    case .closeSubpath:
      appendSegment(from: current, to: start)
      current = start

    @unknown default:
      break
    }
  }

  private mutating func appendSegment(from startPoint: CGPoint, to end: CGPoint) {
    let segment = hypot(end.x - startPoint.x, end.y - startPoint.y)
    appendKnot(length: segment, endPoint: end)
  }

  private mutating func appendQuadCurve(control: CGPoint, end: CGPoint) {
    var previous = current
    for index in 1...curveSamples {
      let t = CGFloat(index) / CGFloat(curveSamples)
      let oneMinusT = 1 - t
      let point = CGPoint(
        x: oneMinusT * oneMinusT * current.x + 2 * oneMinusT * t * control.x + t * t * end.x,
        y: oneMinusT * oneMinusT * current.y + 2 * oneMinusT * t * control.y + t * t * end.y
      )
      let step = hypot(point.x - previous.x, point.y - previous.y)
      appendKnot(length: step, endPoint: point)
      previous = point
    }
    current = previous
  }

  private mutating func appendCubicCurve(control1: CGPoint, control2: CGPoint, end: CGPoint) {
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
      let step = hypot(point.x - previous.x, point.y - previous.y)
      appendKnot(length: step, endPoint: point)
      previous = point
    }
    current = previous
  }

  private mutating func appendKnot(length: CGFloat, endPoint: CGPoint) {
    guard length > 0 else {
      record(endPoint)
      return
    }
    total += length
    record(endPoint)
  }

  private mutating func record(_ point: CGPoint) {
    knots.append((total, point))
  }
}
