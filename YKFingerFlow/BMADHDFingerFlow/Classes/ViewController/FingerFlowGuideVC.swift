// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import UIKit
import SnapKit
import RxSwift
import RxCocoa
//import UIComponent
//import BMADHDUIKit
//import BMADHDCommonResources

class FingerFlowGuideVC: BaseViewController {

  private let rxDisposeBag = DisposeBag()
  private var videoplayer: AVPlayer?

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    bindEvents()
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    playVideo()
  }

  // MARK: lazy
  private lazy var shadowView = {
    let view = UIView()

    view.backgroundColor = .black.withAlphaComponent(0.75)
    return view
  }()

  private lazy var bgView = {
    let view = UIView()

    view.backgroundColor = UIColor(hexString: "#161C44")
    let swipeup = UISwipeGestureRecognizer(target: self, action: #selector(panBgView))
    swipeup.direction = .down
    view.addGestureRecognizer(swipeup)
    return view
  }()

  private lazy var videoBgView = {
    let view = UIView()

    view.backgroundColor = UIColor(hexString: "#252B56")
    view.layer.cornerRadius = 15
    return view
  }()

  private lazy var promtLabel = {
    let promtLabel = UILabel()

    promtLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    promtLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    promtLabel.textAlignment = .center
    promtLabel.text = "Code.FingerflowHowtoplay"
    promtLabel.numberOfLines = 0
    return promtLabel
  }()

  private lazy var startButton = {
    let button = UIButton()

    button.backgroundColor = BMThemeManager.sharedInstance().theme.mainColor()
    button.setTitle("Code.SchulteStart",
                         for: .normal)
    button.setTitleColor(UIColor(hexString: "#131C41"),
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    button.layerCornerRadius = 29
    return button
  }()

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - private
private extension FingerFlowGuideVC {
  @objc func panBgView() {
    dismissVC()
  }

  func bindEvents() {
    startButton.rx
      .tap
      .subscribe(onNext: { [weak self] in
        if let currentItem = self?.videoplayer?.currentItem {
          NotificationCenter.default.removeObserver(currentItem)
        }
        self?.videoplayer = nil
        self?.dismissVC()
      })
      .disposed(by: rxDisposeBag)

    shadowView.rx.tapGesture().when(.recognized)
      .subscribe(onNext:{ [weak self]_ in
        if let currentItem = self?.videoplayer?.currentItem {
          NotificationCenter.default.removeObserver(currentItem)
        }
        self?.videoplayer = nil
        self?.dismissVC()
    }).disposed(by: rxDisposeBag)

      // 前后台切换处理游戏状态+音频
    NotificationCenter.default.rx
      .notification(UIApplication.didEnterBackgroundNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        self?.videoplayer?.pause()
      }).disposed(by: rxDisposeBag)

    NotificationCenter.default.rx
      .notification(UIApplication.didBecomeActiveNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        self?.videoplayer?.play()
      }).disposed(by: rxDisposeBag)
  }

  func setupViews() {
    view.addSubview(shadowView)
    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    view.addSubview(bgView)

    bgView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      let height = 645 + FrameGuide.safeAreaBottomHeight
      make.height.equalTo(height)
    
    }

    bgView.addSubview(videoBgView)

    videoBgView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(305)
      make.height.equalTo(473)
      make.top.equalToSuperview().offset(10)
    
    }

    view.addSubview(promtLabel)

    promtLabel.snp.makeConstraints { make in
      make.left.equalTo(40)
      make.right.equalTo(-40)
      make.top.equalTo(videoBgView.snp.bottom).offset(12)
    
    }

    view.addSubview(startButton)

    startButton.snp.makeConstraints { make in
      make.left.equalTo(20)
      make.right.equalTo(-20)
      make.height.equalTo(58)
      make.bottom.equalToSuperview().offset(-20-FrameGuide.safeAreaBottomHeight)
    
    }
  }

  func playVideo() {
    guard let bundle = FingerFloweBundleUtil.bundle(),
          let path = bundle.path(forResource:"fingerflow_guide",
                                 ofType:"mp4") else {
      return
    }
    let player = AVPlayer(url: URL(fileURLWithPath: path))
    player.volume = 0
    player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none;

    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = CGRect(x: 0,
                               y: 0,
                               width: videoBgView.frame.width,
                               height: videoBgView.frame.height)
    playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill


    guard (player.rate == 0) else {
      self.videoBgView.isHidden = true
      return
    }

    playerLayer.zPosition = -1
    player.rate = 0
    player.play()
    videoBgView.layer.addSublayer(playerLayer)
    self.videoplayer = player

    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem,
                                           queue: nil,
                                           using: { (_) in
      DispatchQueue.main.async { [weak self] in
        let t1 = CMTimeMake(value: 5, timescale: 100)
        self?.videoplayer?.seek(to: t1)
        self?.videoplayer?.play()
      }
    })
  }
}

