//
//  ViewController.swift
//  YKFingerFlow
//
//  Created by Yakamoz on 2026/6/4.
//

import SnapKit
import UIKit

class ViewController: UIViewController {

    private lazy var enterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("进入 Finger Flow", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(enterFingerFlowTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue.withAlphaComponent(0.5)
        return button
    }()
    private lazy var enterButton2: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("进入 New Finger Flow", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(enterNewFingerFlowTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemPink.withAlphaComponent(0.5)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "YKFingerFlow"
        
        view.addSubview(enterButton)
        view.addSubview(enterButton2)
        
        enterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
            make.size.equalTo(CGSizeMake(200, 50))
        }
        
        enterButton2.snp.makeConstraints { make in
            make.centerX.size.equalTo(enterButton)
            make.top.equalTo(enterButton.snp.bottom).offset(20)
        }
    }


    @objc private func enterFingerFlowTapped() {
        let fingerFlowVC = FingerFlowVC()
        navigationController?.pushViewController(fingerFlowVC, animated: true)
    }
    @objc private func enterNewFingerFlowTapped() {
        let fingerFlowVC = NewFingerFlowViewController()
        navigationController?.pushViewController(fingerFlowVC, animated: true)
    }

}
