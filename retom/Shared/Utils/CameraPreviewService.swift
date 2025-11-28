// File: Shared/Utils/CameraPreviewService.swift

import Foundation
import AVFoundation
import UIKit

final class CameraPreviewService: NSObject, ObservableObject {

    // 実際のカメラ映像を映すための AVCaptureSession
    let session = AVCaptureSession()

    // カメラの画質プリセット
    private let preset: AVCaptureSession.Preset = .photo

    override init() {
        super.init()

        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = preset

        // 背面カメラを使う
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: camera)
        else {
            print("❌ カメラデバイス取得失敗")
            return
        }

        // Session に追加
        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()
    }

    /// カメラ開始
    func start() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    /// カメラ停止
    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

