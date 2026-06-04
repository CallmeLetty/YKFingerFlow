// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

///mport UIComponent
import UIKit

enum FingerFlowState: String {
  case before // 指示动画循环播放
  case preparation // 倒计时，动画
  case start
  case pauseCountdown
  case pause
  case resumeFromPauseCountdown
  case resumeFromPauseWaiting
  case resumeFromPauseRunning
  case end

  var isRunning: Bool {
    return [FingerFlowState.resumeFromPauseRunning,
            FingerFlowState.start,
            FingerFlowState.resumeFromPauseCountdown].contains(self)
  }
}

enum FingerFlowBackgroundImage: Int, CaseIterable {
  case bg_pic1 = 1
  case bg_pic2 = 2
  case bg_pic3 = 3
  case bg_pic4 = 4
  case bg_pic5 = 5
  case bg_pic6 = 6
  case bg_pic7 = 7
  case bg_pic8 = 8
  case bg_pic9 = 9
  case bg_pic10 = 10

  var index: Int {
    return FingerFlowBackgroundImage.allCases.firstIndex(of: self) ?? 0
  }

  var trackName: String {
    return "pic\(index + 1)"
  }

  var imageUrlString: String {
    switch self {
      case .bg_pic1: return "https://s.bongmi.cn/push/imgs/8e0c19d6915b2d26def7de815b7cf725.png"
      case .bg_pic2: return "https://s.bongmi.cn/push/imgs/355845c2700b2ad415beb2f7d3babe71.png"
      case .bg_pic3: return "https://s.bongmi.cn/push/imgs/0cad48f6903442e6cc13f4001e1128cc.png"
      case .bg_pic4: return "https://s.bongmi.cn/push/imgs/5055cc800cc513f82b1a69f300e1343d.png"
      case .bg_pic5: return "https://s.bongmi.cn/push/imgs/a5142ef2b03abdf572d59d08ce18242d.png"
      case .bg_pic6: return "https://s.bongmi.cn/push/imgs/c693786f19aba73551292e6d96021d4a.png"
      case .bg_pic7: return "https://s.bongmi.cn/push/imgs/d106e856f435e4b90db4444bcefb3af1.png"
      case .bg_pic8: return "https://s.bongmi.cn/push/imgs/c374c73f0ec949695e85dc721501a8d6.png"
      case .bg_pic9: return "https://s.bongmi.cn/push/imgs/34950a354427ff830d0f2a205b91eb55.png"
      case .bg_pic10: return "https://s.bongmi.cn/push/imgs/a12068f599528cdb4721736509732540.png"
    }
  }
}

enum FingerFlowBackgroundMusic: Int, CaseIterable {
  case bg_music_none = 1
  case bg_music_dreamstate = 2
  case bg_music_galaxy = 3
  case bg_music_moon = 4
  case bg_music_crystal = 5
  case bg_music_rain = 6
  case bg_music_origin = 7
  case bg_music_spring = 8
  case bg_music_ethereal = 9

  var index: Int {
    return FingerFlowBackgroundMusic.allCases.firstIndex(of: self) ?? 1
  }

  var trackName: String {
    switch self {
      case .bg_music_none:          return "No music"
      case .bg_music_dreamstate:    return "Dreamstate"
      case .bg_music_galaxy:        return "Galaxy"
      case .bg_music_moon:          return "Moon"
      case .bg_music_crystal:       return "Crystal"
      case .bg_music_rain:          return "Rain"
      case .bg_music_origin:        return "Origin"
      case .bg_music_spring:        return "Spring"
      case .bg_music_ethereal:      return "Ethereal"
    }
  }

  var normalImage: UIImage? {
    var imageStr = ""
    switch self {
      case .bg_music_none:          imageStr = "sound_default_no"
      case .bg_music_dreamstate:    imageStr = "sound_default_dreamstate"
      case .bg_music_galaxy:        imageStr = "sound_default_galaxy"
      case .bg_music_moon:          imageStr = "sound_default_moon"
      case .bg_music_crystal:       imageStr = "sound_default_crystal"
      case .bg_music_rain:          imageStr = "sound_default_rain"
      case .bg_music_origin:        imageStr = "sound_default_origin"
      case .bg_music_spring:        imageStr = "sound_default_spring"
      case .bg_music_ethereal:      imageStr = "sound_default_ethereal"
    }
    return  UIImage(named: imageStr)
  }

  var highlightImage: UIImage? {
    var imageStr = ""
    switch self {
      case .bg_music_none:          imageStr = "sound_selected_no"
      case .bg_music_dreamstate:    imageStr = "sound_selected_dreamstate"
      case .bg_music_galaxy:        imageStr = "sound_selected_galaxy"
      case .bg_music_moon:          imageStr = "sound_selected_moon"
      case .bg_music_crystal:       imageStr = "sound_selected_crystal"
      case .bg_music_rain:          imageStr = "sound_selected_rain"
      case .bg_music_origin:        imageStr = "sound_selected_origin"
      case .bg_music_spring:        imageStr = "sound_selected_spring"
      case .bg_music_ethereal:      imageStr = "sound_selected_ethereal"
    }
    return  UIImage(named: imageStr)
  }

  var title: String {
    switch self {
      case .bg_music_none:          return "Code.Bgmusic0"
      case .bg_music_dreamstate:    return "Code.Bgmusic1"
      case .bg_music_galaxy:        return "Code.Bgmusic2"
      case .bg_music_moon:          return "Code.Bgmusic3"
      case .bg_music_crystal:       return "Code.Bgmusic4"
      case .bg_music_rain:          return "Code.Bgmusic5"
      case .bg_music_origin:        return "Code.Bgmusic6"
      case .bg_music_spring:        return "Code.Bgmusic7"
      case .bg_music_ethereal:      return "Code.Bgmusic8"
    }
  }

  var urlString: String? {
    switch self {
      case .bg_music_none:          return nil
      case .bg_music_dreamstate:    return "https://s.bongmi.cn/adhd/mp3/Dreamstate.mp3"
      case .bg_music_galaxy:        return "https://s.bongmi.cn/adhd/mp3/Galaxy.mp3"
      case .bg_music_moon:          return "https://s.bongmi.cn/adhd/mp3/Moon.mp3"
      case .bg_music_crystal:       return "https://s.bongmi.cn/adhd/mp3/crystal.mp3"
      case .bg_music_rain:          return "https://s.bongmi.cn/adhd/mp3/rain.mp3"
      case .bg_music_origin:        return "https://s.bongmi.cn/adhd/mp3/source.mp3"
      case .bg_music_spring:        return "https://s.bongmi.cn/adhd/mp3/spring.mp3"
      case .bg_music_ethereal:      return "https://s.bongmi.cn/adhd/mp3/vacancy.mp3"
    }
  }
}


enum FingerFlowPressState {
  case inside, outside, none
}
enum FingerFlowPropmptType {
  case place, keep, welldone, completing

  var localizedText: String {
    switch self {
      case .place:      return "Code.FingerflowPrimeText"
      case .keep:       return "Code.FingerflowBeforetrainingText1"
      case .welldone:   return "Code.FingerflowTrainingText1"
      case .completing: return "Code.FingerflowEndingText1"
    }
  }
}

enum FingerFlowTimerType {
  case game, preparation, pause
}
