// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import UIComponent
//import SwiftyFoundation

import SnapKit
protocol FingerFlowGameViewDelegate: NSObjectProtocol {
  func onPressStateUpdate(_ state: FingerFlowPressState)
  func onPreparationCountdownEnd()
}

class FingerFlowGameView: UIView {
  private var pressState = FingerFlowPressState.none {
    didSet {
      guard self.pressState != oldValue else {
        return
      }
      self.delegate?.onPressStateUpdate(self.pressState)
    }
  }

  // data
  let speedPerSecond: Double = 15
  var lengthNeededToRun: Double {
    get {
    return Double(duration) * speedPerSecond
    }
  }
  private weak var delegate: FingerFlowGameViewDelegate?
  private var preparationTimer: Timer?
  private var preparationCountdownNumber = 3 {
    didSet {
      preparationCountLabel.text = "\(preparationCountdownNumber)"
    }
  }


  private var duration: Double
  private var paths = [UIBezierPath]()
    // start
  private lazy var startPath = UIBezierPath(start: startPoint,
                                            center: startCenter,
                                            radius: startRadius,
                                            clockWise: startClockWise,
                                            angle: 120)
  private var startClockWise: Bool {
    get {
    return true
    }
  }
  private var startRadius: CGFloat {
    get {
    return  80 * 3 / 2 / Double.pi
    }
  }
  private var startPoint: CGPoint {
    get {
    return CGPoint(x: 80,
                     y: UIDevice.isIPhoneXSeries ? 628 : 517)
    }
  }
  private var startCenter: CGPoint {
    get {
    return CGPoint(x:startPoint.x + startRadius,
                     y:startPoint.y)
    }
  }
  let dotRadius: CGFloat = 50
  private(set) lazy var drawArea = CGRect(x: 0,
                                          y: UIDevice.isIPhoneXSeries ? 174 : 164,
                                          width: FrameGuide.screenWidth,
                                          height: UIDevice.isIPhoneXSeries ? 574 : 473)

  init(frame: CGRect,
       duration: Double,
       delegate: FingerFlowGameViewDelegate?) {
    self.delegate = delegate
    self.duration = duration
    super.init(frame: frame)

    setupViews()
  }

  func updateDuration(_ duration: Double) {
    self.duration = duration
  }

  func scaleInPutAnimation() {
    putDot.animateScaleIn(toValue: 0.3)
  }

  func scaleOutPutAnimation() {
    putDot.animateScaleOut(fromValue: 0.3)
  }

  func resetToBefore() {
    _resetToBefore()
  }

  func endGame() {
    for v in [preparationLabel, preparationCountLabel, guideDot, putDot, promptLabel, completingTimeLabel, completingLabel] {
      v.alpha = 0
    }
    pause()
  }

