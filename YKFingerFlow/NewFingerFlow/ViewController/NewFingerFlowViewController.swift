// Copyright (c) 2026, YKFingerFlow — 协调 Reducer、主时钟与游戏视图。

import AVFAudio
import AudioToolbox
import RxCocoa
import RxSwift
import SDWebImage
import SnapKit
import UIKit

/// 重构版 FingerFlow 的入口。
/// 宿主 App 无需修改 Legacy `FingerFlowVC` 即可接入：
/// `navigationController?.pushViewController(NewFingerFlowViewController(), animated: true)`
public final class NewFingerFlowViewController: UIViewController {

  private let rxDisposeBag = DisposeBag()

  /// 纯函数状态机：接收 Event + 当前 snapshot，返回新 snapshot 与待执行的 Effect 列表；不直接操作 UI。
  private var reducer = NewFingerFlowReducer()

  /// 游戏状态的单一真相源（phase、elapsed、press 等）；每次 `send` 后由 Reducer 更新。
  private var snapshot = NewFingerFlowSnapshot()

  /// 主时钟（CADisplayLink）：用唯一 `elapsed` 驱动路径 strokeEnd、圆点位置、welldone/结束判定；暂停时挂起，恢复时继续。
  private let masterClock = NewFingerFlowMasterClock()

  /// 辅助倒计时：开局准备 3s，tick 发 `preparationSecondElapsed`，结束发 `preparationFinished`；不参与路径进度。
  private var preparationClock: NewFingerFlowCountdownClock?

  /// 辅助倒计时：松手后暂停宽限 5s，tick 发 `pauseGraceSecondElapsed`，结束发 `pauseGraceFinished` 并进入真正暂停。
  private var pauseGraceClock: NewFingerFlowCountdownClock?

  private var audioPlayer: AVAudioPlayer?
  private var needToPlay = false
  private var duration: TimeInterval = 60
  private var pauseOverlay: NewFingerFlowPauseOverlay?

  private lazy var bgImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.sd_setImage(with: URL(string: FingerFlowBackgroundImage.bg_pic1.imageUrlString))
    return imageView
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 24, weight: .semibold)
    label.textColor = .white
    label.text = "FingerFlow挑战"
    label.numberOfLines = 0
    return label
  }()

  private var timePicker: FingerFlowTimePicker!

  private lazy var musicIcon: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "fingerflow_music_icon"))
    imageView.contentMode = .center
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  private lazy var imageIcon: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "fingerflow_picture_icon"))
    imageView.contentMode = .center
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  private var gameView: NewFingerFlowGameView!

  public init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    masterClock.delegate = self
    masterClock.duration = duration
    setupViews()
    gameView = NewFingerFlowGameView(duration: duration, delegate: self)
    view.insertSubview(gameView, aboveSubview: bgImageView)
    gameView.snp.makeConstraints { $0.edges.equalToSuperview() }
    bindLifecycle()
    send(.resetRequested)
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    masterClock.pause()
    preparationClock?.cancel()
    pauseGraceClock?.cancel()
  }
}

// MARK: - Reducer 桥接

private extension NewFingerFlowViewController {

  func send(_ event: NewFingerFlowEvent) {
    let (next, effects) = reducer.send(event, snapshot: snapshot)
    snapshot = next
    apply(effects)
  }

