//
//  UIDevice+Frame.swift
//  YKFingerFlow
//
//  Provides isIPhoneXSeries required by FrameGuide (from UIComponent/UIDeviceExt.swift).

import UIKit

extension UIDevice {
  public static var isIPhoneXSeries: Bool {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = scenes.flatMap(\.windows).first { $0.isKeyWindow }
    return (keyWindow?.safeAreaInsets.bottom ?? 0) > 0
  }
}
