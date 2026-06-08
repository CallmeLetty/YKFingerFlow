// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//


import Foundation
import ObjectiveC

private var timerRemainingIntervalKey: UInt8 = 0

extension Timer {
  /// 暂停触发但保持 Timer 有效；已暂停或已失效时不操作。
  func pause() {
    guard isValid, fireDate != .distantFuture else { return }

    let remaining = max(0, fireDate.timeIntervalSinceNow)
    objc_setAssociatedObject(
      self,
      &timerRemainingIntervalKey,
      NSNumber(value: remaining),
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    fireDate = .distantFuture
  }

  /// 从 `pause()` 保存的剩余间隔恢复触发。
  func resume() {
    guard isValid, fireDate == .distantFuture else { return }

    let remaining = (objc_getAssociatedObject(self, &timerRemainingIntervalKey) as? NSNumber)?.doubleValue ?? 0
    fireDate = Date().addingTimeInterval(remaining)
    objc_setAssociatedObject(self, &timerRemainingIntervalKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
