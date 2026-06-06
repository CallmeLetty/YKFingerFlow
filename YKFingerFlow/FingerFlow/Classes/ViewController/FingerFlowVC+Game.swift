// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import UIKit
import Foundation
import AVFAudio
import Photos
import SnapKit
import RxSwift
import RxCocoa

extension FingerFlowVC: FingerFlowGameViewDelegate {
    // MARK: - FingerFlowGameViewDelegate
  func onPressStateUpdate(_ state: FingerFlowPressState) {
    var newState = gameState

    switch gameState {
      case .before:
        if state == .inside {
          newState = .preparation
        }
      case .preparation:
        if state != .inside {
          newState = .before
        }
      case .start, .resumeFromPauseCountdown, .resumeFromPauseRunning:
        if state == .none {
          gameView.showPrompt(.place)
        } else if state == .outside {
          gameView.showPrompt(.keep)
        } else {
          break
        }
        newState = .pauseCountdown
      case .resumeFromPauseWaiting:
        if state == .none {
          gameView.showPrompt(.place)
        } else if state == .outside {
          gameView.showPrompt(.keep)
        } else if state == .inside {
          newState = .resumeFromPauseRunning
        }
      case .end:
        break
      case .pauseCountdown:
        if state == .inside {
          newState = .resumeFromPauseCountdown
        }
      default:
        break
    }

    gameState = newState
  }

  func onPreparationCountdownEnd() {
    gameState = .start
  }
}

extension FingerFlowVC {
  func _onStateUpdate() {
    switch gameState {
      case .before:
        let hiddenViews = [titleLabel, timePicker, musicIcon, imageIcon]
        for subview in hiddenViews {
          subview.alpha = 1
        }
        resetData()
        gameView.resetToBefore()
      case .preparation:
        let hiddenViews = [titleLabel, timePicker, musicIcon, imageIcon]

          UIView.animate(withDuration: 0.3) {
            for subview in hiddenViews {
              subview.alpha = 0
            }
          } completion: { [weak self] flag in
            guard flag else {
              return
            }
            self?.gameView.startPreparation(.keep)
          }
      case .start:
        audioPlayer?.play()
        gameView.startGame()
        startTimer(.game)
      case .pause:
        gameView.hidePrompt()
        stopVibe()
        audioPlayer?.pause()
        let timeString = (pastDuration * 1000).toSecondTimeString()
        let pauseView = FingerFlowPauseView(timeString: timeString)
        pauseView.exitButton.rx.tap.subscribe(onNext: { [weak self] _ in
          pauseView.removeFromSuperview()
          self?.isFinished = false
          self?.gameState = .end
        })
        .disposed(by: rxDisposeBag)

        pauseView.continueButton.rx.tap.subscribe(onNext: { [weak self] _ in
          pauseView.removeFromSuperview()
          self?.gameState = .resumeFromPauseWaiting
        })
        .disposed(by: rxDisposeBag)
        view.addSubview(pauseView)
        pauseView.snp.makeConstraints { make in
          make.edges.equalToSuperview()
                }
      case .resumeFromPauseWaiting:
        gameView.showPrompt(.place)
        gameView.animateBeforeGame()
      case .resumeFromPauseRunning:
        gameTimer?.resume()
        audioPlayer?.play()
        gameView.scaleOutPutAnimation()
        gameView.hidePrompt()
        gameView.resumeGame()
      case .pauseCountdown:
        startVibe()
        startTimer(.pause)
        gameTimer?.pause()
        gameView.scaleInPutAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
          guard let self = self,
                self.gameState == .pauseCountdown else {
            return
          }
          self.gameView.pause()
        }
      case .resumeFromPauseCountdown:
        stopVibe()
        stopTimer(.pause)
        gameTimer?.resume()
        gameView.scaleOutPutAnimation()
        if (duration - pastDuration) <= 10 {
          gameView.showPrompt(.completing)
        }
        gameView.resumeGame()
      case .end:
        audioPlayer?.stop()
        gameView.endGame()
        screenshotAndUpload()
    }
  }

  // game时间到 / 手势异常导致结束
  private func screenshotResult(completion: ((_ bgImage:UIImage?,_ shareImage: UIImage?) -> ())?) {
    // 背景图裁剪
      UIGraphicsBeginImageContextWithOptions(view.bounds.size,
                                             false,
                                             2)
      view.drawHierarchy(in: view.bounds,
                         afterScreenUpdates: true)
      guard let bgImage = UIGraphicsGetImageFromCurrentImageContext() else {
        UIGraphicsEndImageContext()
        completion?(nil, nil)
        return
      }

    UIGraphicsEndImageContext()

    let screenshotRect = CGRect(x: 0,
                                y: 174,
                                width: FrameGuide.screenWidth,
                                height: 574)
    guard let screenshotImage = bgImage.croppedImage(screenshotRect) else {
      completion?(bgImage, nil)
      return
    }

    FingerFloweShareUtil.generateImage(duration: pastDuration,
                                       rawImage: screenshotImage) { shareImage in
      guard let shareImage = shareImage else {
        completion?(bgImage, nil)
        return
      }
        completion?(bgImage, shareImage)
//      PHPhotoLibrary.shared().performChanges({
//        PHAssetChangeRequest.creationRequestForAsset(from: shareImage)
//      }) { (isSuccess: Bool, error: Error?) in
//        completion?(bgImage, shareImage)
//      }
    }
  }

  private func resetData() {
    pastDuration = 0
    pauseCountdownNumber = 5
    isFinished = false
    needToPlay = false
  }
}

