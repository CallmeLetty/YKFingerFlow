// Copyright (c) 2023 年, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMADHDUIKit
//import UIComponent
import RxSwift
import RxCocoa
import SnapKit
//import BMSensors

public class FingerFlowVC: BaseViewController {
  private let rxDisposeBag = DisposeBag()

  // for media extension
  var audioPlayer: AVAudioPlayer?
  var currentImage: FingerFlowBackgroundImage = .bg_pic1
  var currentMusic: FingerFlowBackgroundMusic = .bg_music_dreamstate
  var needToPlay: Bool = false

  // for game
  private(set) var duration: Double = 1 * 60 // default 1 min
  var gameState = FingerFlowState.before {
    didSet {
      guard gameState != oldValue else {
        return
      }
      _onStateUpdate()
    }
  }
  var isFinished = false

  var gameTimer: Timer?
  var pauseTimer: Timer?
  var pauseCountdownNumber = 5
  var pastDuration: TimeInterval = 0

  public init() {
    super.init(nibName: nil,
               bundle: nil)
    self.checkChosenResource()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    bindEvents()
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  public override var saName: String? {
    return "ADHD_FingerFlow训练主页"
  }

  public override func viewFirstDidAppear(_ animated: Bool) {
    super.viewFirstDidAppear(animated)

    firstEnterCheck()
    gameView.resetToBefore()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    stopTimer(.game)
    stopTimer(.pause)
  }

  // MARK: - lazy
  private(set) lazy var bgImageView = {
    let imageView = UIImageView()

    imageView.sd_setImage(with: URL(string: self.currentImage.imageUrlString))
    return imageView
  }()

  private(set) lazy var titleLabel = {
    let titleLabel = UILabel()

    titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
    titleLabel.textColor = UIColor.black
    titleLabel.text = "Code.ChallengeFingerflow"
    titleLabel.numberOfLines = 0
    return titleLabel
  }()

  private(set) lazy var guideButton = {
    let button = UIButton()

    button.setImage(Bundle.bmftCommon_IMG("tips_icon"),
                for: .normal)
    return button
  }()

  private(set) lazy var exitButton = {
    let button = UIButton()

    button.setImage(Bundle.bmftCommon_IMG("prime_close_icon"),
                for: .normal)
    button.layerCornerRadius = 17.0
    button.pressEffectEnable = true
    return button
  }()

  private(set) lazy var timePicker = FingerFlowTimePicker(defaultValue: Int(duration) / 60,
                                                     minValue: 1,
                                                     maxValue: 15,
                                                     delegate: self)

  private(set) lazy var musicIcon = {
    let imageView = UIImageView()

    imageView.image = UIImage(named: "fingerflow_music_icon",
                       in: type(of: self))
    imageView.contentMode = .center
    return imageView
  }()

  private(set) lazy var imageIcon = {
    let imageView = UIImageView()

    imageView.image = UIImage(named: "fingerflow_picture_icon",
                       in: type(of: self))
    imageView.contentMode = .center
    return imageView
  }()

  private(set) lazy var resourcePicker = {
    let view = FingerFlowResourcePicker(delegate: self)
    view.isHidden = true
    return view
  }()

  private(set) lazy var gameView = FingerFlowGameView(frame: view.bounds,
                                                      duration: self.duration,
                                                      delegate: self)
}

// MARK: - private
private extension FingerFlowVC {
  func bindEvents() {
    guideButton.rx.tap.subscribe(onNext: { [weak self] in
      let guideVC = FingerFlowGuideVC()
      guideVC.modalPresentationStyle = .overCurrentContext
      self?.presentVC(guideVC)
      }).disposed(by: rxDisposeBag)

    exitButton.rx.tap.subscribe(onNext: { [weak self] in
      self?.dismissVC()
      self?.onCompletion?(nil)
    }).disposed(by: rxDisposeBag)

    musicIcon.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] _ in
      guard let self = self else {
        return
      }
      var musicValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgMusic) ?? 2
      if musicValue == 0 {
        musicValue = 2
      }
      let music = FingerFlowBackgroundMusic(rawValue: musicValue) ?? .bg_music_dreamstate
      self.resourcePicker.openWithType(.music(selected: music))
      self.prepareAudio(music)
      self.audioPlayer?.play()
    }).disposed(by: rxDisposeBag)

    imageIcon.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] _ in
      guard let self = self else {
        return
      }
      var imageValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgImage) ?? 1
      if imageValue == 0 {
        imageValue = 1
      }
      let image = FingerFlowBackgroundImage(rawValue: imageValue) ?? .bg_pic1
      self.resourcePicker.openWithType(.image(selected: image))
    }).disposed(by: rxDisposeBag)

    // 前后台切换处理游戏状态+音频
    NotificationCenter.default.rx
      .notification(UIApplication.didEnterBackgroundNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        guard let self = self else {
          return
        }
        if self.gameState.isRunning {
          self.gameState = .pauseCountdown
        } else if self.gameState == .preparation {
          self.gameState = .before
        }

        if let audio = self.audioPlayer,
           audio.isPlaying {
          audio.pause()
          self.needToPlay = true
        }
      }).disposed(by: rxDisposeBag)

    NotificationCenter.default.rx
      .notification(UIApplication.didBecomeActiveNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        guard let self = self else {
          return
        }
        if let audio = self.audioPlayer,
           self.needToPlay {
          audio.play()
          self.needToPlay = false
        }
      }).disposed(by: rxDisposeBag)
  }
  
  func setupViews() {
    view.addSubview(bgImageView)
    bgImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    view.addSubview(titleLabel)

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(35 + FrameGuide.safeAreaBottomHeight)
      make.left.equalToSuperview().offset(20)
    
    }

    view.addSubview(gameView)

    gameView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    
    }

    view.addSubview(guideButton)

    guideButton.snp.makeConstraints { make in
      make.left.equalTo(titleLabel.snp.right).offset(6)
      make.centerY.equalTo(titleLabel)
      make.width.height.equalTo(20)
    
    }

    view.addSubview(exitButton)

    exitButton.snp.makeConstraints { make in
      make.right.equalTo(view).offset(-20)
      make.centerY.equalTo(titleLabel)
      make.width.height.equalTo(34)
    
    }

    view.addSubview(timePicker)

    timePicker.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(77)
      make.left.right.equalToSuperview()
      make.height.equalTo(91)
    
    }

    view.addSubview(musicIcon)

    musicIcon.snp.makeConstraints { make in
      make.bottom.equalTo(-44-FrameGuide.safeAreaBottomHeight)
      make.width.height.equalTo(40)
      make.left.equalTo(65)
    
    }

    view.addSubview(imageIcon)

    imageIcon.snp.makeConstraints { make in
      make.bottom.width.height.equalTo(musicIcon)
      make.right.equalTo(-65)
    
    }

    view.addSubview(resourcePicker)

    resourcePicker.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    
    }
  }

  func firstEnterCheck() {
      // first enter check
    if let userCache = AppManager.shared.userDiskCache,
       !userCache.getBool(for: KVCacheKey.fingerFlowEnteredBefore) {
      userCache.setBool(true,
                        for: KVCacheKey.fingerFlowEnteredBefore)

      let guideVC = FingerFlowGuideVC()
      guideVC.modalPresentationStyle = .overCurrentContext
      presentVC(guideVC)
    }

    // prepare audio data
    prepareAudioDataGroup()

    // volumn check
    if currentMusic != .bg_music_none {
      prepareAudio(currentMusic)
      if AVAudioSession.sharedInstance().outputVolume == 0 {
        let volumnVC = FingerFlowVolumnVC()
        volumnVC.modalPresentationStyle = .overCurrentContext
        presentVC(volumnVC)
      }
    }
  }
}

extension FingerFlowVC: FingerFlowTimePickerDelegate {
  func didValueChanged(_ value: Int) {
    duration = Double(value * 60)
    gameView.updateDuration(duration)
  }
}
