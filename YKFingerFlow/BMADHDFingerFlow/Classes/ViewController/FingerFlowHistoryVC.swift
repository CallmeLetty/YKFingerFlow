// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com

//import BMUserBusinessLib
//import BMBaseWidgetLib
//import BMADHDUIKit
//import UIComponent
//import BMSensors

import SnapKit
import RxSwift
import RxCocoa

public class FingerFlowHistoryVC: BaseViewController {
  private let rxDisposeBag = DisposeBag()
  private var curPage = 0

  private lazy var shareUtil = FingerFloweShareUtil()
  private var history: FingerFlowHistoryVM? {
    didSet {
      updateUIWithHistory()
    }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    setupBaseViews()
    fetchData(page: curPage)
  }

  public override var isHiddenNavigationBar: Bool? {
    return true
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: lazy
  private lazy var titleLabel = {
    let titleLabel = UILabel()

    titleLabel.textColor = UIColor.black
    titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    titleLabel.text = "Code.SchulteHistory"
    return titleLabel
  }()

  private var backButton: UIButton!

  private lazy var noHistoryImageView = UIImageView(image: Bundle.bmftCommon_IMG("history_no_img"))
  private lazy var noHistoryLabel = {
    let noHistoryLabel = UILabel()

    noHistoryLabel.textColor = UIColor.black.withAlphaComponent(0.8)
    noHistoryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    noHistoryLabel.text = "Code.SchulteHistoryEmpty"
    return noHistoryLabel
  }()

  private lazy var historyBgImageView = UIImageView(image: Bundle.bmftCommon_IMG("gamesresult_bg"))

  private lazy var bestBgImageView = UIImageView(image: Bundle.bmftCommon_IMG("gamesresult_win_img"))

  private lazy var bestLabel = {
    let bestLabel = UILabel()

    bestLabel.textColor = BMThemeManager.sharedInstance().theme.normalContentColor()
    bestLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
    bestLabel.text = "Code.SchulteBest1"
    return bestLabel
  }()

  private lazy var bestRecordLabel = {
    let bestRecordLabel = UILabel()

    bestRecordLabel.textColor = UIColor.black
    bestRecordLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
    return bestRecordLabel
  }()

  private lazy var bestRecordTimeLabel = {
    let bestRecordTimeLabel = UILabel()

    bestRecordTimeLabel.textColor = UIColor.black.withAlphaComponent(0.6)
    bestRecordTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    return bestRecordTimeLabel
  }()

  private lazy var listTable = {
    let tableView = UITableView()

    tableView.separatorStyle = .none
    tableView.backgroundColor = .clear
    tableView.register(FingerFlowHistoryCell.self,
                forCellReuseIdentifier: FingerFlowHistoryCell.className)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.mj_footer = BMADHDRefreshFooter(refreshingBlock: onFooterAction)
    return tableView
  }()
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension FingerFlowHistoryVC: UITableViewDataSource, UITableViewDelegate {
  // UITableViewDataSource
  public func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return history?.list.count ?? 0
  }

  public func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath,
                                             cellType: FingerFlowHistoryCell.self)
    guard let history = history,
          history.list.count > indexPath.item else {
      return cell
    }
    let result = history.list[indexPath.item]

    cell.durationLabel.text = TimeInterval(result.duration.floatValue).toSecondTimeString()
    cell.timeLabel.text = TimeInterval(result.createTime.floatValue).toDateString()
    return cell
  }

  // UITableViewDelegate
  public func tableView(_ tableView: UITableView,
                        didSelectRowAt indexPath: IndexPath) {

    guard let vm = history?.list[indexPath.item],
          let imageUrlString = vm.imageUrl else {
      return
    }
    openShareView(imageUrlString: imageUrlString)
  }
}