  func startGame() {
    promptLabel.alpha = 0
    promptLabel.snp.remakeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(159 - bounds.height)
    }
    promptLabel.layer.removeAllAnimations()
    drawCircleList()
  }

  func startPreparation(_ promptType: FingerFlowPropmptType) {
    promptLabel.text = promptType.localizedText
    putDot.layer.removeAllAnimations()
    promptLabel.layer.removeAllAnimations()

    UIView.animate(withDuration: 0.3) { [weak self] in
      self?.promptLabel.alpha = 0
    } completion: { [weak self] complete in
      guard complete else {
        return
      }
      self?._startPreparation()
    }

    DispatchQueue.global().async { [weak self] in
      self?.calculatePoints()
    }
  }

  func resumeGame() {
    promptLabel.animateDisappear()
    putDot.animateScaleOut(fromValue: 0.3)

    lineLayer?.resumeAnimation()
    guideDot.layer.resumeAnimation()
  }

  func pause() {
    lineLayer?.pauseAnimation()
    guideDot.layer.pauseAnimation()
  }

  func showPrompt(_ promptType: FingerFlowPropmptType) {
    switch promptType {
      case .place:
        completingLabel.alpha = 0
        completingTimeLabel.alpha = 0

        promptLabel.layer.removeAllAnimations()
        promptLabel.text = promptType.localizedText
        promptLabel.animateAppear()
      case .keep:
        completingLabel.alpha = 0
        completingTimeLabel.alpha = 0

        promptLabel.layer.removeAllAnimations()
        promptLabel.text = promptType.localizedText
        promptLabel.animateAppear()
      case .welldone:
        promptLabel.text = promptType.localizedText
        promptLabel.alpha = 0

        promptLabel.layer.removeAllAnimations()

        UIView.animate(withDuration: 2) { [weak self] in
          self?.promptLabel.alpha = 1
        } completion: { [weak self] complete in
          guard complete else {
            return
          }
          self?.promptLabel.alpha = 0
        }
      case .completing:
        UIView.animate(withDuration: 0.3) { [weak self] in
          self?.completingTimeLabel.alpha = 1
          self?.completingLabel.alpha = 1
        }
    }
  }

  func hidePrompt() {
    promptLabel.alpha = 0
  }

  func updateCompletingCount(_ timeString: String) {
    completingTimeLabel.alpha = 1
    completingTimeLabel.text = timeString
  }

  func stopDot() {
    guideDot.layer.pauseAnimation()
  }

  // resumeFromPause / resetToBefore(from end / preparation)
  func animateBeforeGame() {
    putDot.layer.removeAllAnimations()
    promptLabel.layer.removeAllAnimations()

    promptLabel.alpha = 1
    let keyAnimate = CAKeyframeAnimation(keyPath: "opacity")
    keyAnimate.duration = 5
    keyAnimate.keyTimes = [0,0.2,0.6,0.8]
    keyAnimate.values = [0,1,1,0]
    keyAnimate.autoreverses = false
    keyAnimate.isRemovedOnCompletion = false // 避免退后台动画消失
    keyAnimate.repeatCount = MAXFLOAT
    keyAnimate.duration = 5

    promptLabel.layer.add(keyAnimate, forKey: "prompt.before")

    // put dot
    let scaleAnimate = CAKeyframeAnimation(keyPath: "transform.scale")
    scaleAnimate.duration = 4
    scaleAnimate.keyTimes = [0,0.25,0.5,0.75,1]
    scaleAnimate.values = [0,1,0,1,0]
    scaleAnimate.autoreverses = false
    scaleAnimate.isRemovedOnCompletion = false // 避免退后台动画消失
    scaleAnimate.repeatCount = MAXFLOAT

    putDot.layer.add(keyAnimate, forKey: "putDot.before")
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    stopPreparationTimer()
  }

  // MARK: - lazy
  private lazy var startLayer = {
    let shapeLayer = CAShapeLayer()

    shapeLayer.strokeColor = UIColor.blue.cgColor
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.lineWidth = 6.0
    shapeLayer.lineCap = .round
    shapeLayer.lineJoin = .round
    return shapeLayer
  }()

  private(set) var lineLayer: CAShapeLayer?

  private lazy var preparationLabel = {
    let preparationLabel = UILabel()

    preparationLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
    preparationLabel.textColor = UIColor.black
    preparationLabel.text = "Code.FingerflowBeforetrainingText2"
    preparationLabel.textAlignment = .center
    preparationLabel.numberOfLines = 0
    preparationLabel.alpha = 0
    return preparationLabel
  }()

  private lazy var preparationCountLabel = {
    let preparationCountLabel = UILabel()

    preparationCountLabel.font = UIFont.systemFont(ofSize: 34, weight: .semibold)
    preparationCountLabel.textColor = UIColor.black
    preparationCountLabel.text = "3"
    preparationCountLabel.textAlignment = .center
    preparationCountLabel.numberOfLines = 0
    preparationCountLabel.alpha = 0
    return preparationCountLabel
  }()
  private lazy var guideDot = UIImageView(image: UIImage(named: "fingerflow_dot_img",
                                                         in: type(of: self)))

  private lazy var putDot = UIImageView(image: UIImage(named: "fingerflow_put_img",
                                                       in: type(of: self)))

  private(set) lazy var promptLabel = {
    let promptLabel = UILabel()

    promptLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
    promptLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    promptLabel.textAlignment = .center
    promptLabel.numberOfLines = 0
    return promptLabel
  }()

  private lazy var completingTimeLabel = {
    let completingTimeLabel = UILabel()

    completingTimeLabel.font = UIFont.systemFont(ofSize: 34, weight: .semibold)
    completingTimeLabel.textColor = UIColor.black
    completingTimeLabel.textAlignment = .center
    completingTimeLabel.numberOfLines = 0
    completingTimeLabel.alpha = 0
    return completingTimeLabel
  }()

  private lazy var completingLabel = {
    let completingLabel = UILabel()

    completingLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    completingLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    completingLabel.text = "Code.FingerflowEndingText1"
    completingLabel.textAlignment = .center
    completingLabel.numberOfLines = 0
    completingLabel.alpha = 0
    return completingLabel
  }()
}

