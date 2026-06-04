// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import SnapKit
import UIKit

public class FingerFlowEntranceCardView: UIView {
  convenience init() {
    self.init(frame: .zero)

    setupViews()
  }

  public func updateBestDuration(_ durationString: String) {
    bestLabel.isHidden = false
    bestLabel.text = "\("Code.SchulteBest2")\(durationString)"

    bestLabel.sizeToFit()
    let width = bestLabel.bounds.width
    bestLabel.snp.updateConstraints { make in
      make.width.equalTo(width + 7 * 2)
    }
  }

  // MARK: - lazy
  private lazy var mainImageView = UIImageView(image: UIImage(named: "fingerflow_img"))

  private lazy var bestLabel = {
    let bestLabel = UILabel()

    bestLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
      bestLabel.textColor = UIColor.white
    bestLabel.backgroundColor = UIColor(hexString: "#FEE0BF")
    bestLabel.layer.cornerRadius = 12
    bestLabel.textAlignment = .center
    bestLabel.isHidden = true
    return bestLabel
  }()

  private lazy var label = {
    let label = UILabel()

    label.text = "Code.ChallengeFingerflowIntro"
    label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    label.textColor = UIColor.white
    return label
  }()

  private lazy var arrowImageView = UIImageView(image: UIImage(systemName: "arrow.right"))
}

private extension FingerFlowEntranceCardView {
  func setupViews() {
    backgroundColor = UIColor(hexString: "#213358")
      layer.cornerRadius = 12

    self.addSubview(mainImageView)

    mainImageView.snp.makeConstraints { make in
      make.left.right.top.equalToSuperview()
      make.bottom.equalToSuperview().offset(-60)
    
    }

    self.addSubview(bestLabel)

    bestLabel.snp.makeConstraints { make in
      make.left.top.equalTo(mainImageView).offset(10)
      make.width.equalTo(96.5)
      make.height.equalTo(24)
    
    }

    self.addSubview(label)

    label.snp.makeConstraints { make in
      make.left.equalTo(15)
      make.bottom.equalTo(-20)
    
    }

    self.addSubview(arrowImageView)

    arrowImageView.snp.makeConstraints { make in
      make.right.equalTo(-15)
      make.bottom.equalTo(-16)
      make.width.height.equalTo(28)
    
    }
  }
}
