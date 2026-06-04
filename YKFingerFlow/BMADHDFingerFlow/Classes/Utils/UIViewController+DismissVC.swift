// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From UIComponent

import UIKit

extension UIViewController {
  /// Pops from the navigation stack when pushed; otherwise dismisses modally.
  func dismissVC(animated: Bool = true, completion: (() -> Void)? = nil) {
    if let navigationController,
       navigationController.viewControllers.count > 1,
       navigationController.viewControllers.last === self {
      navigationController.popViewController(animated: animated)
      completion?()
    } else if presentingViewController != nil {
      dismiss(animated: animated, completion: completion)
    } else {
      dismiss(animated: animated, completion: completion)
    }
  }
}
