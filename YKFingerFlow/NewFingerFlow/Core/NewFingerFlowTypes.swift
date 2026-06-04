// Copyright (c) 2026, YKFingerFlow — NewFingerFlow module (legacy code untouched).

import Foundation

// MARK: - Game phase (mirrors FingerFlowState, owned by reducer)

enum NewFingerFlowPhase: String, Equatable {
  case before
  case preparation
  case running
  case pauseGrace
  case paused
  case resumeWaiting
  case resumeGrace
  case ended

  var isRunning: Bool {
    switch self {
    case .running, .resumeGrace:
      return true
    default:
      return false
    }
  }
}

enum NewFingerFlowPress: Equatable {
  case none
  case inside
  case outside
}

enum NewFingerFlowPrompt: Equatable {
  case place
  case keep
  case welldone
  case completing
}

// MARK: - Reducer I/O

enum NewFingerFlowEvent: Equatable {
  case pressChanged(NewFingerFlowPress)
  case preparationSecondElapsed(remaining: Int)
  case preparationFinished
  case pauseGraceSecondElapsed(remaining: Int)
  case pauseGraceFinished
  case masterClockTick(elapsed: TimeInterval, duration: TimeInterval)
  case userTappedExitOnPause
  case userTappedContinueOnPause
  case appEnteredBackground
  case resetRequested
}

enum NewFingerFlowEffect: Equatable {
  case applyPhase(NewFingerFlowPhase)
  case runGuideLoop
  case stopGuideLoop
  case hideSetupChrome
  case showSetupChrome
  case beginPreparationUI
  case beginPathPlayback
  case pausePathPlayback
  case resumePathPlayback
  case freezeGuideDot
  case scalePutDotIn
  case scalePutDotOut
  case showPrompt(NewFingerFlowPrompt)
  case hidePrompt
  case showPauseOverlay(elapsedMs: TimeInterval)
  case removePauseOverlay
  case startPauseHaptic
  case stopPauseHaptic
  case rebuildPath(seed: UInt64, duration: TimeInterval)
  /// Restore guide dot on path after pause sheet dismiss (legacy `resumeFromPauseWaiting`).
  case prepareResumeWaitingUI(elapsed: TimeInterval, duration: TimeInterval)
}

struct NewFingerFlowSnapshot: Equatable {
  var phase: NewFingerFlowPhase = .before
  var press: NewFingerFlowPress = .none
  var preparationRemaining: Int = 3
  var pauseGraceRemaining: Int = 5
  var elapsed: TimeInterval = 0
  var duration: TimeInterval = 60
  var pathGeneration: UInt64 = 0
  var welldoneShownAtSeconds: Set<Int> = []
  var dotFrozen: Bool = false
}