private extension FingerFlowGameView {
  func calculatePoints() {
    let pointSafeArea = CGRect(x: drawArea.minX + dotRadius,
                               y: drawArea.minY + dotRadius,
                               width: drawArea.width - dotRadius * 2,
                               height: drawArea.height - dotRadius * 2)
    var leftPaths = startPath.subPaths(startClockWise: true,
                                       startCenter: startCenter,
                                       wholeLengthWithoutStart: lengthNeededToRun,
                                       pointSafeArea: pointSafeArea)

    while leftPaths == nil {
      leftPaths = startPath.subPaths(startClockWise: true,
                                     startCenter: startCenter,
                                     wholeLengthWithoutStart: lengthNeededToRun,
                                     pointSafeArea: pointSafeArea)
    }
    paths.append(contentsOf: leftPaths!)
  }

  func drawCircleList() {
    let progressPath = UIBezierPath()
    for path in paths {
      progressPath.append(path)
    }
    let gameLayer = CAShapeLayer()
    gameLayer.strokeColor = UIColor.blue.cgColor
    gameLayer.fillColor = UIColor.clear.cgColor
    gameLayer.lineWidth = 6.0
    gameLayer.lineCap = .round
    gameLayer.lineJoin = .round
    gameLayer.path = progressPath.cgPath
    
    lineLayer = gameLayer
    layer.addSublayer(gameLayer)
    bringSubviewToFront(guideDot)

    guard let gamePath = gameLayer.path else {
      return
    }

    // line path animate
    let fromValue = startPath.cgPath.length / lengthNeededToRun
    let animateStrokeEnd = CABasicAnimation(keyPath: "strokeEnd")
    animateStrokeEnd.duration = duration
    animateStrokeEnd.fromValue = fromValue
    animateStrokeEnd.toValue = 1
    animateStrokeEnd.fillMode = .forwards
    animateStrokeEnd.isRemovedOnCompletion = false
    gameLayer.add(animateStrokeEnd,
                  forKey: "Move")

    // circle dot animate
    let dotDuration = duration + startPath.cgPath.length / 15
    let circleAnimation = CAKeyframeAnimation(keyPath:"position")
    circleAnimation.duration = dotDuration
    circleAnimation.path = gamePath
    circleAnimation.calculationMode = .paced
    circleAnimation.isRemovedOnCompletion = false
    circleAnimation.fillMode = .forwards

    self.guideDot.layer.add(circleAnimation, forKey:"Move")
  }

  func _startPreparation() {
    // promptLabel
    promptLabel.layer.removeAllAnimations()

    // countdown
    UIView.animate(withDuration: 0.3) { [weak self] in
      self?.preparationLabel.alpha = 1
      self?.preparationCountLabel.alpha = 1
      self?.promptLabel.alpha = 1
    } completion: { [weak self] complete in
      guard let self = self,
            complete else {
        return
      }
      self.startPreparationTimer()
    }
  }
}

