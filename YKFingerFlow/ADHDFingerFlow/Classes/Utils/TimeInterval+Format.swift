// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//

import Foundation

extension TimeInterval {
  /// Formats milliseconds as `mm:ss`.
  func toSecondTimeString() -> String {
    let date = Date(timeIntervalSince1970: self / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss"
    return formatter.string(from: date)
  }

  /// Formats unix timestamp (seconds) as `yyyy/MM/dd HH:mm:ss`.
  func toDateString() -> String {
    let date = Date(timeIntervalSince1970: self)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return formatter.string(from: date)
  }
}
