// Copyright (c) 2026, YKFingerFlow — orchestrates reducer + master clock + game view.

import AVFAudio
import AudioToolbox
import RxCocoa
import RxSwift
import SDWebImage
import SnapKit
import UIKit

/// Entry point for the refactored FingerFlow experience.
/// Wire from host app without editing legacy `FingerFlowVC`:
/// `navigationController?.pushViewController(NewFingerFlowViewController(), animated: true)`
public final class NewFingerFlowViewController: UIViewController {

  private let rxDisposeBag = DisposeBag()
  private var reducer = NewFingerFlowReducer()
  private var snapshot = NewFingerFlowSnapshot()

  private let masterClock = NewFingerFlowMasterClock()
  private var preparationClock: NewFingerFlowCountdownClock?
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

// MARK: - Reducer bridge

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
        UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
          self.titleLabel.alpha = 1
          self.timePicker.alpha = 1
          self.musicIcon.alpha = 1
          self.imageIcon.alpha = 1
        }.startAnimation()
        gameView.resetToBefore()

      case .beginPreparationUI:
        gameView.beginPreparation()
        startPreparationCountdown()

      case .beginPathPlayback:
        gameView.useManualGuidePositioning()
        masterClock.duration = snapshot.duration
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
      }
    }

    if effects.contains(where: { if case .scalePutDotIn = $0 { return true }; return false }) {
      startPauseGraceCountdown()
    }

    if snapshot.phase == .ended {
      gameView.endSession()
      masterClock.pause()
      preparationClock?.cancel()
      pauseGraceClock?.cancel()
      audioPlayer?.stop()
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
      make.left.equalTo(20)
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

// MARK: - Delegates

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

  func masterClockDidReachDuration(_ clock: NewFingerFlowMasterClock) {
    gameView.endSession()
  }
}

extension NewFingerFlowViewController: FingerFlowTimePickerDelegate {

  func didValueChanged(_ value: Int) {
    duration = TimeInterval(value * 60)
    snapshot.duration = duration
    masterClock.duration = duration
    gameView.updateDuration(duration)
  }
}
