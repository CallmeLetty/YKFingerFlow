// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import UIComponent
//import BMSensors

import SnapKit
import RxSwift
import RxCocoa
class FingerFlowVolumnVC: BaseViewController {
  private let rxDisposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    bindEvents()
  }

  // MARK: - lazy
  private lazy var shadowView = {
    let view = UIView()

    view.backgroundColor = .black.withAlphaComponent(0.75)
    return view
  }()

  private lazy var bgView = {
    let view = UIView()

    view.backgroundColor = UIColor(hexString: "#172240")
    view.layerCornerRadius = 15
    return view
  }()

  private lazy var titleLabel = {
    let titleLabel = UILabel()

    titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
    titleLabel.textColor = UIColor.black
    titleLabel.text = "Code.FingerflowSoundText1"
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    return titleLabel
  }()

  private lazy var contentLabel = {
    let contentLabel = UILabel()

    contentLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    contentLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    contentLabel.text = "Code.FingerflowSoundText2"
    contentLabel.textAlignment = .center
    contentLabel.numberOfLines = 0
    return contentLabel
  }()

  private lazy var sureButton = {
    let button = UIButton()

    button.setTitle("Code.CommonOk",
                         for: .normal)
    button.layerCornerRadius = 26
    button.backgroundColor = UIColor.blue
    button.setTitleColor(UIColor(hexString: "#131C41"),
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    return button
  }()
}

private extension FingerFlowVolumnVC {
  func bindEvents() {
    sureButton.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.dismissVC()
    }).disposed(by: rxDisposeBag)
  }

  func setupViews() {
    view.addSubview(shadowView)
    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    view.addSubview(bgView)

    bgView.snp.makeConstraints { make in
      make.left.right.equalToSuperview().inset(37.5)
      make.height.equalTo(201.5)
      make.centerY.equalToSuperview()
    
    }

    bgView.addSubview(titleLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(20)
    
    }

    bgView.addSubview(contentLabel)

    contentLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
    
    }

    bgView.addSubview(sureButton)

    sureButton.snp.makeConstraints { make in
      make.left.right.equalTo(contentLabel)
      make.height.equalTo(52)
      make.bottom.equalTo(-20)
    
    }
  }
}
