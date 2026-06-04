// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

import AudioToolbox
import Reusable
import SnapKit
import UIKit

fileprivate let RulerLineColor            = UIColor.white
fileprivate let RulerGap: CGFloat         = 14

protocol FingerFlowTimePickerDelegate:NSObjectProtocol {
  func didValueChanged(_ value: Int)
}

class FingerFlowTimePicker: UIView {
  private weak var delegate:FingerFlowTimePickerDelegate?
  private var stepNum = 0 //分多少个大区
  private var currentValue:Int = 0 {
    didSet {
      guard currentValue != oldValue else {
        return
      }
      delegate?.didValueChanged(currentValue)
    }
  }

  private var minValue: Int = 0
  private var maxValue: Int = 0

  init(defaultValue: Int,
       minValue:Int,
       maxValue:Int,
       delegate: FingerFlowTimePickerDelegate?) {
    super.init(frame: .zero)

    self.delegate = delegate
    self.currentValue = defaultValue
    self.minValue     = minValue
    self.maxValue     = maxValue
    self.stepNum      = maxValue - minValue

    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    collectionView.setContentOffset(CGPoint.init(x: (currentValue - minValue) * Int(RulerGap),
                                                 y: 0),
                                      animated: true)
  }

  // MARK: - lazy
  private lazy var valueLabel = {
    let valueLabel = UILabel()

    valueLabel.textColor = UIColor.white.withAlphaComponent(0.8)
    valueLabel.font = UIFont.systemFont(ofSize: 34, weight: .semibold)
    return valueLabel
  }()

  private lazy var unitLabel = {
    let unitLabel = UILabel()

    unitLabel.textColor = UIColor.white.withAlphaComponent(0.8)
    unitLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    unitLabel.text = "选择时间"
    unitLabel.restorationIdentifier = "Code.FingerflowPrimeMin"
    return unitLabel
  }()

  private lazy var collectionView: UICollectionView = {
    let flowLayout              = UICollectionViewFlowLayout()
    flowLayout.scrollDirection  = .horizontal
    flowLayout.sectionInset     = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    let collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: flowLayout)
    collectionView.backgroundColor = .clear
    collectionView.bounces = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator   = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(UICollectionViewCell.self,
                            forCellWithReuseIdentifier: "UICollectionViewCell")
    collectionView.register(FingerFlowSingleCell.self,
                            forCellWithReuseIdentifier: "FingerFlowSingleCell")

    return collectionView
  }()

  private lazy var chosenLine = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    return view
  }()
}

private extension FingerFlowTimePicker {
  func setupViews() {
    backgroundColor = .clear
    valueLabel.text = "\(currentValue)"

    self.addSubview(valueLabel)

    valueLabel.snp.makeConstraints { make in
      make.centerX.top.equalToSuperview()
    
    }

    self.addSubview(unitLabel)

    unitLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(valueLabel.snp.bottom).offset(5)
    
    }

    self.addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(unitLabel.snp.bottom)
    
    }
    
    self.addSubview(chosenLine)
    
    chosenLine.snp.makeConstraints { make in
      make.centerX.bottom.equalToSuperview()
      make.width.equalTo(1.5)
      make.height.equalTo(22)
        
    }
  }

  func setOffsetValueAndAnimated(offsetValue:Int,
                                 animated:Bool){
    currentValue = offsetValue + minValue
    valueLabel.text = "\(currentValue)"
    collectionView.setContentOffset(CGPoint(x: CGFloat(offsetValue) * RulerGap,
                                                y: 0),
                                    animated: animated)
  }
}

// MARK: - collection view
extension FingerFlowTimePicker : UICollectionViewDataSource,
                                  UICollectionViewDelegate,
                                 UICollectionViewDelegateFlowLayout {
  // UICollectionViewDataSource
  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return stepNum + 2
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.item != 0 else {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell",
                                                    for: indexPath)
      cell.backgroundColor = .clear
    return cell
    }
    return collectionView.dequeueReusableCell(for: indexPath,
                                              cellType: FingerFlowSingleCell.self)
  }

  // UICollectionViewDelegate
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offsetValue = Int(scrollView.contentOffset.x / RulerGap)
    let totalValue = offsetValue + minValue

    var newText = ""
    if totalValue >= maxValue {
      newText = "\(maxValue)"
    } else if totalValue <= minValue {
      newText = "\(minValue)"
    } else {
      newText = "\(totalValue)"
    }

    if newText != valueLabel.text {
      AudioServicesPlaySystemSound(1519)
    }
    valueLabel.text = newText
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                willDecelerate decelerate: Bool) {
    guard !decelerate else {
      return
    }
    setOffsetValueAndAnimated(offsetValue: Int(scrollView.contentOffset.x / RulerGap),
                              animated: true)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    setOffsetValueAndAnimated(offsetValue: Int(scrollView.contentOffset.x / RulerGap),
                              animated: true)
  }

  // UICollectionViewDelegateFlowLayout
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    var width = RulerGap
    if indexPath.item == 0 || indexPath.item == stepNum + 1 {
      width = frame.size.width / 2
    }
    return CGSize(width: width,
                  height: 27)
  }
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}

class FingerFlowSingleCell: UICollectionViewCell, Reusable {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
  }

  override func draw(_ rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    context?.setLineWidth(0.5)
    context?.setLineCap(CGLineCap.butt)
    context?.setStrokeColor(UIColor.white.cgColor)
    context?.move(to: CGPoint(x: 0,
                              y: 27))
    context!.addLine(to: CGPoint(x: 0,
                                 y: 17))
    context!.strokePath()
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
