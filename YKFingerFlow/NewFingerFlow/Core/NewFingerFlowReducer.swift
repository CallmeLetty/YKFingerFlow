// Copyright (c) 2026, YKFingerFlow — P2: explicit transition table + single `send` entry.

import Foundation

struct NewFingerFlowReducer {

  private let pauseGraceSeconds = 5
  private let preparationSeconds = 3
  private let welldoneInterval = 15
  private let completingLeadSeconds: TimeInterval = 10
  private let freezeDotLeadSeconds: TimeInterval = 2

  mutating func send(
    _ event: NewFingerFlowEvent,
    snapshot: NewFingerFlowSnapshot
  ) -> (NewFingerFlowSnapshot, [NewFingerFlowEffect]) {
    var next = snapshot
    var effects: [NewFingerFlowEffect] = []

    switch event {
    case .resetRequested:
      return (NewFingerFlowSnapshot(duration: snapshot.duration), resetEffects(duration: snapshot.duration))

    case .pressChanged(let press):
      next.press = press
      effects = handlePress(press, snapshot: next)

    case .preparationSecondElapsed(let remaining):
      next.preparationRemaining = remaining

    case .preparationFinished:
      next.phase = .running
      next.preparationRemaining = preparationSeconds
      effects = enterRunningEffects(snapshot: next)

    case .pauseGraceSecondElapsed(let remaining):
      next.pauseGraceRemaining = remaining

    case .pauseGraceFinished:
      next.phase = .paused
      next.pauseGraceRemaining = pauseGraceSeconds
      effects = enterPausedEffects(snapshot: next)

    case .masterClockTick(let elapsed, let duration):
      next.elapsed = elapsed
      effects = handleClockTick(elapsed: elapsed, duration: duration, snapshot: &next)

    case .userTappedExitOnPause:
      next.phase = .before
      effects = enterEndedEffects()
        
//        let vm = FingerFlowResultVM(duration: duration,
//                                                    bestDuration: bestDuration,
//                                                    image: bgImage,
//                                                    shareImage: shareImage)
//                        let resultVC = FingerFlowResultVC(result: vm)
//                        resultVC.modalPresentationStyle = .overFullScreen
//                        self?.presentVC(resultVC)
//
//                        self?.gameState = .before

    case .userTappedContinueOnPause:
      next.phase = .resumeWaiting
      effects = [
        .applyPhase(.resumeWaiting),
        .removePauseOverlay,
        .prepareResumeWaitingUI(elapsed: snapshot.elapsed, duration: snapshot.duration),
        .scalePutDotOut,
        .showPrompt(.place),
        .runGuideLoop,
      ]

    case .appEnteredBackground:
      effects = handleBackground(snapshot: &next)

    default:
      break
    }

    if next.phase != snapshot.phase, !effects.contains(where: { if case .applyPhase = $0 { return true }; return false }) {
      effects.insert(.applyPhase(next.phase), at: 0)
    }

    return (next, effects)
  }

  // MARK: - Transition table (press × phase)

  private func handlePress(
    _ press: NewFingerFlowPress,
    snapshot: NewFingerFlowSnapshot
  ) -> [NewFingerFlowEffect] {
    switch (snapshot.phase, press) {
    case (.before, .inside):
      return [
        .applyPhase(.preparation),
        .stopGuideLoop,
        .hideSetupChrome,
        .beginPreparationUI,
      ]

    case (.preparation, .none), (.preparation, .outside):
      return resetEffects(duration: snapshot.duration)

    case (.running, .none):
      return pauseFromRunning(snapshot: snapshot, prompt: .place)

    case (.running, .outside):
      return pauseFromRunning(snapshot: snapshot, prompt: .keep)

    case (.resumeGrace, .none):
      return pauseFromRunning(snapshot: snapshot, prompt: .place)

    case (.resumeGrace, .outside):
      return pauseFromRunning(snapshot: snapshot, prompt: .keep)

    case (.resumeWaiting, .inside):
      return [
        .applyPhase(.resumeGrace),
        .stopGuideLoop,
        .scalePutDotOut,
        .hidePrompt,
        .resumePathPlayback,
      ]

    case (.resumeWaiting, .none):
      return [.showPrompt(.place)]

    case (.resumeWaiting, .outside):
      return [.showPrompt(.keep)]

    case (.pauseGrace, .inside):
      var list: [NewFingerFlowEffect] = [
        .applyPhase(.resumeGrace),
        .stopPauseHaptic,
        .scalePutDotOut,
        .resumePathPlayback,
      ]
      if snapshot.duration - snapshot.elapsed <= completingLeadSeconds {
        list.append(.showPrompt(.completing))
      }
      return list

    default:
      return []
    }
  }

