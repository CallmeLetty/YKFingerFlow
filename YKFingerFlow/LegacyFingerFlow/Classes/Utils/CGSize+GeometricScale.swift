// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//


import CoreGraphics

extension CGSize {
  /// 等比缩放使宽度匹配 `targetWidth`。
  func geometricScale(width targetWidth: CGFloat) -> CGSize {
    guard width > 0 else { return self }
    let scale = targetWidth / width
    return CGSize(width: targetWidth, height: height * scale)
  }
}
