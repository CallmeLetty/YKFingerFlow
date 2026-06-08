// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//

import Foundation

extension TimeInterval {
  /// 将毫秒格式化为 `mm:ss`。
  func toSecondTimeString() -> String {
    let date = Date(timeIntervalSince1970: self / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss"
    return formatter.string(from: date)
  }

  /// 将 Unix 时间戳（秒）格式化为 `yyyy/MM/dd HH:mm:ss`。
  func toDateString() -> String {
    let date = Date(timeIntervalSince1970: self)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return formatter.string(from: date)
  }
}
