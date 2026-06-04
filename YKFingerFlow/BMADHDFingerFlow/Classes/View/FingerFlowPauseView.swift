// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import UIComponent

import SnapKit
class FingerFlowPauseView: UIView {
  var onExit: (()->Void)?
  var onContinue: (()->Void)?
  private let timeString: String

  init(timeString: String) {
    self.timeString = timeString
    super.init(frame: .zero)

    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    // MARK: - lazy
  private lazy var shadowView = {
    let view = UIView()

    view.backgroundColor = .black.withAlphaComponent(0.75)
    return view
  }()

  private lazy var cardView = {
    let view = UIView()

    view.backgroundColor = UIColor(hexString: "#172240")
    view.layerCornerRadius = 15
    return view
  }()

  private lazy var timeLabel = {
    let timeLabel = UILabel()

    timeLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
    timeLabel.text = self.timeString
    timeLabel.textColor = UIColor.black
    timeLabel.textAlignment = .center
    timeLabel.numberOfLines = 0
    return timeLabel
  }()

  private lazy var subTitleLabel = {
    let subTitleLabel = UILabel()

    subTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    subTitleLabel.textColor = UIColor.black
    subTitleLabel.text = "Code.FingerflowWarningText1"
    subTitleLabel.textAlignment = .center
    subTitleLabel.numberOfLines = 0
    return subTitleLabel
  }()

  private lazy var contentLabel = {
    let contentLabel = UILabel()

    contentLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    contentLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    contentLabel.setLineSpacing(4,
                      with: "Code.FingerflowWarningText2")
    contentLabel.textAlignment = .center
    contentLabel.numberOfLines = 0
    return contentLabel
  }()

  private(set) lazy var exitButton = {
    let button = UIButton()

    button.setTitle("Code.BottonExit",
                         for: .normal)
    button.layerCornerRadius = 25
    button.backgroundColor = UIColor(hexString: "#213358")
    button.setTitleColor(UIColor.blue,
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    return button
  }()

  private(set) lazy var continueButton = {
    let button = UIButton()

    button.setTitle("Code.ButtonContinue",
                         for: .normal)
    button.layerCornerRadius = 25
    button.backgroundColor = UIColor.blue
    button.setTitleColor(UIColor(hexString: "#131C41"),
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    return button
  }()
}

private extension FingerFlowPauseView {
  func setupViews() {
    backgroundColor = .clear

    self.addSubview(shadowView)

    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    
    }

    self.addSubview(cardView)

    cardView.snp.makeConstraints { make in
      make.centerY.centerX.equalToSuperview()
      make.width.equalTo(300)
    
    }

    cardView.addSubview(timeLabel)

    timeLabel.snp.makeConstraints { make in
      make.top.equalTo(35)
      make.centerX.equalToSuperview()
    
    }

    cardView.addSubview(subTitleLabel)

    subTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(timeLabel.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
    
    }

    cardView.addSubview(contentLabel)

    contentLabel.snp.makeConstraints { make in
      make.top.equalTo(subTitleLabel.snp.bottom).offset(15)
      make.left.right.equalToSuperview().inset(20)
    
    }

    cardView.addSubview(exitButton)

    exitButton.snp.makeConstraints { make in
      make.top.equalTo(contentLabel.snp.bottom).offset(20)
      make.left.equalTo(15)
      make.width.equalTo(130)
      make.height.equalTo(49)
    
    }

    cardView.addSubview(continueButton)

    continueButton.snp.makeConstraints { make in
      make.right.equalTo(-15)
      make.top.width.height.equalTo(exitButton)
      make.bottom.equalTo(-30)
    
    }
  }
}
