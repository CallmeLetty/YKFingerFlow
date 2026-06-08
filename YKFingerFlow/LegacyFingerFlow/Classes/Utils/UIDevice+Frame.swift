//
//  UIDevice+Frame.swift
//  YKFingerFlow

import UIKit

extension UIDevice {
  public static var isIPhoneXSeries: Bool {
    if Thread.isMainThread {
      return computeIsIPhoneXSeries()
    }
    return DispatchQueue.main.sync { computeIsIPhoneXSeries() }
  }

  /// 必须在主线程调用。
  private static func computeIsIPhoneXSeries() -> Bool {
    if let bottom = keyWindowSafeAreaBottom {
      return bottom > 0
    }
    return fallbackIsIPhoneXSeries
  }

  private static var keyWindowSafeAreaBottom: CGFloat? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard let keyWindow = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) else {
      return nil
    }
    return keyWindow.safeAreaInsets.bottom
  }

  private static var fallbackIsIPhoneXSeries: Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
    let size = UIScreen.main.bounds.size
    return max(size.width, size.height) >= 812
  }
}
