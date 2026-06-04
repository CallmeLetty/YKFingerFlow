//
//  ViewController.swift
//  YKFingerFlow
//
//  Created by Yakamoz on 2026/6/4.
//

import UIKit

class ViewController: UIViewController {

    private lazy var enterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("进入 Finger Flow", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(enterFingerFlowTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "YKFingerFlow"
        setupButton()
    }

    private func setupButton() {
        view.addSubview(enterButton)
        NSLayoutConstraint.activate([
            enterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func enterFingerFlowTapped() {
        let fingerFlowVC = FingerFlowVC()
        navigationController?.pushViewController(fingerFlowVC, animated: true)
    }

}
