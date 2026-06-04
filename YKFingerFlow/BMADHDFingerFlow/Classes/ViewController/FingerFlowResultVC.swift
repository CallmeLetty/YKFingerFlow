// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMADHDCommonResources
//import UIComponent
//import BMADHDUIKit
//import BMADHDStreak
//import BMSensors
import SnapKit
import RxSwift
import RxCocoa
import Lottie
import UIKit

class FingerFlowResultVC: UIViewController {
  let model: FingerFlowResultVM
    let rxDisposeBag = DisposeBag()

  init(result: FingerFlowResultVM) {
    self.model = result

    super.init(nibName: nil,
               bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    bindEvents()
    setupViews()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    buttonAnimationView.play()
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: lazy
    private lazy var bgImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.image = self.model.bgImage
    let effect = UIBlurEffect(style: .dark)
    let effectView = UIVisualEffectView(effect: effect)
    effectView.alpha = 0.5
    effectView.isUserInteractionEnabled = false
    imageV.addSubview(effectView)
    effectView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }
        return imageV
  }()

  private lazy var timeLabel = {
    let timeLabel = UILabel()

    timeLabel.textColor = UIColor.black
      timeLabel.font = .systemFont(ofSize: 34, weight: .bold)
    timeLabel.numberOfLines = 0
    timeLabel.text = self.model.duration.toSecondTimeString()
    return timeLabel
  }()

  private lazy var bestBgImageView = UIImageView(image: UIImage(named: "result_besttime_img"))

  private lazy var bestLabel = {
    let bestLabel = UILabel()

    bestLabel.textColor = UIColor.black
    bestLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    bestLabel.numberOfLines = 0
    let best = model.bestDuration.toSecondTimeString()
    bestLabel.text = "最棒\(best)"
    return bestLabel
  }()

    private lazy var shareButton = {
        let button = UIButton()
        
        button.backgroundColor = .blue
        button.setTitle("分享",for: .normal)
        button.setTitleColor(.white,
                             for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 29
        return button
  }()

  private lazy var exitButton = {
    let button = UIButton()

      button.setImage(.init(systemName: "close"), for: .normal)
    button.layerCornerRadius = 17.0
    button.pressEffectEnable = true
    return button
  }()

  private lazy var buttonAnimationView: LottieAnimationView = {
    let animationView = LottieAnimationView(name: "share_button_js",
                                         bundle: FingerFloweBundleUtil.bundle()!)
    animationView.loopAnimation = true
    animationView.isUserInteractionEnabled = false
    return animationView
  }()
}

// MARK: - private
private extension FingerFlowResultVC {
  func share() {
    UINavigationBar.appearance().isTranslucent = false
      UINavigationBar.appearance().barTintColor = .blue

    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }

      let textItem = FingerFloweShareUtil().text()
      let imageItem = FingerFlowShareImageProvider(shareImage: self.model.shareImage)
      let urlItem = FingerFlowShareURLProvider()
      let vc = UIActivityViewController(activityItems: [textItem, imageItem, urlItem],
                                        applicationActivities: nil)

      self.view.hud.hideLoading()
      vc.popoverPresentationController?.sourceRect = CGRect(x: FrameGuide.screenWidth / 2,
                                                            y: FrameGuide.screenHeight - 70,
                                                            width: 1,
                                                            height: 1)
      vc.popoverPresentationController?.sourceView = self.view
      vc.popoverPresentationController?.permittedArrowDirections = .down
      self.presentVC(vc)
    }
  }

  func bindEvents() {
    exitButton.rx.tap.subscribe(onNext: { [weak self] _ in
        self?.navigationController?.popViewController(animated: true)
    }).disposed(by: rxDisposeBag)

    shareButton.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.share()
    }).disposed(by: rxDisposeBag)
  }

  func setupViews() {
    // views
    view.backgroundColor = .clear

    // layout
    view.addSubview(bgImageView)
    bgImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    view.addSubview(exitButton)

    exitButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-20)
      make.top.equalTo(35 + FrameGuide.safeAreaBottomHeight)
      make.width.height.equalTo(34)
    
    }

    view.addSubview(timeLabel)

    timeLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(exitButton.snp.bottom).offset(215)
    
    }

    view.addSubview(bestBgImageView)

    bestBgImageView.snp.makeConstraints { make in
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(58)
      make.top.equalTo(timeLabel.snp.bottom).offset(29.5)
    
    }

    view.addSubview(bestLabel)

    bestLabel.snp.makeConstraints { make in
      make.centerX.centerY.equalTo(bestBgImageView)
    
    }

    view.addSubview(shareButton)

    shareButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(335)
      make.height.equalTo(58)
      make.bottom.equalToSuperview().offset(-25.5-FrameGuide.safeAreaBottomHeight)
    
    }

    shareButton.addSubview(buttonAnimationView)

    buttonAnimationView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalToSuperview()
    
    }

    buttonAnimationToScale()
  }

  func buttonAnimationToScale() {
    UIView.animate(withDuration: 1,
                   delay: 0,
                   options: [.layoutSubviews, .allowUserInteraction]) { [weak self] in
      guard let self = self else {
        return
      }
      self.shareButton.transform = CGAffineTransform(scaleX: 0.9,
                                                     y: 0.9)
    } completion: { [weak self] complete in
      self?.buttonAnimationToNormal()
    }
  }

  func buttonAnimationToNormal() {
    UIView.animate(withDuration: 1,
                   delay: 0,
                   options: [.layoutSubviews, .allowUserInteraction]) { [weak self] in
      guard let self = self else {
        return
      }
      self.shareButton.transform = CGAffineTransform(scaleX: 1.0,
                                                     y: 1.0)
    } completion: { [weak self] complete in
      self?.buttonAnimationToScale()
    }
  }
}

