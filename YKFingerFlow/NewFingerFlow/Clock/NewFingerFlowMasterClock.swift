// Copyright (c) 2026, YKFingerFlow — P1: single elapsed timeline (display link + pause accumulation).

import QuartzCore
import UIKit

protocol NewFingerFlowMasterClockDelegate: AnyObject {
  func masterClock(_ clock: NewFingerFlowMasterClock, didTick elapsed: TimeInterval, duration: TimeInterval)
  func masterClockDidReachDuration(_ clock: NewFingerFlowMasterClock)
}

/// Drives game progress, milestone prompts, and path sampling from one `elapsed` value.
final class NewFingerFlowMasterClock {

  weak var delegate: NewFingerFlowMasterClockDelegate?

  private(set) var elapsed: TimeInterval = 0
  var duration: TimeInterval = 60
  var isRunning: Bool { displayLink != nil }

  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval?
  private var accumulatedPause: TimeInterval = 0
  private var pauseBeganAt: CFTimeInterval?

  func reset() {
    pause()
    elapsed = 0
    accumulatedPause = 0
    pauseBeganAt = nil
    lastTimestamp = nil
  }

  func start() {
    guard displayLink == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(step(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
    lastTimestamp = nil
  }

  func pause() {
    displayLink?.invalidate()
    displayLink = nil
    lastTimestamp = nil
  }

  /// Freezes timeline without clearing elapsed (game pause / grace).
  func suspend() {
    pause()
  }

  func resume() {
    start()
  }

  @objc private func step(_ link: CADisplayLink) {
    let now = link.timestamp
    defer { lastTimestamp = now }

    guard let last = lastTimestamp else { return }
    let delta = now - last
    elapsed += delta

    if elapsed >= duration {
      elapsed = duration
      delegate?.masterClock(self, didTick: elapsed, duration: duration)
      delegate?.masterClockDidReachDuration(self)
      pause()
      return
    }

    delegate?.masterClock(self, didTick: elapsed, duration: duration)
  }
}

// MARK: - Secondary discrete clocks (preparation / pause grace)

final class NewFingerFlowCountdownClock {

  var onTick: ((Int) -> Void)?
  var onFinish: (() -> Void)?

  private var task: Task<Void, Never>?
  private var remaining: Int

  init(seconds: Int) {
    remaining = seconds
  }

  func start() {
    cancel()
    let initial = remaining
    task = Task { @MainActor [weak self] in
      guard let self else { return }
      for value in stride(from: initial, through: 1, by: -1) {
        if Task.isCancelled { return }
        self.remaining = value
        self.onTick?(value)
        if value == 1 {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          if Task.isCancelled { return }
          self.onFinish?()
          return
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      }
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
  }

  func reset(to seconds: Int) {
    cancel()
    remaining = seconds
  }
}
