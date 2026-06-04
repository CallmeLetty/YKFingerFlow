// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMBaseWidgetLib

import SnapKit
import Foundation
import UIKit

class FingerFloweBundleUtil {
  static func bundle() -> Bundle? {
    let mainBundle = Bundle(for: FingerFloweBundleUtil.self)
    guard let path = mainBundle.path(forResource: "BMADHDFingerFlow",
                                     ofType: "bundle"),
          let bundle = Bundle(path: path) else {
      return nil
    }

    return bundle
  }
}

class FingerFloweShareUtil {
  func text() -> String {
    return "Code.ChallengeFingerflowPicText2"
  }

  func image(imageUrlString: String,
             completion: ((UIImage?) -> Void)?) {
    requestImage(url: imageUrlString) { image in
      DispatchQueue.main.async {
        completion?(image)
      }
    }
  }

  static func generateImage(duration: Double,
                            rawImage: UIImage,
                            completion: ((UIImage?) -> Void)?) {
    let bgView = UIImageView(image: rawImage)

    let effect = UIBlurEffect(style: .dark)
    let effectView = UIVisualEffectView(effect: effect)
    effectView.alpha = 0.2
    effectView.isUserInteractionEnabled = false

    var rawSize = rawImage.size
    bgView.size = rawSize.geometricScale(width: 315)
    let titleLabel: UILabel = {
      let label = UILabel()
      label.textColor = UIColor.white
      label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
      label.text = "Code.ChallengeFingerflowPicText1"
      return label
    }()

    let durationLabel: UILabel = {
      let label = UILabel()
      label.textColor = UIColor.white
      label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
      label.text = TimeInterval(duration * 1000).toSecondTimeString()
      return label
    }()

    let logoImageView = UIImageView(image: UIImage(named: "sharecard_logo_img"))

    let appNameLabel: UILabel = {
      let label = UILabel()
      label.textColor = UIColor.white
      label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
      label.text = "Code.ChallengeFingerflowPicText4"
      return label
    }()

    let invitationLabel: UILabel = {
      let label = UILabel()
      label.textColor = .white.withAlphaComponent(0.6)
      label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
      label.text = "Code.ChallengeFingerflowPicText2"
      return label
    }()

    let qrImageView = UIImageView(image: UIImage(named: "sharecard_qrcode_img"))
    bgView.addSubview(effectView)
    effectView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    bgView.addSubview(titleLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(25)
    }
    bgView.addSubview(durationLabel)
    durationLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
    }
    bgView.addSubview(logoImageView)
    logoImageView.snp.makeConstraints { make in
      make.width.height.equalTo(34)
      make.left.equalTo(15)
      make.bottom.equalTo(-23)
    }
    bgView.addSubview(appNameLabel)
    appNameLabel.snp.makeConstraints { make in
      make.left.equalTo(logoImageView.snp.right).offset(6)
      make.top.equalTo(logoImageView)
    }
    bgView.addSubview(invitationLabel)
    invitationLabel.snp.makeConstraints { make in
      make.left.equalTo(appNameLabel)
      make.top.equalTo(appNameLabel.snp.bottom).offset(3)
    }
    bgView.addSubview(qrImageView)
    qrImageView.snp.makeConstraints { make in
      make.width.height.equalTo(50)
      make.right.equalTo(-15)
      make.bottom.equalTo(-15)
    }

    DispatchQueue.main.async {
      UIGraphicsBeginImageContextWithOptions(rawImage.size,
                                             false,
                                             UIScreen.main.scale)
      bgView.drawHierarchy(in: CGRect(origin: .zero, size: rawImage.size),
                           afterScreenUpdates: true)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      completion?(image)
    }
  }

  private func requestImage(url: String,
                            completion: ((UIImage?) -> ())?) {
    guard let parsedURL = URL(string: url) else {
      return
    }
    URLSession.shared.dataTask(with: parsedURL) { data, response, error in
      guard let data = data,
            data.count > 0 else {
        completion?(nil)
        return
          
                        }
      completion?(UIImage(data: data))
    }.resume()
  }

  func urlString() -> String {
    let originalString = "focus://challenge/finger_flow"
    guard let escapedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
      return ""
    }
    let prefix = "https://app.adjust.com/10tu6xa2?campaign=Focus&adgroup=FingerFlow&creative=Result&deeplink="
    let suffix = "?linkme=1"
    let urlStr = "\(prefix)\(escapedString)\(suffix)"
    return urlStr
  }
}