extension FingerFlowVC {
  // MARK: - game timer
  private func startTimer(_ type: FingerFlowTimerType) {
    switch type {
      case .game:
        guard gameTimer == nil else {
          return
        }
        gameTimer = Timer.scheduledTimer(
          timeInterval: 1,
          target:    self,
          selector:  #selector(gameTimerAction),
          userInfo:  nil,
          repeats:   true
        )
      case .pause:
        guard pauseTimer == nil else {
          return
        }

        pauseTimer = Timer.scheduledTimer(
          timeInterval: 1,
          target:    self,
          selector:  #selector(pauseTimerAction),
          userInfo:  nil,
          repeats:   true
        )
      default:
        break
    }
  }

  func stopTimer(_ type: FingerFlowTimerType) {
    switch type {
      case .game:
        gameTimer?.invalidate()
        gameTimer = nil
      case .pause:
        pauseCountdownNumber = 5
        pauseTimer?.invalidate()
        pauseTimer = nil
      default:
        break
    }
  }

  @objc func pauseTimerAction() {
    guard pauseCountdownNumber > 1 else {
      stopTimer(.pause)
      gameState = .pause
      return
    }
    pauseCountdownNumber -= 1
  }

  @objc private func gameTimerAction() {
    guard pastDuration < duration else {
      isFinished = true
      stopTimer(.game)
      gameState = .end
      return
    }
    pastDuration += 1
    if Int(pastDuration) % 15 == 0 {
      gameView.showPrompt(.welldone)
    }

    if (duration - pastDuration) == 10 {
      gameView.showPrompt(.completing)
    }

    if (duration - pastDuration) <= 10 {
      gameView.updateCompletingCount((pastDuration * 1000).toSecondTimeString())
    }

    if (duration - pastDuration) == 2 {
      gameView.stopDot()
    }
  }

  // MARK: - vibe
  private func startVibe() {
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate,
                                          nil,
                                          nil, { (sound,_)  in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
      })
    }, nil);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
  }

  private func stopVibe() {
    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
    AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);
  }

  // MARK: - game over handle
  private func screenshotAndUpload() {
      let duration = self.pastDuration
      screenshotResult { [weak self] bgImage, shareImage in
          let vm = FingerFlowResultVM(duration: duration,
                                      bestDuration: duration, // TODO: UNDO 暂时放本次
                                      image: bgImage,
                                      shareImage: shareImage)
          let resultVC = FingerFlowResultVC(result: vm)
          resultVC.modalPresentationStyle = .overFullScreen
          self?.navigationController?.pushViewController(resultVC, animated: true)
          
          self?.gameState = .before
      }

  }

  private func uploadResult(resultImageUrl: String?,
                            bgImage: UIImage?,
                            shareImage: UIImage?) {
  }
}
