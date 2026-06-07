// Copyright (c) 2026, YKFingerFlow — pause UI (standalone; does not modify FingerFlowPauseView).

import SnapKit
import UIKit

final class NewFingerFlowPauseOverlay: UIView {

  var onExit: (() -> Void)?
  var onContinue: (() -> Void)?

  private let timeString: String

  init(timeString: String) {
    self.timeString = timeString
    super.init(frame: .zero)
    setupViews()
    exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var shadowView: UIView = {
    let view = UIView()
    view.backgroundColor = .black.withAlphaComponent(0.75)
    return view
  }()

  private lazy var cardView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hexString: "#172240")
    view.layer.cornerRadius = 15
    return view
  }()

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 24, weight: .semibold)
    label.text = timeString
    label.textColor = .white
    label.textAlignment = .center
    return label
  }()

  private lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 18, weight: .medium)
    label.textColor = .white
    label.text = "太棒了！"
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }()

  private lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.textColor = UIColor.white.withAlphaComponent(0.8)
    label.text = "FingerFlow有助于提高专注力和工作效率！"
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }()

  private(set) lazy var exitButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("结束", for: .normal)
    button.layer.cornerRadius = 25
    button.backgroundColor = UIColor(hexString: "#213358")
    button.setTitleColor(.systemBlue, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    return button
  }()

  private(set) lazy var continueButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("继续", for: .normal)
    button.layer.cornerRadius = 25
    button.backgroundColor = .systemBlue
    button.setTitleColor(UIColor(hexString: "#131C41"), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    return button
  }()

  @objc private func exitTapped() { onExit?() }
  @objc private func continueTapped() { onContinue?() }
}

private extension NewFingerFlowPauseOverlay {
  func setupViews() {
    addSubview(shadowView)
    shadowView.snp.makeConstraints { $0.edges.equalToSuperview() }

    addSubview(cardView)
    cardView.snp.makeConstraints { make in
      make.center.equalToSuperview()
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
