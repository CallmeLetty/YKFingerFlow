// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//

import Foundation

final class AppManager {
  static let shared = AppManager()

  let userDiskCache: DiskCache?
  let globalDiskCache: DiskCache

  private init() {
    userDiskCache = DiskCache(userNamespace: "user")
    globalDiskCache = DiskCache(fileNamespace: "global")
  }
}
