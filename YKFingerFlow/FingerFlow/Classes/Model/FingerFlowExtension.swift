// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import UIKit

extension UIStackView {
  func unhighlightAll() {
    for sub in arrangedSubviews {
      if let cell = sub as? FingerFlowImagePickerCell {
        cell.highlighted = false
      }

      if let cell = sub as? FingerFlowMusicPickerCell {
        cell.highlighted = false
      }
    }

  }
}

extension CALayer {
  func resetMoveAnimation() {
    removeAnimation(forKey: "Move")
    speed = 1
  }

  func pauseAnimation() {
    let pauseTime = convertTime(CACurrentMediaTime(),
                                from: nil)
    speed = 0.0
    timeOffset = pauseTime
  }

  func resumeAnimation() {
    guard speed == 0 else {
      return
    }
    let pauseTime = timeOffset
    speed = 1.0
    timeOffset = 0.0
    beginTime = 0.0
    let currentTime = convertTime(CACurrentMediaTime(),
                                  from: nil)
    beginTime = currentTime - pauseTime
  }
}

extension UIView {
  func animateAppear(fromValue: Float = 0,
                     toValue: Float = 1,
                     duration: CFTimeInterval = 0.3,
                     key: String? = nil,
                     keepResult: Bool = true) {
    alpha = keepResult ? 1 : 0
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = fromValue
    animation.toValue = toValue
    animation.duration = duration
    animation.isRemovedOnCompletion = true
    animation.fillMode = .forwards
    layer.add(animation,
              forKey: key)
  }

  func animateDisappear(fromValue: Float = 1,
                        toValue: Float = 0,
                        duration: CFTimeInterval = 0.3,
                        key: String? = nil,
                        keepResult: Bool = true) {
    alpha = keepResult ? 0 : 1
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = fromValue
    animation.toValue = toValue
    animation.duration = duration
    animation.isRemovedOnCompletion = true
    animation.fillMode = .forwards
    layer.add(animation,
              forKey: key)
  }

  func animateScaleOut(fromValue: CGFloat = 0,
                        toValue: CGFloat = 1,
                        duration: CFTimeInterval = 0.3,
                        key: String? = nil) {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = fromValue
    animation.toValue = toValue
    animation.duration = duration
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    layer.add(animation,
              forKey: key)
  }

  func animateScaleIn(fromValue: CGFloat = 1,
                      toValue: CGFloat = 0,
                      duration: CFTimeInterval = 0.3,
                      key: String? = nil) {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = fromValue
    animation.toValue = toValue
    animation.duration = duration
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    layer.add(animation,
              forKey: key)
  }
}

extension CGPoint {
    /// self为center point，计算角度
    /// - Parameters:
    ///   - p2: 两圆相交点坐标
    ///   - r2: 下一个圆的圆心
    /// - Returns: 终点（即下一个圆心位置）坐标
  func calDestination(pastPoint p2: CGPoint,
                      nextRadius r2: CGFloat) -> CGPoint {
    let p1 = self
    let prevRadius = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))

    let yOffset1 = abs(p2.y - p1.y)
    let xOffset1 = abs(p2.x - p1.x)

    if xOffset1 == 0 {
      let nextCenterY = (p2.y > p1.y) ? (p2.y + r2) : (p2.y - r2)
      return CGPoint(x: p1.x,
                     y: nextCenterY)
    }

    if yOffset1 == 0 {
      let nextCenterX = (p2.x > p1.x) ? (p2.x + r2) : (p2.x - r2)
      return CGPoint(x: nextCenterX,
                     y: p1.y)
    }

    let xOffset2 = xOffset1 * (prevRadius + r2) / prevRadius
    let yOffset2 = yOffset1 * (prevRadius + r2) / prevRadius

    let nextCenterX = (p2.x < p1.x) ? ceil(p1.x - xOffset2) : ceil(p1.x + xOffset2)
    let nextCenterY = (p2.y < p1.y) ? ceil(p1.y - yOffset2) : ceil(p1.y + yOffset2)

    let nextCenter = CGPoint(x: nextCenterX,
                             y: nextCenterY)

    return nextCenter
  }

    /// self为center point，计算角度
    /// - Parameters:
    ///   - pointInCircle: 给定圆上一点
    ///   - radius: 给定半径
    /// - Returns: 计算角度
  func calAngleInCircle(pointInCircle:CGPoint,
                        radius: CGFloat) -> Double {
    let endPoint = CGPoint(x: self.x + radius,
                           y: self.y)

    //排除特殊情况，三个点一条线
    if (pointInCircle.x == self.x && self.x == endPoint.x) ||
        (pointInCircle.y == self.x && self.x == endPoint.x) {
      return 0
    }

    let x1 = pointInCircle.x - self.x
    let y1 = pointInCircle.y - self.y

    let x2 = endPoint.x - self.x
    let y2 = endPoint.y - self.y

    let x = x1 * x2 + y1 * y2
    let y = x1 * y2 - x2 * y1

    var angle = acos(x / sqrt(x * x + y * y))
    if endPoint.x < self.x {
      angle = Double.pi * 2 - angle
    }

    if pointInCircle.y < self.y {
      angle = -angle
    }

    return angle
  }
}

