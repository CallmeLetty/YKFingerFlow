// Copyright (c) 2023 年, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import RxSwift
import RxCocoa
import SnapKit
import SDWebImage
import UIKit
import AVFoundation

public class FingerFlowVC: UIViewController {
    let rxDisposeBag = DisposeBag()
    
    // for media extension
    var audioPlayer: AVAudioPlayer?
    var currentImage: FingerFlowBackgroundImage = .bg_pic1
    var currentMusic: FingerFlowBackgroundMusic = .bg_music_dreamstate
    var needToPlay: Bool = false
    
    // for game
    private(set) var duration: Double = 1 * 60 // default 1 min
    var gameState = FingerFlowState.before {
        didSet {
            guard gameState != oldValue else {
                return
            }
            _onStateUpdate()
        }
    }
    var isFinished = false
    
    var gameTimer: Timer?
    var pauseTimer: Timer?
    var pauseCountdownNumber = 5
    var pastDuration: TimeInterval = 0
    
    public init() {
        super.init(nibName: nil,
                   bundle: nil)
        self.checkChosenResource()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bindEvents()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var firstAppear = true
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if firstAppear {
            firstAppear = false

            gameView.resetToBefore()
            prepareAudioDataGroup()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTimer(.game)
        stopTimer(.pause)
    }
    
    // MARK: - lazy
    private(set) lazy var bgImageView = {
        let imageView = UIImageView()
        
        imageView.sd_setImage(with: URL(string: self.currentImage.imageUrlString))
        return imageView
    }()
    
    private(set) lazy var titleLabel = {
        let titleLabel = UILabel()
        
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = UIColor.white
        titleLabel.text = "Fingerflow挑战"
        titleLabel.numberOfLines = 0
        return titleLabel
    }()
    
    private(set) lazy var timePicker = FingerFlowTimePicker(defaultValue: Int(duration) / 60,
                                                            minValue: 1,
                                                            maxValue: 15,
                                                            delegate: self)
    
    private(set) lazy var musicIcon = {
        let imageView = UIImageView()
        
        imageView.image = UIImage(named: "fingerflow_music_icon")
        imageView.contentMode = .center
        return imageView
    }()
    
    private(set) lazy var imageIcon = {
        let imageView = UIImageView()
        
        imageView.image = UIImage(named: "fingerflow_picture_icon")
        imageView.contentMode = .center
        return imageView
    }()
    
    private(set) lazy var resourcePicker = {
        let view = FingerFlowResourcePicker(delegate: self)
        view.isHidden = true
        return view
    }()
    
    private(set) lazy var gameView = FingerFlowGameView(frame: view.bounds,
                                                        duration: self.duration,
                                                        delegate: self)
}

// MARK: - private
private extension FingerFlowVC {
    func bindEvents() {
        musicIcon.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] _ in
            guard let self = self else {
                return
            }
            var musicValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgMusic) ?? 2
            if musicValue == 0 {
                musicValue = 2
            }
            let music = FingerFlowBackgroundMusic(rawValue: musicValue) ?? .bg_music_dreamstate
            self.resourcePicker.openWithType(.music(selected: music))
            self.prepareAudio(music)
            self.audioPlayer?.play()
        }).disposed(by: rxDisposeBag)
        
        imageIcon.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] _ in
            guard let self = self else {
                return
            }
            var imageValue = AppManager.shared.userDiskCache?.getInt(for: KVCacheKey.fingerFlowBgImage) ?? 1
            if imageValue == 0 {
                imageValue = 1
            }
            let image = FingerFlowBackgroundImage(rawValue: imageValue) ?? .bg_pic1
            self.resourcePicker.openWithType(.image(selected: image))
        }).disposed(by: rxDisposeBag)
        
        // 前后台切换处理游戏状态+音频
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else {
                    return
                }
                if self.gameState.isRunning {
                    self.gameState = .pauseCountdown
                } else if self.gameState == .preparation {
                    self.gameState = .before
                }
                
                if let audio = self.audioPlayer,
                   audio.isPlaying {
                    audio.pause()
                    self.needToPlay = true
                }
            }).disposed(by: rxDisposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else {
                    return
                }
                if let audio = self.audioPlayer,
                   self.needToPlay {
                    audio.play()
                    self.needToPlay = false
                }
            }).disposed(by: rxDisposeBag)
    }
    
    func setupViews() {
        view.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(35 + FrameGuide.safeAreaBottomHeight)
            make.left.equalToSuperview().offset(20)
            
        }
        
        view.addSubview(gameView)
        
        gameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            
        }
        
        view.addSubview(timePicker)
        
        timePicker.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(77)
            make.left.right.equalToSuperview()
            make.height.equalTo(91)
            
        }
        
        view.addSubview(musicIcon)
        
        musicIcon.snp.makeConstraints { make in
            make.bottom.equalTo(-44-FrameGuide.safeAreaBottomHeight)
            make.width.height.equalTo(40)
            make.left.equalTo(65)
            
        }
        
        view.addSubview(imageIcon)
        
        imageIcon.snp.makeConstraints { make in
            make.bottom.width.height.equalTo(musicIcon)
            make.right.equalTo(-65)
            
        }
        
        view.addSubview(resourcePicker)
        
        resourcePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            
        }
    }
}

extension FingerFlowVC: FingerFlowTimePickerDelegate {
    func didValueChanged(_ value: Int) {
        duration = Double(value * 60)
        gameView.updateDuration(duration)
    }
}
