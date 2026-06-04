// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From BMBaseWidgetLib

import UIKit

extension UIImage {
  /// Crops using a rect in point coordinates (same space as `size`).
  func croppedImage(_ rect: CGRect) -> UIImage? {
    guard rect.width > 0, rect.height > 0, let source = cgImage else { return nil }

    let scale = self.scale
    var pixelRect = CGRect(
      x: rect.origin.x * scale,
      y: rect.origin.y * scale,
      width: rect.size.width * scale,
      height: rect.size.height * scale
    ).integral

    let bounds = CGRect(x: 0, y: 0, width: CGFloat(source.width), height: CGFloat(source.height))
    pixelRect = pixelRect.intersection(bounds)
    guard !pixelRect.isNull, pixelRect.width > 0, pixelRect.height > 0 else { return nil }

    guard let cropped = source.cropping(to: pixelRect) else { return nil }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }
}
