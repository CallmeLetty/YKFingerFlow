// Copyright (c) 2026, YKFingerFlow
// P3: UIViewPropertyAnimator + keyframes instead of infinite CAKeyframeAnimation.

import UIKit

/// Idle guide loop before the game starts.
final class NewFingerFlowGuideAnimator {

  private weak var promptLabel: UILabel?
  private weak var putDot: UIView?

  private var promptAnimator: UIViewPropertyAnimator?
  private var putAnimator: UIViewPropertyAnimator?
  private var isRunning = false

  func bind(promptLabel: UILabel, putDot: UIView) {
    self.promptLabel = promptLabel
    self.putDot = putDot
  }

  func start(idlePrompt: String) {
    guard !isRunning else { return }
    isRunning = true
    promptLabel?.text = idlePrompt
    promptLabel?.alpha = 0
    putDot?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    runPromptCycle()
    runPutDotCycle()
  }

  func stop() {
    isRunning = false
    promptAnimator?.stopAnimation(true)
    putAnimator?.stopAnimation(true)
    promptAnimator = nil
    putAnimator = nil
    promptLabel?.layer.removeAllAnimations()
    putDot?.layer.removeAllAnimations()
    putDot?.transform = .identity
  }

  // MARK: - Prompt opacity 0 → 1 → 1 → 0 (5s loop)

  private func runPromptCycle() {
    guard isRunning, let label = promptLabel else { return }

    label.alpha = 0
    let fadeIn = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) {
      label.alpha = 1
    }
    fadeIn.addCompletion { [weak self] _ in
      guard let self, self.isRunning else { return }
      let hold = UIViewPropertyAnimator(duration: 2, curve: .linear) { }
      hold.addCompletion { [weak self] _ in
        guard let self, self.isRunning else { return }
        let fadeOut = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) {
          label.alpha = 0
        }
        fadeOut.addCompletion { [weak self] _ in
          self?.runPromptCycle()
        }
        self.promptAnimator = fadeOut
        fadeOut.startAnimation()
      }
      self.promptAnimator = hold
      hold.startAnimation()
    }
    promptAnimator = fadeIn
    fadeIn.startAnimation()
  }

  // MARK: - Put dot scale 0 → 1 → 0 → 1 → 0 (4s loop)

  private func runPutDotCycle() {
    guard isRunning, let dot = putDot else { return }

    dot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    let grow = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.85) {
      dot.transform = .identity
    }
    grow.addCompletion { [weak self] _ in
      guard let self, self.isRunning else { return }
      let shrink = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.85) {
        dot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
      }
      shrink.addCompletion { [weak self] _ in
        guard let self, self.isRunning else { return }
        let grow2 = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.85) {
          dot.transform = .identity
        }
        grow2.addCompletion { [weak self] _ in
          guard let self, self.isRunning else { return }
          let shrink2 = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.85) {
            dot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
          }
          shrink2.addCompletion { [weak self] _ in
            self?.runPutDotCycle()
          }
          self.putAnimator = shrink2
          shrink2.startAnimation()
        }
        self.putAnimator = grow2
        grow2.startAnimation()
      }
      self.putAnimator = shrink
      shrink.startAnimation()
    }
    putAnimator = grow
    grow.startAnimation()
  }
}
