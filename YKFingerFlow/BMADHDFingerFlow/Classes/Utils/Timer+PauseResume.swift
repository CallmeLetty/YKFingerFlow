// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From BMBaseWidgetLib

import Foundation
import ObjectiveC

private var timerRemainingIntervalKey: UInt8 = 0

extension Timer {
  /// Pauses firing while keeping the timer valid. No-op if already paused or invalidated.
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

  /// Resumes firing from the remaining interval saved by `pause()`.
  func resume() {
    guard isValid, fireDate == .distantFuture else { return }

    let remaining = (objc_getAssociatedObject(self, &timerRemainingIntervalKey) as? NSNumber)?.doubleValue ?? 0
    fireDate = Date().addingTimeInterval(remaining)
    objc_setAssociatedObject(self, &timerRemainingIntervalKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
