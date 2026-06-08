// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//

import Foundation

extension Array {
  /// 返回随机元素；数组为空时返回 `nil`。
  func random() -> Element? {
    guard !isEmpty else { return nil }
    return self[Int.random(in: 0..<count)]
  }
}