extension UIBezierPath {
  public convenience init(start: CGPoint,
                          center: CGPoint,
                          radius: CGFloat,
                          clockWise: Bool,
                          angle: CGFloat) {
    let startAngle = center.calAngleInCircle(pointInCircle: start,
                                             radius: radius)
    let endOffset = angle / 180 * Double.pi
    let endAngle: CGFloat = clockWise ? (startAngle + endOffset) : (startAngle - endOffset)

    self.init(arcCenter: center,
              radius: radius,
              startAngle: startAngle,
              endAngle: endAngle,
              clockwise: clockWise)
  }

  public func subPaths(startClockWise: Bool,
                       startCenter: CGPoint,
                       wholeLengthWithoutStart: CGFloat,
                       pointSafeArea: CGRect) -> [UIBezierPath]? {
    var tempList = [UIBezierPath]()
    let kWidth = FrameGuide.screenWidth
    let kAngleList: [CGFloat] = [180, 210, 240, 270, 300]
    let kRadiusList = [kWidth / 4, kWidth / 3, kWidth / 10, kWidth / 12]

    var tempPath = self

    var tempClockWise = startClockWise
    var prevCenter = startCenter

      // 每秒15pt
    var currentLength: Double = 0

    while currentLength < wholeLengthWithoutStart {
      let nextStart = tempPath.currentPoint
      var nextRadius = kRadiusList.random()!
      tempClockWise = !tempClockWise
      var legalFlag = true
      var nextCenter = prevCenter.calDestination(pastPoint: nextStart,
                                                nextRadius: nextRadius)
        // 范围判断
      while (!pointSafeArea.rangeJudgeLegal(center: nextCenter,
                                            radius: nextRadius)) {
        legalFlag = false
        nextRadius = nextRadius / 2
        nextCenter = prevCenter.calDestination(pastPoint: nextStart,
                                               nextRadius: nextRadius)
      }

      let path = UIBezierPath(start: nextStart,
                              center: nextCenter,
                              radius: nextRadius,
                              clockWise: tempClockWise,
                              angle: legalFlag ? kAngleList.random()! : 330)
      if (__inline_isnand(path.currentPoint.x) != 0) {
        return nil
      }

      legalFlag = true
      tempPath = path
      prevCenter = nextCenter

      if (currentLength + path.cgPath.length > wholeLengthWithoutStart) {
        let leftLength = wholeLengthWithoutStart - currentLength
        let angle = (leftLength / (Double.pi * 2 * nextRadius)) * 180 / .pi
        let lastPath = UIBezierPath(start: nextStart,
                                    center: nextCenter,
                                    radius: nextRadius,
                                    clockWise: tempClockWise,
                                    angle: legalFlag ? kAngleList.random()! : 330)
        tempList.append(lastPath)
        break
      }
      currentLength += path.cgPath.length
      tempList.append(path)
    }
    return tempList
  }
}

extension CGRect {
  func rangeJudgeLegal(center: CGPoint,
                       radius: CGFloat) -> Bool {
    if (center.x - radius < minX ) ||
        (center.x + radius > maxX ) ||
        (center.y - radius < minY ) ||
        (center.y + radius > maxY ) {
      return false
    }
    return true
  }
}
