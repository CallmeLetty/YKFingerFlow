// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

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

  init(duration: Double,
       bestDuration: Double,
       image: UIImage?,
       shareImage: UIImage?) {
    self.duration = duration
    self.bestDuration = bestDuration
    self.bgImage = image
    self.shareImage = shareImage
    self.ifNewRecord = (duration >= bestDuration)
  }
}

