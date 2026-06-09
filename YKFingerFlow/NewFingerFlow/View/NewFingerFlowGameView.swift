// Copyright (c) 2026, YKFingerFlow — 由主时钟与属性动画驱动的游戏界面。

import SnapKit
import UIKit

protocol NewFingerFlowGameViewDelegate: AnyObject {
  func gameView(_ view: NewFingerFlowGameView, pressChanged: NewFingerFlowPress)
  func gameViewPreparationFinished(_ view: NewFingerFlowGameView)
}

final class NewFingerFlowGameView: UIView {

  weak var delegate: NewFingerFlowGameViewDelegate?

  private let layout = NewFingerFlowPathLayout.make()
  private let guideAnimator = NewFingerFlowGuideAnimator()
  private let promptAnimator = NewFingerFlowPromptAnimator()
  private let putDotScaler = NewFingerFlowPutDotScaler()

  // MARK: - 路径与播放状态

  /// 本局已构建的路径：`cgPath`、弧长查表、`strokeStartFraction`；`nil` 表示尚未开局或已 reset。
  private var builtPath: NewFingerFlowBuiltPath?
  /// 线 `strokeEnd` 的起始值（起始 120° 弧占全路径的弧长比例），来自 `builtPath.strokeStartFraction`。
  private var strokeStartFraction: CGFloat = 0
  /// 弧长查表顺序 hint；`dotT` 单调递增时沿 knot 表向前扫，避免每帧从头查找。
  private var arcLengthHintIndex = 0
  /// 最近一次 `rebuildPath` 使用的随机种子（与 Reducer `pathGeneration` 同步传入 SubPathGenerator）。
  private var pathGeneration: UInt64 = 0
  /// 异步建路径任务句柄（历史预留）。当前 `rebuildPath` 为同步构建，仅 reset/deinit 时 cancel 以防旧 Task 残留。
  private var pathBuildTask: Task<Void, Never>?
  /// 本局挑战时长（秒），与 VC / 主时钟一致；用于 `applyPlayback` 计算 `timeProgress` 与 `dotDuration`。
  private var duration: TimeInterval = 60

  // MARK: - 圆点摆位与命中

  /// 局末前 2s 为 true：`applyPlayback` 不再更新圆点位置（对齐 Legacy `stopDot`），线仍可继续画。
  private var dotFrozen = false
  /// 上一帧查表得到的圆心；命中检测与 `dotFrozen` 时显示均用此坐标，避免读 `presentation()`。
  private var lastDotCenter: CGPoint = .zero
  /// true = 圆点改用手动 `center` 摆位（已移除 SnapKit 约束）；游戏中/暂停恢复后必须为 true，否则约束与 center 打架导致圆点消失。
  private var usesManualGuidePositioning = false

  private var pressState = NewFingerFlowPress.none {
    didSet {
      guard pressState != oldValue else { return }
      delegate?.gameView(self, pressChanged: pressState)
    }
  }

