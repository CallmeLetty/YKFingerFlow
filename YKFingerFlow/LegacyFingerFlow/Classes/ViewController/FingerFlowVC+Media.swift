// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import AVKit
import SDWebImage

extension FingerFlowVC {
  func checkChosenResource() {
      // bg image
    let imageValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgImage) ?? 1
    let image = FingerFlowBackgroundImage(rawValue: imageValue) ?? .bg_pic1
    currentImage = image

      // music
    var musicValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgMusic) ?? 2
    if musicValue == 0 {
      musicValue = 2
    }
    let music = FingerFlowBackgroundMusic(rawValue: musicValue) ?? .bg_music_dreamstate
    currentMusic = music
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
          AppManager.shared.globalDiskCache.setData(newData,
                                                    for: urlString)
        } catch (let error) {
          OnlineLogger().error(error.localizedDescription)
        }
      }
    }

    workingGroup.notify(queue: workingQueue) { [weak self] in
      guard let self = self,
            self.needToPlay else {
        return
      }
      self.prepareAudio(self.currentMusic)
      self.audioPlayer?.play()
    }
  }

  func prepareAudio(_ selected: FingerFlowBackgroundMusic) {
    guard let urlString = selected.urlString else {
      // 选中none
      audioPlayer?.stop()
      audioPlayer = nil
      return
    }

    guard let data = AppManager.shared.globalDiskCache.getData(for: urlString) else {
        // 未解析完成
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
      self.audioPlayer = newPlayer
    } catch {
      audioPlayer = nil
    }
  }
}

  // MARK: - subviews delegate
extension FingerFlowVC: FingerFlowResourcePickerDelegate {
    // FingerFlowResourcePicker
  func onCancelingSelection(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
      case .music(_):
        audioPlayer?.stop()
        needToPlay = false
      case .image(_):
        bgImageView.sd_setImage(with: URL(string: currentImage.imageUrlString))
    }
  }

  func onSelecting(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
      case .music(let selected):
        prepareAudio(selected)
        audioPlayer?.play()
      case .image(let selected):
        bgImageView.sd_setImage(with: URL(string: selected.imageUrlString))
    }
  }

  func onConfirm(_ resourceType: FingerFlowResourcePicker.ResourceType) {
    switch resourceType {
      case .music(let selected):
        currentMusic = selected
        AppManager.shared.userDiskCache?.setInt(selected.rawValue,
                                                for: KVCacheKey.fingerFlowBgMusic)
        prepareAudio(selected)
        audioPlayer?.stop()
        needToPlay = false
      case .image(let selected):
        AppManager.shared.userDiskCache?.setInt(selected.rawValue,
                                                for: KVCacheKey.fingerFlowBgImage)
        currentImage = selected
    }
  }
}

// MARK: - AVAudioPlayerDelegate
extension FingerFlowVC: AVAudioPlayerDelegate {
  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    assert(error != nil)
  }
}
