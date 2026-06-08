// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import UIKit
import Foundation

public struct FingerFlowHistoryVM {
  var best: FingerFlowSingleHistoryVM
  var list: [FingerFlowSingleHistoryVM]
}

public struct FingerFlowSingleHistoryVM {
  var duration: Double
  var createTime: NSNumber
  var imageUrl: String?
}

public struct FingerFlowResultVM {
  var duration: Double
  var bestDuration: Double
  var bgImage: UIImage?
  var shareImage: UIImage?
  var ifNewRecord: Bool
  /// NewFingerFlow 本局路径 seed；仅 Debug 结果页展示，Legacy 为 nil
  var pathSeed: UInt64?

  init(duration: Double,
       bestDuration: Double,
       image: UIImage?,
       shareImage: UIImage?,
       pathSeed: UInt64? = nil) {
    self.duration = duration
    self.bestDuration = bestDuration
    self.bgImage = image
    self.shareImage = shareImage
    self.ifNewRecord = (duration >= bestDuration)
    self.pathSeed = pathSeed
  }
}

