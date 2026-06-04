// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMUserBusinessLib
import AVFoundation
import UIKit
import Reusable
import SnapKit
import RxSwift
import RxCocoa

protocol FingerFlowResourcePickerDelegate: NSObjectProtocol {
  func onCancelingSelection(_ resourceType: FingerFlowResourcePicker.ResourceType)
  func onSelecting(_ resourceType: FingerFlowResourcePicker.ResourceType)
  func onConfirm(_ resourceType: FingerFlowResourcePicker.ResourceType)
}

class FingerFlowResourcePicker: UIView {
  enum ResourceType {
    case music(selected: FingerFlowBackgroundMusic)
    case image(selected: FingerFlowBackgroundImage)
  }

    private let rxDisposeBag = DisposeBag()
  private var currentResource = ResourceType.music(selected: .bg_music_dreamstate)

  private var audioPlayer: AVAudioPlayer?
  private weak var delegate: FingerFlowResourcePickerDelegate?

  init(delegate: FingerFlowResourcePickerDelegate?) {
    self.delegate = delegate

    super.init(frame: .zero)

    setupViews()
    bindEvents()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func openWithType(_ resourceType: ResourceType) {
    isHidden = false
    currentResource = resourceType

    switch resourceType {
      case .image(let selected):
        musicScrollView.isHidden = true
        imageScrollView.isHidden = false

        let height = 291 + FrameGuide.safeAreaBottomHeight
        bgView.snp.updateConstraints { make in
          make.height.equalTo(height)
        }

        bgView.transform = CGAffineTransform(translationX: 0,
                                             y: height)
        UIView.animate(withDuration: 0.25) { [weak self] in
          self?.bgView.transform = CGAffineTransform(translationX: 0,
                                                     y: 0)

        } completion: { [weak self] flag in
          let offset = CGPoint(x: selected.index * 75,
                               y: 0)
          self?.imageScrollView.setContentOffset(offset,
                                                 animated: true)
          if let cell = self?.imageStackView.arrangedSubviews[selected.index] as? FingerFlowImagePickerCell {
            self?.imageStackView.unhighlightAll()
            cell.highlighted = true
          }
        }
      case .music(let selected):
        imageScrollView.isHidden = true
        musicScrollView.isHidden = false

        let height = 206.5 + FrameGuide.safeAreaBottomHeight
        bgView.snp.updateConstraints { make in
          make.height.equalTo(height)
        }

        bgView.transform = CGAffineTransform(translationX: 0,
                                             y: height)
        UIView.animate(withDuration: 0.25) { [weak self] in
          self?.bgView.transform = CGAffineTransform(translationX: 0,
                                                     y: 0)
        } completion: { [weak self] flag in
          let offset = CGPoint(x: CGFloat(selected.index) * 75,
                               y: 0)
          self?.musicScrollView.setContentOffset(offset,
                                                 animated: true)
          if let cell = self?.musicStackView.arrangedSubviews[selected.index] as? FingerFlowMusicPickerCell {
            self?.musicStackView.unhighlightAll()
            cell.highlighted = true
          }
        }
    }
  }

  // MARK: - lazy
  private lazy var shadowView = {
    let view = UIView()

    view.backgroundColor = .black.withAlphaComponent(0.75)
    return view
  }()

  private lazy var bgView = {
    let view = UIView()

    view.backgroundColor = UIColor(hexString: "#1F233D")
    return view
  }()

  private lazy var musicStackView = {
    let stackView = UIStackView()

    stackView.axis = .horizontal
    stackView.spacing = 5

    for music in FingerFlowBackgroundMusic.allCases {
      let view = FingerFlowMusicPickerCell(type: music)
      let gesture = UITapGestureRecognizer(target: self,
                                           action: #selector(onClickCell(_:)))
      view.addGestureRecognizer(gesture)
      stackView.addArrangedSubview(view)
    }
    return stackView
  }()

  private lazy var imageStackView = {
    let stackView = UIStackView()

    stackView.axis = .horizontal
    stackView.spacing = 30

    for image in FingerFlowBackgroundImage.allCases {
      let view = FingerFlowImagePickerCell(type: image)
      let gesture = UITapGestureRecognizer(target: self,
                                           action: #selector(onClickCell(_:)))
      view.addGestureRecognizer(gesture)
      stackView.addArrangedSubview(view)
    }
    return stackView
  }()

  private lazy var musicScrollView = {
    let scrollView = UIScrollView()

    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.bounces = false
    scrollView.contentSize.height = 0
    return scrollView
  }()

  private lazy var imageScrollView = {
    let scrollView = UIScrollView()

    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.bounces = false
    scrollView.contentSize.height = 0
    return scrollView
  }()

  private lazy var confirmButton = {
    let button = UIButton()

    button.setTitle("Code.ButtonConfirm",
                         for: .normal)
      button.layer.cornerRadius = 29
    button.backgroundColor = UIColor.blue
    button.setTitleColor(UIColor(hexString: "131C41"),
                     for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    return button
  }()
}

private extension FingerFlowResourcePicker {
  @objc func onClickCell(_ sender: UITapGestureRecognizer) {
    if let imageCell = sender.view as? FingerFlowImagePickerCell {
      imageStackView.unhighlightAll()
      imageCell.highlighted = true
      currentResource = .image(selected: imageCell.type)
    }

    if let musicCell = sender.view as? FingerFlowMusicPickerCell {
      musicStackView.unhighlightAll()
      musicCell.highlighted = true
      currentResource = .music(selected: musicCell.type)
    }

    delegate?.onSelecting(currentResource)
  }

  func bindEvents() {
    shadowView.rx.tapGesture()
      .when(.recognized)
      .subscribe(onNext: { [weak self] _ in
        self?.disappearAnimate(cancel: true)
      })
      .disposed(by: rxDisposeBag)

    confirmButton.rx.tap
      .subscribe(onNext: { [weak self] _ in
        self?.disappearAnimate(cancel: false)
      })
      .disposed(by: rxDisposeBag)
  }

  func setupViews() {
    self.addSubview(shadowView)
    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        }

    self.addSubview(bgView)

    bgView.snp.makeConstraints { make in
      make.bottom.left.right.equalToSuperview()
      make.height.equalTo(291 + FrameGuide.safeAreaBottomHeight)
    
    }

    bgView.addSubview(musicScrollView)

    musicScrollView.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.equalTo(26)
      make.height.equalTo(53.5)
    
    }

    musicScrollView.addSubview(musicStackView)

    musicStackView.snp.makeConstraints { make in
      make.edges.equalTo(UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
      make.height.equalToSuperview()
    
    }

    bgView.addSubview(imageScrollView)

    imageScrollView.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.equalTo(28.5)
      make.height.equalTo(136)
    
    }

    imageScrollView.addSubview(imageStackView)

    imageStackView.snp.makeConstraints { make in
      make.edges.equalTo(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
      make.height.equalToSuperview()
    
    }

    bgView.addSubview(confirmButton)

    confirmButton.snp.makeConstraints { make in
      make.bottom.equalTo(-20-FrameGuide.safeAreaBottomHeight)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(58)
    
    }
  }

  func disappearAnimate(cancel: Bool) {
    let viewHeight = bounds.height
    UIView.animate(withDuration: 0.25) { [weak self] in
      self?.bgView.transform = CGAffineTransform(translationX: 0,
                                                 y: viewHeight)
    } completion: { [weak self] flag in
      guard let self = self else {
        return
      }
      if cancel {
        self.delegate?.onCancelingSelection(self.currentResource)
      } else {
        self.delegate?.onConfirm(self.currentResource)
      }
      self.isHidden = true
    }
  }
}

class FingerFlowMusicPickerCell: UIView, Reusable {
  private(set) var type: FingerFlowBackgroundMusic

  var highlighted: Bool = false {
    didSet {
      title.textColor = self.highlighted ? UIColor.blue : UIColor.black.withAlphaComponent(0.8)
      icon.image = self.highlighted ? type.highlightImage : type.normalImage
    }
  }

  init(type: FingerFlowBackgroundMusic) {
    self.type = type

    super.init(frame: .zero)

    setupViews()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 75, height: 53.5)
  }

  // MARK: - lazy
  private lazy var icon = UIImageView(image: self.type.normalImage)
  private lazy var title = {
    let label = UILabel()

    label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    label.textColor = UIColor.black.withAlphaComponent(0.8)
    label.textAlignment = .center
    label.text = self.type.title
    label.numberOfLines = 0
    return label
  }()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    self.addSubview(icon)
    icon.snp.makeConstraints { make in
      make.top.centerX.equalToSuperview()
      make.width.height.equalTo(34)
        }

    self.addSubview(title)

    title.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.bottom.equalTo(-1)
    
    }
  }
}

class FingerFlowImagePickerCell: UIView {
  private(set) var type: FingerFlowBackgroundImage

  var highlighted: Bool = false {
    didSet {
      thumbnailImage.layerBorderColor = self.highlighted ? UIColor.blue : .clear
    }
  }

  init(type: FingerFlowBackgroundImage) {
    self.type = type
    
    super.init(frame: .zero)

    setupViews()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 78, height: 136)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

    // MARK: - lazy
  private lazy var thumbnailImage = {
    let imageView = UIImageView()

    imageView.layerBorderWidth = 1.5
    imageView.layerBorderColor = .clear
    imageView.layerCornerRadius = 8
    imageView.sd_setImage(with: URL(string: self.type.imageUrlString))
    return imageView
  }()

  private func setupViews() {
    self.addSubview(thumbnailImage)
    thumbnailImage.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
      make.width.equalTo(75)
      make.height.equalTo(133)
        }
  }
}
