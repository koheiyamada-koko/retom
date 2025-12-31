//
//  CameraViewModel.swift
//  retom
//
//  Created by kohei yamada on 2025/11/23.
//

import Foundation
import AVFoundation
import UIKit

class CameraViewModel: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // カメラデバイス取得
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
                #if DEBUG
                print("❌ カメラデバイス取得失敗")
                #endif
                return
            }

            // 入力
            guard let input = try? AVCaptureDeviceInput(device: device) else {
                #if DEBUG
                print("❌ カメラインプット失敗")
                #endif
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            // 出力
            let output = AVCapturePhotoOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
}
