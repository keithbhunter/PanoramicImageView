//
//  ViewController.swift
//  PanoramicImageView
//
//  Created by Keith Hunter on 6/2/17.
//  Copyright © 2017 Keith Hunter. All rights reserved.
//

import CoreMotion
import UIKit

class ViewController: UIViewController {

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(panoramicView)
        panoramicView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        panoramicView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        panoramicView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        panoramicView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { deviceMotion, error in
                self.panoramicView.deviceMotion = deviceMotion
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
    }


    // MARK: - Properties

    private let motionManager: CMMotionManager = {
        let mm = CMMotionManager()
        mm.deviceMotionUpdateInterval = 1 / 60
        return mm
    }()

    private let panoramicView: PanoramicImageView = {
        let iv = PanoramicImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.showsStatistics = true
        iv.image = #imageLiteral(resourceName: "room.jpg")
        return iv
    }()

}

