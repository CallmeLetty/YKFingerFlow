// Copyright (c) 2026, YKFingerFlow — 背景图与背景音乐选择。

import AVFAudio
import UIKit

extension NewFingerFlowViewController {
  func checkChosenResource() {
    let imageValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgImage) ?? 1
    currentImage = FingerFlowBackgroundImage(rawValue: imageValue) ?? .bg_pic1

    var musicValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgMusic) ?? 2
    if musicValue == 0 {
      musicValue = 2
    }
    currentMusic = FingerFlowBackgroundMusic(rawValue: musicValue) ?? .bg_music_dreamstate
  }

  func prepareAudioDataGroup() {
    let workingGroup = DispatchGroup()
    let workingQueue = DispatchQueue(label: "fingerflow.audio")

    for item in FingerFlowBackgroundMusic.allCases {
      guard let urlString = item.urlString,
            AppManager.shared.globalDiskCache.getData(for: urlString) == nil,
            let audioURL = URL(string: urlString) else {
        continue
      }
      workingGroup.enter()
      workingQueue.async {
        do {
          let newData = try Data(contentsOf: audioURL)
          AppManager.shared.globalDiskCache.setData(newData, for: urlString)
        } catch {
          OnlineLogger().error(error.localizedDescription)
        }
        workingGroup.leave()
      }
    }

    workingGroup.notify(queue: .main) { [weak self] in
      guard let self, self.needToPlay else { return }
      self.prepareAudio(self.currentMusic)
      self.audioPlayer?.play()
    }
  }

  func prepareAudio(_ selected: FingerFlowBackgroundMusic) {
    guard let urlString = selected.urlString else {
      audioPlayer?.stop()
      audioPlayer = nil
      return
    }

    guard let data = AppManager.shared.globalDiskCache.getData(for: urlString) else {
      needToPlay = true
      audioPlayer?.stop()
      audioPlayer = nil
      return
    }

    needToPlay = false

    do {
      let newPlayer = try AVAudioPlayer(data: data)
      newPlayer.delegate = self
      newPlayer.prepareToPlay()
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback)
      try session.setActive(true)
      audioPlayer = newPlayer
    } catch {
      audioPlayer = nil
    }
  }
}

extension NewFingerFlowViewController: FingerFlowResourcePickerDelegate {
  func onCancelingSelection(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
    case .music(_):
      audioPlayer?.stop()
      needToPlay = false
    case .image(_):
      bgImageView.image = currentImage.image
    }
  }

  func onSelecting(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
    case .music(let selected):
      prepareAudio(selected)
      audioPlayer?.play()
    case .image(let selected):
      bgImageView.image = selected.image
    }
  }

  func onConfirm(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
    case .music(let selected):
      currentMusic = selected
      AppManager.shared.userDiskCache?.setInt(selected.rawValue, for: KVCacheKey.fingerFlowBgMusic)
      prepareAudio(selected)
      audioPlayer?.stop()
      needToPlay = false
    case .image(let selected):
      AppManager.shared.userDiskCache?.setInt(selected.rawValue, for: KVCacheKey.fingerFlowBgImage)
      currentImage = selected
    }
  }
}

extension NewFingerFlowViewController: AVAudioPlayerDelegate {
  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    assert(error != nil)
  }
}