// MARK: - Base UI
private extension FingerFlowGameView {
  func _resetToBefore(_ promptType: FingerFlowPropmptType = .place) {
    guideDot.layer.resetMoveAnimation()

    for v in [preparationLabel,preparationCountLabel, completingTimeLabel, completingLabel] {
      v.layer.removeAllAnimations()
      v.alpha = 0
    }
    stopPreparationTimer()

    for v in [guideDot, putDot, promptLabel] {
      v.alpha = 1
    }
    // path
    paths.removeAll()
    paths.append(startPath)

    lineLayer?.removeFromSuperlayer()
    lineLayer = nil

    // dot
    bringSubviewToFront(guideDot)
    guideDot.snp.remakeConstraints { make in
      make.center.equalTo(startPoint)
      make.width.height.equalTo(100)
    }

    promptLabel.text = promptType.localizedText
    promptLabel.snp.remakeConstraints { make in
      make.left.equalTo(30)
      make.bottom.equalTo(guideDot.snp.top).offset(-50)
      make.width.equalTo(228.5)
    }

    animateBeforeGame()
  }

  func setupViews() {
    backgroundColor = .clear
    let ges = UILongPressGestureRecognizer(target: self,
                                           action: #selector(longPressGuideDot))
    addGestureRecognizer(ges)
    isUserInteractionEnabled = true

    self.addSubview(preparationLabel)

    preparationLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(30 + FrameGuide.safeAreaBottomHeight)
    
    }

    self.addSubview(preparationCountLabel)

    preparationCountLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(preparationLabel.snp.bottom).offset(12)
    
    }

    self.addSubview(completingTimeLabel)

    completingTimeLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(30 + FrameGuide.safeAreaBottomHeight)
    
    }

    self.addSubview(completingLabel)

    completingLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.left.right.equalToSuperview().inset(20)
      make.top.equalTo(completingTimeLabel.snp.bottom).offset(6)
    
    }

    startLayer.path = startPath.cgPath
    layer.addSublayer(startLayer)

    self.addSubview(guideDot)

    guideDot.snp.makeConstraints { make in
      make.center.equalTo(startPoint)
      make.width.height.equalTo(100)
    
    }

    guideDot.addSubview(putDot)

    putDot.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    
    }

    self.addSubview(promptLabel)

    promptLabel.snp.makeConstraints { make in
      make.left.equalTo(30)
      make.bottom.equalTo(guideDot.snp.top).offset(-50)
      make.width.equalTo(228.5)
    
    }
  }
}

// MARK: - action
private extension FingerFlowGameView {
  @objc func longPressGuideDot(recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state != .ended else {
      pressState = .none
      return
    }
    guard let guideFrame = guideDot.layer.presentation()?.frame else {
      pressState = .none
      return
    }

    let point = recognizer.location(in: self)
    let contain = guideFrame.contains(point)
    pressState = contain ? .inside : .outside
  }
}

// MARK: - preparation timer
private extension FingerFlowGameView {
    func startPreparationTimer() {
      guard preparationTimer == nil else {
        return
      }

      preparationTimer = Timer.scheduledTimer(
        timeInterval: 1,
        target:    self,
        selector:  #selector(preparationTimerAction),
        userInfo:  nil,
        repeats:   true
      )
    }

    func stopPreparationTimer() {
      preparationCountdownNumber = 3
      preparationTimer?.invalidate()
      preparationTimer = nil
    }

    @objc func preparationTimerAction() {
      guard preparationCountdownNumber > 1 else {
        delegate?.onPreparationCountdownEnd()
        preparationLabel.alpha = 0
        preparationCountLabel.alpha = 0
        stopPreparationTimer()
        return
      }
      preparationCountdownNumber -= 1
    }
}
