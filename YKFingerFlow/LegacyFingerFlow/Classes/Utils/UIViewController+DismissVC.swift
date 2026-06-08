// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//

import UIKit

extension UIViewController {
  /// 若为 push 则 pop；否则模态关闭。
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
