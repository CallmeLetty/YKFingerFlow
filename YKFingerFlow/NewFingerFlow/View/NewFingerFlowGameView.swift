// Copyright (c) 2026, YKFingerFlow — game surface driven by master clock + property animators.

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

  private var progressPath: CGPath?
  private var strokeStartFraction: CGFloat = 0
  private var pathGeneration: UInt64 = 0
  private var pathBuildTask: Task<Void, Never>?
  private var duration: TimeInterval = 60
  private var dotFrozen = false
  private var lastDotCenter: CGPoint = .zero
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
    label.text = "Code.FingerflowBeforetrainingText2"
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

  // MARK: - Effects surface (called by VC)

  func resetToBefore() {
    pathBuildTask?.cancel()
    dotFrozen = false
    gameLayer?.removeFromSuperlayer()
    gameLayer = nil
    progressPath = nil
    startLayer.path = layout.startPath.cgPath
    guideDot.layer.removeAllAnimations()
    restoreGuideDotConstraints()
    lastDotCenter = layout.startPoint
    preparationLabel.alpha = 0
    preparationCountLabel.alpha = 0
    completingTimeLabel.alpha = 0
    completingLabel.alpha = 0
    promptLabel.alpha = 1
    promptLabel.text = FingerFlowPropmptType.place.localizedText
    runGuideLoop()
  }

  func runGuideLoop() {
    guideAnimator.start()
  }

  func stopGuideLoop() {
    guideAnimator.stop()
  }

  func beginPreparation() {
    stopGuideLoop()
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
    self.pathGeneration = generation
    self.duration = duration
    let token = generation
    pathBuildTask = Task.detached(priority: .userInitiated) { [layout] in
      let built = layout.buildProgressPath(duration: duration)
      await MainActor.run { [weak self] in
        guard let self, self.pathGeneration == token else { return }
        self.applyBuiltPath(built.path, strokeStart: built.strokeStartFraction)
      }
    }
  }

  /// Use frame-based layout during play so `center` is not fighting SnapKit (fixes dot vanishing after pause).
  func useManualGuidePositioning() {
    guard !usesManualGuidePositioning else { return }
    usesManualGuidePositioning = true
    guideDot.snp.removeConstraints()
    guideDot.translatesAutoresizingMaskIntoConstraints = true
    guideDot.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
  }

  /// Legacy `resumeFromPauseWaiting`: show guide on path + idle pulse until user presses again.
  func prepareResumeWaiting(elapsed: TimeInterval, duration: TimeInterval) {
    stopGuideLoop()
    guideDot.alpha = 1
    guideDot.isHidden = false
    completingTimeLabel.alpha = 0
    completingLabel.alpha = 0
    scalePutDotOut()
    useManualGuidePositioning()
    applyPlayback(elapsed: elapsed, duration: duration)
    bringSubviewToFront(guideDot)
    layoutIfNeeded()
  }

  func applyPlayback(elapsed: TimeInterval, duration: TimeInterval) {
    guard let path = progressPath, duration > 0 else { return }
    let t = min(max(elapsed / duration, 0), 1)
    let fraction = strokeStartFraction + (1 - strokeStartFraction) * CGFloat(t)
    gameLayer?.strokeEnd = fraction

    let point = path.point(atFraction: fraction)
    if !dotFrozen {
      lastDotCenter = point
    }
    positionGuideDot(at: lastDotCenter)
  }

  func freezeGuideDot() {
    dotFrozen = true
  }

  func scalePutDotIn() { putDotScaler.scaleIn(putDot) }
  func scalePutDotOut() { putDotScaler.scaleOut(putDot) }

  func showPrompt(_ prompt: NewFingerFlowPrompt) {
    switch prompt {
    case .place, .keep:
      completingTimeLabel.alpha = 0
      completingLabel.alpha = 0
      let text = mapPrompt(prompt)
      promptAnimator.appear(label: promptLabel, text: text)
    case .welldone:
      promptAnimator.welldonePulse(label: promptLabel, text: mapPrompt(prompt))
    case .completing:
      promptAnimator.showCompleting(
        timeLabel: completingTimeLabel,
        subtitleLabel: completingLabel,
        timeText: completingTimeLabel.text ?? ""
      )
    }
  }

  func hidePrompt() {
    promptAnimator.disappear(label: promptLabel)
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
    [preparationLabel, preparationCountLabel, guideDot, putDot, promptLabel, completingTimeLabel, completingLabel].forEach {
      $0.alpha = 0
    }
  }

  /// P1: hit test from clock-sampled center, not `presentation()` frame.
  func containsTouchNearGuide(_ point: CGPoint, threshold: CGFloat = 55) -> Bool {
    let center = dotFrozen ? lastDotCenter : guideDot.center
    return hypot(point.x - center.x, point.y - center.y) <= threshold
  }
}

// MARK: - Private

private extension NewFingerFlowGameView {

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

  func applyBuiltPath(_ path: CGPath, strokeStart: CGFloat) {
    progressPath = path
    strokeStartFraction = strokeStart
    useManualGuidePositioning()
    gameLayer?.removeFromSuperlayer()

    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.systemBlue.cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = 6
    layer.lineCap = .round
    layer.lineJoin = .round
    layer.path = path
    layer.strokeEnd = strokeStart
    self.gameLayer = layer
    self.layer.addSublayer(layer)
    bringSubviewToFront(guideDot)
  }

  func mapPrompt(_ prompt: NewFingerFlowPrompt) -> String {
    switch prompt {
    case .place: return FingerFlowPropmptType.place.localizedText
    case .keep: return FingerFlowPropmptType.keep.localizedText
    case .welldone: return FingerFlowPropmptType.welldone.localizedText
    case .completing: return FingerFlowPropmptType.completing.localizedText
    }
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
    guideDot.center = point
  }

  @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state != .ended else {
      pressState = .none
      return
    }
    let point = recognizer.location(in: self)
    pressState = containsTouchNearGuide(point) ? .inside : .outside
  }
}

// MARK: - Put dot scale (property animator)

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
