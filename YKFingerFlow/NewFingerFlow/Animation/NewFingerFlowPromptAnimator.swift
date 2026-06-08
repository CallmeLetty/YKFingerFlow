// Copyright (c) 2026, YKFingerFlow — P3：可中断的提示过渡动画。

import UIKit

final class NewFingerFlowPromptAnimator {

  private var activeAnimator: UIViewPropertyAnimator?

  func cancelActive() {
    activeAnimator?.stopAnimation(true)
    activeAnimator = nil
  }

  func appear(label: UILabel, text: String) {
    cancelActive()
    label.text = text
    label.alpha = 0
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
      label.alpha = 1
    }
    activeAnimator = animator
    animator.startAnimation()
  }

  func disappear(label: UILabel) {
    cancelActive()
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
      label.alpha = 0
    }
    activeAnimator = animator
    animator.startAnimation()
  }

  func welldonePulse(label: UILabel, text: String) {
    cancelActive()
    label.text = text
    label.alpha = 0
    let fadeIn = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) {
      label.alpha = 1
    }
    fadeIn.addCompletion { [weak self] _ in
      let fadeOut = UIViewPropertyAnimator(duration: 1, curve: .easeInOut) {
        label.alpha = 0
      }
      self?.activeAnimator = fadeOut
      fadeOut.startAnimation()
    }
    activeAnimator = fadeIn
    fadeIn.startAnimation()
  }

  func showCompleting(timeLabel: UILabel, subtitleLabel: UILabel, timeText: String) {
    cancelActive()
    timeLabel.text = timeText
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
      timeLabel.alpha = 1
      subtitleLabel.alpha = 1
    }
    activeAnimator = animator
    animator.startAnimation()
  }
}
