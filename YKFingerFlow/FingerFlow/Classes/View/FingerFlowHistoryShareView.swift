// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com


import SnapKit
import RxSwift
import RxCocoa
import UIKit

class FingerFlowHistoryShareView: UIView {
  private let rxDisposeBag = DisposeBag()
  private let image: UIImage
  private var shareHandler: (() -> ())?

  init(image: UIImage,
       shareHandler: (() -> ())?) {
    self.image = image
    self.shareHandler = shareHandler
    super.init(frame: .zero)

    setupViews()
    bindEvents()
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

  private lazy var imageView = {
    let imageView = UIImageView()

    imageView.image = self.image
    imageView.contentMode = .scaleToFill
    imageView.backgroundColor = .clear
    imageView.layer.cornerRadius = 15
    return imageView
  }()

  private lazy var shareBtn = {
    let button = UIButton()

    button.backgroundColor = UIColor.blue
    button.setTitle("Code.ChallengeFingerflowPicText3",
                         for: .normal)
    button.setTitleColor(UIColor(hexString: "#131C41"),
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    button.layer.cornerRadius = 29
    return button
  }()

  private(set) lazy var exitButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark"),
                for: .normal)
    button.layer.cornerRadius = 17.0
    return button
  }()
}

private extension FingerFlowHistoryShareView {
  func bindEvents() {
    exitButton.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.removeFromSuperview()
    })
    .disposed(by: rxDisposeBag)

    shareBtn.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.shareHandler?()
    })
    .disposed(by: rxDisposeBag)
  }

  func setupViews() {
    self.addSubview(shadowView)
    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    let scale = image.size.width / image.size.height
    self.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.width.equalTo(315)
      make.height.equalTo(315 / scale)
      make.center.equalToSuperview()
        }

    self.addSubview(shareBtn)

    shareBtn.snp.makeConstraints { make in
      make.width.equalTo(295)
      make.height.equalTo(58)
      make.centerX.equalToSuperview()
      make.top.equalTo(imageView.snp.bottom).offset(30)
    
    }

    self.addSubview(exitButton)

    exitButton.snp.makeConstraints { make in
      make.right.equalTo(imageView.snp.right)
      make.bottom.equalTo(imageView.snp.top).offset(-15)
      make.width.height.equalTo(34)
    
    }
  }
}
