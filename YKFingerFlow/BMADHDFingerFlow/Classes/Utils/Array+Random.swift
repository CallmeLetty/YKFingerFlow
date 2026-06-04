// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From BMBaseWidgetLib

import Foundation

extension Array {
  /// Returns a random element, or `nil` if the array is empty.
  func random() -> Element? {
    guard !isEmpty else { return nil }
    return self[Int.random(in: 0..<count)]
  }
}