  private lazy var startLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.systemBlue.cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = 6
    layer.lineCap = .round
    layer.lineJoin = .round
    return layer
  }()

  private var gameLayer: CAShapeLayer?

  private lazy var guideDot = UIImageView(image: UIImage(named: "fingerflow_dot_img"))
  private lazy var putDot = UIImageView(image: UIImage(named: "fingerflow_put_img"))

  private lazy var promptLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 20, weight: .medium)
    label.textColor = UIColor.white.withAlphaComponent(0.8)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.text = FingerFlowPropmptType.place.localizedText
    return label
  }()

  private lazy var preparationLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 22, weight: .semibold)
    label.textColor = .white
    label.text = "准备"
    label.textAlignment = .center
    label.numberOfLines = 0
    label.alpha = 0
    return label
  }()

  private lazy var preparationCountLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 34, weight: .semibold)
    label.textColor = .white
    label.text = "3"
    label.textAlignment = .center
    label.alpha = 0
    return label
  }()

  private lazy var completingTimeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 34, weight: .semibold)
    label.textColor = .white
    label.textAlignment = .center
    label.alpha = 0
    return label
  }()

  private lazy var completingLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 18, weight: .medium)
    label.textColor = UIColor.white.withAlphaComponent(0.8)
    label.text = FingerFlowPropmptType.completing.localizedText
    label.textAlignment = .center
    label.numberOfLines = 0
    label.alpha = 0
    return label
  }()

  init(duration: TimeInterval, delegate: NewFingerFlowGameViewDelegate?) {
    self.duration = duration
    self.delegate = delegate
    super.init(frame: .zero)
    setupViews()
    guideAnimator.bind(promptLabel: promptLabel, putDot: putDot)
    resetToBefore()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    pathBuildTask?.cancel()
  }

  func updateDuration(_ duration: TimeInterval) {
    self.duration = duration
  }

  // MARK: - Effect 执行面（由 VC 调用）

  func resetToBefore() {
    pathBuildTask?.cancel()
    dotFrozen = false
    gameLayer?.removeFromSuperlayer()
    gameLayer = nil
    builtPath = nil
    arcLengthHintIndex = 0
    startLayer.isHidden = false
    startLayer.path = layout.startPath.cgPath
    guideDot.layer.removeAllAnimations()
    putDot.layer.removeAllAnimations()
    restoreGuideDotConstraints()
    layoutIfNeeded()
    lastDotCenter = layout.startPoint
    guideDot.alpha = 1
    guideDot.isHidden = false
    putDot.alpha = 1
    putDot.transform = .identity
    preparationLabel.alpha = 0
    preparationCountLabel.alpha = 0
    completingTimeLabel.alpha = 0
    completingLabel.alpha = 0
    showIdlePrompt()
    bringSubviewToFront(guideDot)
    runGuideLoop()
  }

  /// 局末截图前隐藏屏幕文案（须同步执行，不用淡出动画）。
  func prepareForScreenshot() {
    stopGuideLoop()
    promptAnimator.cancelActive()
    hideGameplayTextImmediately()
  }

  func showIdlePrompt() {
    promptAnimator.cancelActive()
    promptLabel.text = FingerFlowPropmptType.place.localizedText
    promptLabel.isHidden = false
    promptLabel.alpha = 0
  }

  func runGuideLoop(idlePrompt: String = FingerFlowPropmptType.place.localizedText) {
    guideAnimator.start(idlePrompt: idlePrompt)
  }

  func stopGuideLoop() {
    guideAnimator.stop()
  }

  func beginPreparation() {
    stopGuideLoop()
    promptLabel.isHidden = false
    promptAnimator.appear(label: promptLabel, text: FingerFlowPropmptType.keep.localizedText)
    UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
      self.preparationLabel.alpha = 1
      self.preparationCountLabel.alpha = 1
    }.startAnimation()
  }

  func updatePreparationCount(_ remaining: Int) {
    preparationCountLabel.text = "\(remaining)"
  }

  func finishPreparationCountdown() {
    preparationLabel.alpha = 0
    preparationCountLabel.alpha = 0
    delegate?.gameViewPreparationFinished(self)
  }

  func rebuildPath(generation: UInt64, duration: TimeInterval) {
    pathBuildTask?.cancel()
    pathBuildTask = nil
    pathGeneration = generation
    self.duration = duration
    // 同步应用，使同批 Effect 中的 `beginPathPlayback` 能看到就绪路径，
    // 引导圆点停在路径起点（fraction 0），而非待机起始弧末端。
    let built = layout.buildProgressPath(duration: duration, seed: generation)
    applyBuiltPath(built)
  }

  /// 游戏中用手动 frame 布局，避免 `center` 与 SnapKit 冲突（修复暂停后圆点消失）。
  func useManualGuidePositioning() {
    guard !usesManualGuidePositioning else { return }
    layoutIfNeeded()
    let preservedCenter = guideDot.center
    usesManualGuidePositioning = true
    guideDot.snp.removeConstraints()
    guideDot.translatesAutoresizingMaskIntoConstraints = true
    guideDot.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    guideDot.center = preservedCenter
  }

  /// 对应 Legacy `resumeFromPauseWaiting`：在路径上显示引导圆点并播放待机动画，直至用户再次按压。
  func prepareResumeWaiting(elapsed: TimeInterval, duration: TimeInterval) {
    stopGuideLoop()
    guideDot.alpha = 1
    guideDot.isHidden = false
    completingTimeLabel.alpha = 0
    completingLabel.alpha = 0
    scalePutDotOut()
    useManualGuidePositioning()
    arcLengthHintIndex = 0
    applyPlayback(elapsed: elapsed, duration: duration)
    bringSubviewToFront(guideDot)
    layoutIfNeeded()
    runGuideLoop(idlePrompt: FingerFlowPropmptType.pausePlace.localizedText)
  }

  /// 每帧把主时钟 **时间** `elapsed` 映射到路径 **几何**（线 stroke / 圆点坐标）。
  ///
  /// 时间 → 几何须分两步，不能直接把 `elapsed/duration` 当路径 t：
  /// 1. `elapsed / duration`（或 `dotDuration`）→ 得到 0…1 的 **播放进度**（时间维）；
  /// 2. 将进度作为 **弧长比例** 传给 `ArcLengthPath.point(atFraction:)`（距离维），才得到圆点坐标。
  ///
  /// 线与圆点使用不同时间分母（对齐 Legacy 双 CA），故 `strokeFraction` 与 `dotT` 不同。
  func applyPlayback(elapsed: TimeInterval, duration: TimeInterval) {
    guard let built = builtPath, duration > 0 else { return }

    // 时间维：用户设定的游戏时长内走了多少比例（≠ 路径方程参数 t）
    let timeProgress = min(max(elapsed / duration, 0), 1)
    // 几何维：strokeEnd 按弧长比例，从起始 120° 弧终点（strokeStartFraction）画到路径末端
    let strokeFraction = strokeStartFraction + (1 - strokeStartFraction) * CGFloat(timeProgress)
    gameLayer?.strokeEnd = strokeFraction

    if !dotFrozen {
      let startArcLength = layout.startRadius * 120 / 180 * .pi
      // 圆点沿全路径的「时间轴」比线多 startArc/15 秒（Legacy position CA 的 duration）
      let dotDuration = duration + startArcLength / 15
      let dotT = min(max(elapsed / dotDuration, 0), 1)
      let point: CGPoint
      if dotT <= 0 {
        point = layout.startPoint
      } else {
        // dotT 此处作为弧长比例 fraction 查表，实现匀速沿路径移动（弧长参数化）
        point = built.arcLengthPath.point(atFraction: CGFloat(dotT), hintIndex: &arcLengthHintIndex)
      }
      lastDotCenter = point
      positionGuideDot(at: lastDotCenter)
    }
  }

  func freezeGuideDot() {
    dotFrozen = true
  }

  func scalePutDotIn() { putDotScaler.scaleIn(putDot) }
  func scalePutDotOut() { putDotScaler.scaleOut(putDot) }

  func showPrompt(_ prompt: NewFingerFlowPrompt) {
    switch prompt {
    case .place, .pausePlace, .keep:
      completingTimeLabel.alpha = 0
      completingLabel.alpha = 0
      completingTimeLabel.isHidden = true
      completingLabel.isHidden = true
      promptLabel.isHidden = false
        let text = prompt.localizedText
      promptAnimator.appear(label: promptLabel, text: text)
    case .welldone:
        promptAnimator.welldonePulse(label: promptLabel, text: prompt.localizedText)
    case .completing:
      promptAnimator.showCompleting(
        timeLabel: completingTimeLabel,
        subtitleLabel: completingLabel,
        timeText: completingTimeLabel.text ?? ""
      )
    }
  }

  func hidePrompt() {
    promptAnimator.cancelActive()
    promptLabel.layer.removeAllAnimations()
    promptLabel.alpha = 0
  }

  func hideGameplayTextImmediately() {
    gameplayTextLabels.forEach { label in
      label.layer.removeAllAnimations()
      label.alpha = 0
      label.isHidden = true
    }
  }

  func updateCompletingTime(_ text: String) {
    completingTimeLabel.text = text
    if completingTimeLabel.alpha < 1 {
      promptAnimator.showCompleting(
        timeLabel: completingTimeLabel,
        subtitleLabel: completingLabel,
        timeText: text
      )
    }
  }

  func endSession() {
    stopGuideLoop()
    promptAnimator.cancelActive()
    hideGameplayTextImmediately()
    [guideDot, putDot].forEach { $0.alpha = 0 }
  }
}