private extension FingerFlowHistoryVC {
  func openShareView(imageUrlString: String) {
    view.showLoading()
    shareUtil.image(imageUrlString: imageUrlString) { [weak self] shareImage in
      self?.view.hideLoading()
      guard let self = self,
            let shareImage = shareImage else {
        return
      }

      let shareView = FingerFlowHistoryShareView(image: shareImage) { [weak self] in
        self?.share(shareImage: shareImage)
      }

      self.view.addSubview(shareView)

      shareView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      
      }
    }
  }

  func share(shareImage: UIImage) {
      UINavigationBar.appearance().isTranslucent = false
      UINavigationBar.appearance().barTintColor = UIColor.blue

      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }

        let textItem = FingerFloweShareUtil().text()
        let imageItem = FingerFlowShareImageProvider(shareImage: shareImage)
        let urlItem = FingerFlowShareURLProvider()
        let vc = UIActivityViewController(activityItems: [textItem, imageItem, urlItem],
                                          applicationActivities: nil)

        self.view.hud.hideLoading()
        vc.popoverPresentationController?.sourceRect = CGRect(x: FrameGuide.screenWidth / 2,
                                                              y: FrameGuide.screenHeight - 70,
                                                              width: 1,
                                                              height: 1)
        vc.popoverPresentationController?.sourceView = self.view
        vc.popoverPresentationController?.permittedArrowDirections = .down

        self.presentVC(vc)
      }
  }

  func onFooterAction() {
    fetchData(page: curPage + 1)
  }

  func updateUIWithHistory() {
    guard let history = history,
          history.list.count > 0 else {
      return
    }
    noHistoryImageView.isHidden = true
    noHistoryLabel.isHidden = true

    for view in [historyBgImageView, bestBgImageView, bestLabel, bestRecordLabel, bestRecordTimeLabel, listTable] {
      view.isHidden = false
    }

    listTable.reloadData()

    bestRecordLabel.text = history.best.duration.toSecondTimeString()
    bestRecordTimeLabel.text = TimeInterval(history.best.createTime.floatValue).toDateString()
  }

  func fetchData(page: Int) {
    let api = FingerFlowHistoryListTask(page_no: page)
    api.observable.bindLoading(at: view)
      .subscribe(onNext: {[weak self] response in

        self?.listTable.mj_footer?.endRefreshing()
        guard response.isSucceed else {
          UIWindow.realTopMost().bmt_makeToast("Code.SchulteHistoryFailed")
          return
        }

        guard let data = response.data,
              let history = data.toFFResultList() else {
          return
        }
        self?.curPage = page

        let list: [FingerFlowSingleHistoryVM] = (self?.history?.list ?? []) + history.list

        self?.history = FingerFlowHistoryVM(best: history.best,
                                            list: list)
      })
      .disposed(by: rxDisposeBag)
  }

  func setupBaseViews() {
    view.backgroundColor = ColorGuide.normalBackground
    let backImg = Bundle.bmftCommon_IMG("nav_back_icon")
    backButton = addBackButtonAtView(image: backImg,
                                     extraAction: { [weak self] in
      self?.onCompletion?(nil)
    })

    backButton.snp.remakeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.top.equalToSuperview().offset(FrameGuide.statusBarHeight)
      make.width.height.equalTo(34)
    }

    view.addSubview(titleLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalTo(backButton)
    
    }

    view.addSubview(noHistoryImageView)

    noHistoryImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(166.5)
    
    }

    view.addSubview(noHistoryLabel)

    noHistoryLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(noHistoryImageView.snp.bottom).offset(20)
    
    }

    // hidden
    view.addSubview(historyBgImageView)
    historyBgImageView.snp.makeConstraints { make in
      make.centerX.width.equalToSuperview()
      make.top.equalTo(UIDevice.isIPhoneXSeries ? 0 : -24)
        }

    view.addSubview(bestBgImageView)

    bestBgImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(43)
    
    }

    view.addSubview(bestLabel)

    bestLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(bestBgImageView).offset(2)
    
    }

    view.addSubview(bestRecordLabel)

    bestRecordLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(bestBgImageView.snp.bottom).offset(20)
    
    }

    view.addSubview(bestRecordTimeLabel)

    bestRecordTimeLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(bestRecordLabel.snp.bottom).offset(5)
    
    }

    view.addSubview(listTable)

    listTable.snp.makeConstraints { make in
      make.centerX.left.right.bottom.equalToSuperview()
      make.top.equalTo(historyBgImageView.snp.bottom)
    
    }

    for view in [historyBgImageView, bestBgImageView, bestLabel, bestRecordLabel, bestRecordTimeLabel, listTable] {
      view.isHidden = true
    }
    
    view.bringSubviewToFront(backButton)
    view.bringSubviewToFront(titleLabel)
  }
}
