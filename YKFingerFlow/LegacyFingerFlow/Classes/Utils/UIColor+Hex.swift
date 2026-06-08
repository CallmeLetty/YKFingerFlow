//
//  UIColor+Hex.swift
//  YKFingerFlow

import UIKit

extension UIColor {
  convenience init?(hexString: String, alpha: CGFloat = 1.0) {
    var formatted = hexString.replacingOccurrences(of: "0x", with: "")
    formatted = formatted.replacingOccurrences(of: "#", with: "")
    guard let hex = Int(formatted, radix: 16) else {
      return nil
    }

    let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(hex & 0x0000FF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
