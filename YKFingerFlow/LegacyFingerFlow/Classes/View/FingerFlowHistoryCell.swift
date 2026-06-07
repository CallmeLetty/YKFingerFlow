// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import Reusable
import UIKit

import SnapKit
class FingerFlowHistoryCell: UITableViewCell, Reusable {

  override init(style: UITableViewCell.CellStyle,
                reuseIdentifier: String?) {
    super.init(style: style,
               reuseIdentifier: reuseIdentifier)

    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: lazy
  private(set) lazy var durationLabel = {
    let durationLabel = UILabel()

    durationLabel.textColor = UIColor.white
    durationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    durationLabel.numberOfLines = 1
    return durationLabel
  }()

  private(set) lazy var timeLabel = {
    let timeLabel = UILabel()

    timeLabel.textColor = UIColor.white.withAlphaComponent(0.6)
    timeLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    timeLabel.numberOfLines = 1
    return timeLabel
  }()

  private lazy var arrowImageView = {
    let imageView = UIImageView()
      let image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
      imageView.image = image?.withTintColor(UIColor.black.withAlphaComponent(0.6))
    return imageView
  }()
}

extension FingerFlowHistoryCell {
  private func setupViews() {
    selectionStyle = .none
    backgroundColor = .clear

    contentView.addSubview(durationLabel)

    durationLabel.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.left.equalTo(20)
    
    }

    contentView.addSubview(arrowImageView)

    arrowImageView.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.right.equalTo(-20)
    
    }

    contentView.addSubview(timeLabel)

    timeLabel.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.right.equalTo(arrowImageView.snp.left).offset(-6)
    
    }
  }
}