  func apply(_ effects: [NewFingerFlowEffect]) {
    for effect in effects {
      switch effect {
      case .applyPhase(let phase):
        snapshot.phase = phase
        if phase == .ended {
          gameView.endSession()
          masterClock.pause()
          preparationClock?.cancel()
          pauseGraceClock?.cancel()
          audioPlayer?.stop()
        }

      case .runGuideLoop:
        gameView.runGuideLoop()

      case .stopGuideLoop:
        gameView.stopGuideLoop()

      case .hideSetupChrome:
        UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
          self.titleLabel.alpha = 0
          self.timePicker.alpha = 0
          self.musicIcon.alpha = 0
          self.imageIcon.alpha = 0
        }.startAnimation()

      case .showSetupChrome:
        [titleLabel, timePicker, musicIcon, imageIcon].forEach { $0.isHidden = false }
        UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
          self.titleLabel.alpha = 1
          self.timePicker.alpha = 1
          self.musicIcon.alpha = 1
          self.imageIcon.alpha = 1
        }.startAnimation()
        masterClock.reset()
        gameView.resetToBefore()

      case .beginPreparationUI:
        gameView.beginPreparation()
        startPreparationCountdown()

      case .beginPathPlayback:
        let sessionDuration = max(snapshot.duration, duration, 1)
        snapshot.duration = sessionDuration
        masterClock.duration = sessionDuration
        masterClock.reset()
        masterClock.start()
        audioPlayer?.play()

      case .prepareResumeWaitingUI(let elapsed, let duration):
        gameView.prepareResumeWaiting(elapsed: elapsed, duration: duration)

      case .pausePathPlayback:
        masterClock.suspend()

      case .resumePathPlayback:
        masterClock.resume()
        audioPlayer?.play()

      case .freezeGuideDot:
        gameView.freezeGuideDot()

      case .scalePutDotIn:
        gameView.scalePutDotIn()

      case .scalePutDotOut:
        gameView.scalePutDotOut()

      case .showPrompt(let prompt):
        gameView.showPrompt(prompt)
        if prompt == .completing {
          gameView.updateCompletingTime((snapshot.elapsed * 1000).toSecondTimeString())
        }

      case .hidePrompt:
        gameView.hidePrompt()

      case .showPauseOverlay(let elapsedMs):
        showPauseOverlay(timeMs: elapsedMs)

      case .removePauseOverlay:
        pauseOverlay?.removeFromSuperview()
        pauseOverlay = nil

      case .startPauseHaptic:
        playRepeatingVibration()

      case .stopPauseHaptic:
        stopVibration()

      case .rebuildPath(let seed, let duration):
        snapshot.pathGeneration = seed
        gameView.rebuildPath(generation: seed, duration: duration)

      case .enterResult:
        let playedSeconds = max(snapshot.elapsed, masterClock.elapsed)
        presentResultVC(duration: playedSeconds)
      }
    }

    if effects.contains(where: { if case .scalePutDotIn = $0 { return true }; return false }) {
      startPauseGraceCountdown()
    }
  }

  func presentResultVC(duration: TimeInterval) {
    let pathSeed = snapshot.pathGeneration
    captureResultImages(duration: duration) { [weak self] bgImage, shareImage in
      guard let self else { return }
      let vm = FingerFlowResultVM(
        duration: duration,
        bestDuration: duration,
        image: bgImage,
        shareImage: shareImage,
        pathSeed: pathSeed
      )
      let resultVC = FingerFlowResultVC(result: vm)
      resultVC.modalPresentationStyle = .overFullScreen
      navigationController?.pushViewController(resultVC, animated: true)
      send(.resetRequested)
    }
  }

  func captureResultImages(
    duration: TimeInterval,
    completion: @escaping (_ bgImage: UIImage?, _ shareImage: UIImage?) -> Void
  ) {
    gameView.prepareForScreenshot()
    pauseOverlay?.isHidden = true
    [titleLabel, timePicker, musicIcon, imageIcon].forEach {
      $0.alpha = 0
      $0.isHidden = true
    }
    view.setNeedsLayout()
    view.layoutIfNeeded()

    // 等待一个 RunLoop，确保 drawHierarchy 能截到已隐藏文案的界面。
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        completion(nil, nil)
        return
      }

      UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 2)
      self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
      guard let bgImage = UIGraphicsGetImageFromCurrentImageContext() else {
        UIGraphicsEndImageContext()
        completion(nil, nil)
        return
      }
      UIGraphicsEndImageContext()

      let screenshotRect = CGRect(
        x: 0,
        y: 174,
        width: FrameGuide.screenWidth,
        height: 574
      )
      guard let screenshotImage = bgImage.croppedImage(screenshotRect) else {
        completion(bgImage, nil)
        return
      }

      FingerFloweShareUtil.generateImage(duration: duration, rawImage: screenshotImage) { shareImage in
        completion(bgImage, shareImage)
      }
    }
  }

  func startPreparationCountdown() {
    preparationClock?.cancel()
    let clock = NewFingerFlowCountdownClock(seconds: 3)
    clock.onTick = { [weak self] remaining in
      self?.gameView.updatePreparationCount(remaining)
      self?.send(.preparationSecondElapsed(remaining: remaining))
    }
    clock.onFinish = { [weak self] in
      self?.gameView.finishPreparationCountdown()
      self?.send(.preparationFinished)
    }
    preparationClock = clock
    clock.start()
  }

  func startPauseGraceCountdown() {
    pauseGraceClock?.cancel()
    let clock = NewFingerFlowCountdownClock(seconds: 5)
    clock.onTick = { [weak self] remaining in
      self?.send(.pauseGraceSecondElapsed(remaining: remaining))
    }
    clock.onFinish = { [weak self] in
      self?.send(.pauseGraceFinished)
    }
    pauseGraceClock = clock
    clock.start()
  }

  func showPauseOverlay(timeMs: TimeInterval) {
    pauseOverlay?.removeFromSuperview()
    let overlay = NewFingerFlowPauseOverlay(timeString: timeMs.toSecondTimeString())
    overlay.onExit = { [weak self] in self?.send(.userTappedExitOnPause) }
    overlay.onContinue = { [weak self] in self?.send(.userTappedContinueOnPause) }
    view.addSubview(overlay)
    overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
    pauseOverlay = overlay
  }

  func bindLifecycle() {
    NotificationCenter.default.rx
      .notification(UIApplication.didEnterBackgroundNotification)
      .subscribe(onNext: { [weak self] _ in
        self?.send(.appEnteredBackground)
        if let audio = self?.audioPlayer, audio.isPlaying {
          audio.pause()
          self?.needToPlay = true
        }
      })
      .disposed(by: rxDisposeBag)

    NotificationCenter.default.rx
      .notification(UIApplication.didBecomeActiveNotification)
      .subscribe(onNext: { [weak self] _ in
        if let audio = self?.audioPlayer, self?.needToPlay == true {
          audio.play()
          self?.needToPlay = false
        }
      })
      .disposed(by: rxDisposeBag)
  }

  func playRepeatingVibration() {
    AudioServicesAddSystemSoundCompletion(
      kSystemSoundID_Vibrate,
      nil,
      nil,
      { _, _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
      },
      nil
    )
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  func stopVibration() {
    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
    AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
  }

  func setupViews() {
    view.addSubview(bgImageView)
    bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

    view.addSubview(titleLabel)
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(35 + FrameGuide.safeAreaBottomHeight)
        make.centerX.equalToSuperview()
    }

    timePicker = FingerFlowTimePicker(
      defaultValue: 1,
      minValue: 1,
      maxValue: 15,
      delegate: self
    )
    view.addSubview(timePicker)
    timePicker.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(77)
      make.left.right.equalToSuperview()
      make.height.equalTo(91)
    }

    view.addSubview(musicIcon)
    musicIcon.snp.makeConstraints { make in
      make.bottom.equalTo(-44 - FrameGuide.safeAreaBottomHeight)
      make.width.height.equalTo(40)
      make.left.equalTo(65)
    }

    view.addSubview(imageIcon)
    imageIcon.snp.makeConstraints { make in
      make.bottom.width.height.equalTo(musicIcon)
      make.right.equalTo(-65)
    }
  }
}