  private func pauseFromRunning(
    snapshot: NewFingerFlowSnapshot,
    prompt: NewFingerFlowPrompt
  ) -> [NewFingerFlowEffect] {
    [
      .applyPhase(.pauseGrace),
      .showPrompt(prompt),
      .startPauseHaptic,
      .scalePutDotIn,
      .pausePathPlayback,
    ]
  }

  private func handleClockTick(
    elapsed: TimeInterval,
    duration: TimeInterval,
    snapshot: inout NewFingerFlowSnapshot
  ) -> [NewFingerFlowEffect] {
    guard snapshot.phase.isRunning else { return [] }

    var effects: [NewFingerFlowEffect] = []
    let remaining = duration - elapsed

    if elapsed >= duration {
      snapshot.phase = .ended
      return enterEndedEffects() + [.applyPhase(.ended)]
    }

    let second = Int(elapsed)
    if second > 0, second % welldoneInterval == 0, !snapshot.welldoneShownAtSeconds.contains(second) {
      snapshot.welldoneShownAtSeconds.insert(second)
      effects.append(.showPrompt(.welldone))
    }

    if remaining <= completingLeadSeconds, remaining > completingLeadSeconds - 0.05 {
      effects.append(.showPrompt(.completing))
    }

    if !snapshot.dotFrozen, remaining <= freezeDotLeadSeconds {
      snapshot.dotFrozen = true
      effects.append(.freezeGuideDot)
    }

    return effects
  }

  private func handleBackground(snapshot: inout NewFingerFlowSnapshot) -> [NewFingerFlowEffect] {
    switch snapshot.phase {
    case .running, .resumeGrace:
      snapshot.phase = .pauseGrace
      return pauseFromRunning(snapshot: snapshot, prompt: .place)
    case .preparation:
      snapshot.phase = .before
      return resetEffects(duration: snapshot.duration)
    default:
      return []
    }
  }

  private func resetEffects(duration: TimeInterval) -> [NewFingerFlowEffect] {
    [
      .applyPhase(.before),
      .showSetupChrome,
      .stopGuideLoop,
      .pausePathPlayback,
      .rebuildPath(seed: UInt64.random(in: .min ... .max), duration: duration),
      .runGuideLoop,
      .hidePrompt,
      .scalePutDotOut,
      .removePauseOverlay,
      .stopPauseHaptic,
    ]
  }

  private func enterRunningEffects(snapshot: NewFingerFlowSnapshot) -> [NewFingerFlowEffect] {
    [
      .applyPhase(.running),
      .stopGuideLoop,
      .hidePrompt,
      .rebuildPath(seed: snapshot.pathGeneration &+ 1, duration: snapshot.duration),
      .beginPathPlayback,
    ]
  }

  private func enterPausedEffects(snapshot: NewFingerFlowSnapshot) -> [NewFingerFlowEffect] {
    [
      .applyPhase(.paused),
      .stopPauseHaptic,
      .hidePrompt,
      .pausePathPlayback,
      .showPauseOverlay(elapsedMs: snapshot.elapsed * 1000),
    ]
  }

  private func enterEndedEffects() -> [NewFingerFlowEffect] {
    [
      .stopPauseHaptic,
      .stopGuideLoop,
      .pausePathPlayback,
      .removePauseOverlay,
      .hidePrompt,
    ]
  }
}
