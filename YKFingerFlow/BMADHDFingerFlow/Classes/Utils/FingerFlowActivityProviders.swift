// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMUserBusinessLib
//import BMBaseWidgetLib
import UIKit

class FingerFlowShareImageProvider: UIActivityItemProvider {
  private(set) var image: UIImage?

  init(shareImage: UIImage?) {
    self.image = shareImage

    super.init(placeholderItem: image ?? "")
  }

  override func activityViewController(_ activityViewController: UIActivityViewController,
                              itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    if activityType?.rawValue == "com.burbn.instagram.shareextension" {
      return nil
    }
    return image
  }
}

class FingerFlowShareURLProvider: UIActivityItemProvider {
  init() {
    super.init(placeholderItem: "")
  }

  override func activityViewController(_ activityViewController: UIActivityViewController,
                              itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    let urlString = FingerFloweShareUtil().urlString()
    if activityType == .postToTwitter {
      return urlString
    }
    return URL(string: urlString)
  }
}