// MARK: - 私有

private extension NewFingerFlowGameView {

  var gameplayTextLabels: [UILabel] {
    [preparationLabel, preparationCountLabel, promptLabel, completingTimeLabel, completingLabel]
  }

  func setupViews() {
    backgroundColor = .clear
    let ges = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    addGestureRecognizer(ges)

    startLayer.path = layout.startPath.cgPath
    layer.addSublayer(startLayer)

    addSubview(preparationLabel)
    preparationLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(30 + FrameGuide.safeAreaBottomHeight)
    }

    addSubview(preparationCountLabel)
    preparationCountLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(preparationLabel.snp.bottom).offset(12)
    }

    addSubview(completingTimeLabel)
    completingTimeLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(30 + FrameGuide.safeAreaBottomHeight)
    }

    addSubview(completingLabel)
    completingLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.left.right.equalToSuperview().inset(20)
      make.top.equalTo(completingTimeLabel.snp.bottom).offset(6)
    }

    addSubview(guideDot)
    guideDot.snp.makeConstraints { make in
      make.center.equalTo(layout.startPoint)
      make.width.height.equalTo(100)
    }

    guideDot.addSubview(putDot)
    putDot.snp.makeConstraints { $0.edges.equalToSuperview() }

    addSubview(promptLabel)
    promptLabel.snp.makeConstraints { make in
      make.left.equalTo(30)
      make.bottom.equalTo(guideDot.snp.top).offset(-50)
      make.width.equalTo(228.5)
    }
  }

  func applyBuiltPath(_ built: NewFingerFlowBuiltPath) {
    builtPath = built
    strokeStartFraction = built.strokeStartFraction
    arcLengthHintIndex = 0
    useManualGuidePositioning()
    gameLayer?.removeFromSuperlayer()
    startLayer.isHidden = true

    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.systemBlue.cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = 6
    layer.lineCap = .round
    layer.lineJoin = .round
    layer.path = built.cgPath
    layer.strokeEnd = built.strokeStartFraction
    gameLayer = layer
    self.layer.addSublayer(layer)
    lastDotCenter = layout.startPoint
    guideDot.center = layout.startPoint
    bringSubviewToFront(guideDot)
    applyPlayback(elapsed: 0, duration: duration)
  }

  func restoreGuideDotConstraints() {
    usesManualGuidePositioning = false
    guideDot.translatesAutoresizingMaskIntoConstraints = false
    guideDot.snp.remakeConstraints { make in
      make.center.equalTo(layout.startPoint)
      make.width.height.equalTo(100)
    }
  }

  func positionGuideDot(at point: CGPoint) {
    if !usesManualGuidePositioning {
      useManualGuidePositioning()
    }
    guideDot.layer.removeAllAnimations()
    guideDot.center = point
  }

  @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state != .ended else {
      pressState = .none
      return
    }
      let point = recognizer.location(in: self)
      let center = dotFrozen ? lastDotCenter : guideDot.center
      /// 用时钟采样的圆心做命中检测，而非 `presentation()` 的 frame。
      let containsTouchNearGuide = (hypot(point.x - center.x, point.y - center.y) <= 55)
      pressState = containsTouchNearGuide ? .inside : .outside
  }
}

// MARK: - 按压圆点缩放（属性动画）

private final class NewFingerFlowPutDotScaler {
  private var animator: UIViewPropertyAnimator?

  func scaleIn(_ view: UIView) {
    animator?.stopAnimation(true)
    let anim = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
      view.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
    }
    animator = anim
    anim.startAnimation()
  }

  func scaleOut(_ view: UIView) {
    animator?.stopAnimation(true)
    let anim = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
      view.transform = .identity
    }
    animator = anim
    anim.startAnimation()
  }
}
