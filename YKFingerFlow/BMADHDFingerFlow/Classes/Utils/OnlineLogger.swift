// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import Foundation
import os.log

final class OnlineLogger {
  private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "YKFingerFlow",
                                  category: "OnlineLogger")

  func error(_ message: String) {
    Self.log.error("\(message, privacy: .public)")
  }
}
