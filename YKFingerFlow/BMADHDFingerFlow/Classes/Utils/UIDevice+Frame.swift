//
//  UIDevice+Frame.swift
//  YKFingerFlow
//
//  Provides isIPhoneXSeries required by FrameGuide (from UIComponent/UIDeviceExt.swift).

import UIKit

extension UIDevice {
  public static var isIPhoneXSeries: Bool {
    if Thread.isMainThread {
      return computeIsIPhoneXSeries()
    }
    return DispatchQueue.main.sync { computeIsIPhoneXSeries() }
  }

  /// Must run on the main thread.
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
