// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//


import CoreGraphics

extension CGSize {
  /// Scales proportionally so the width matches `targetWidth`.
  func geometricScale(width targetWidth: CGFloat) -> CGSize {
    guard width > 0 else { return self }
    let scale = targetWidth / width
    return CGSize(width: targetWidth, height: height * scale)
  }
}
