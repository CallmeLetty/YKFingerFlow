//
//  FrameGuide.swift
//  UIComponent
//
//  Created by hanl001 on 2020/5/28.
//  Copyright © 2020 XiaoYu. All rights reserved.
//

import UIKit

public struct FrameGuide {

  /// 1 Pixel (0.5 pt)
  public static let onePx: CGFloat = 0.5

  /// UIScreen Size
  public static let screenSize = UIScreen.main.bounds.size

  /// UIScreen Width
  public static let screenWidth = screenSize.width

  /// UIScreen height
  public static var screenHeight = screenSize.height

  /// UIScreen Width multiply by 0.5
  public static let screenWidthHalf = FrameGuide.screenWidth * 0.5

  public static let navigationBarHeight: CGFloat = 44

  public static let navigationAndStatusBarHeight = navigationBarHeight + statusBarHeight

  /// iPhoneX Screen Height
  public static let iPhoneXScreenHeight: CGFloat = 896

  /// UI Guide Screen Height
  public static let guideScreenHeight: CGFloat = 667

  /// iPhoneX Screen Height - NavigationBar Height - StatusBar Height
  public static let iPhoneXViewHeight = iPhoneXScreenHeight - navigationAndStatusBarHeight

  /// UI Guide Screen Height - NavigationBar Height - StatusBar Height
  public static let guideViewHeight = iPhoneXScreenHeight - navigationAndStatusBarHeight

  public static var tabbarHeightWithSafeArea: CGFloat {
    return UIDevice.isIPhoneXSeries ? iPhoneXSeriesTabBottomHeight : tabbarHeight
  }

  public static var safeAreaBottomHeight: CGFloat {
    return UIDevice.isIPhoneXSeries ? 34 : 0
  }

  public static let iPhoneXSeriesTabBottomHeight: CGFloat = 83

  public static let tabbarHeight: CGFloat = 49

  public static var statusBarHeight: CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
      ?? scenes.compactMap { $0 as? UIWindowScene }.first
    if let height = windowScene?.statusBarManager?.statusBarFrame.height, height > 0 {
      return height
    }
    return UIDevice.isIPhoneXSeries ? 44 : 20
  }

  /// vc main view size
  public static let viewSize = CGSize(width: FrameGuide.screenWidth,
                                      height: FrameGuide.screenHeight -
                                      FrameGuide.statusBarHeight -
                                      FrameGuide.navigationBarHeight)

  public static let f10: CGFloat = 10
  public static let f12: CGFloat = 12
  public static let f16: CGFloat = 16
  public static let f18: CGFloat = 18
  public static let f20: CGFloat = 20
  public static let f25: CGFloat = 25
  public static let f30: CGFloat = 30
  public static let f40: CGFloat = 40
  public static let f45: CGFloat = 45
  public static let f50: CGFloat = 50
  public static let f60: CGFloat = 60
}