// MARK: - 代理

extension NewFingerFlowViewController: NewFingerFlowGameViewDelegate {

  func gameView(_ view: NewFingerFlowGameView, pressChanged: NewFingerFlowPress) {
    if snapshot.phase == .pauseGrace, pressChanged == .inside {
      pauseGraceClock?.cancel()
    }
    send(.pressChanged(pressChanged))
  }

  func gameViewPreparationFinished(_ view: NewFingerFlowGameView) {
    send(.preparationFinished)
  }
}

extension NewFingerFlowViewController: NewFingerFlowMasterClockDelegate {

  func masterClock(_ clock: NewFingerFlowMasterClock, didTick elapsed: TimeInterval, duration: TimeInterval) {
    gameView.applyPlayback(elapsed: elapsed, duration: duration)
    if duration - elapsed <= 10 {
      gameView.updateCompletingTime((elapsed * 1000).toSecondTimeString())
    }
    send(.masterClockTick(elapsed: elapsed, duration: duration))
  }

  func masterClockDidReachDuration(_ clock: NewFingerFlowMasterClock) {}
}

extension NewFingerFlowViewController: FingerFlowTimePickerDelegate {

  func didValueChanged(_ value: Int) {
    duration = TimeInterval(value * 60)
    snapshot.duration = duration
    masterClock.duration = duration
    gameView.updateDuration(duration)
  }
}
