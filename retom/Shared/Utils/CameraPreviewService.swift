// File: Shared/Utils/CameraPreviewService.swift
import Foundation
import AVFoundation

/// カメラのプレビュー専用サービス
final class CameraPreviewService: ObservableObject {

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "retom.camera.session.queue")
    private var isConfigured = false

    // MARK: - Public

    func start() {
        sessionQueue.async {
            // まだ設定してなければ一度だけ構成
            if !self.isConfigured {
                self.configureSession()
            }

            // 設定が成功していて、まだ走っていなければ start
            if self.isConfigured, !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - Private

    private func configureSession() {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        session.sessionPreset = .photo

        // デバイス取得（背面広角カメラ）
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            #if DEBUG
            print("⚠️ CameraPreviewService: カメラデバイスが見つかりません")
            #endif
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                #if DEBUG
                print("⚠️ CameraPreviewService: 入力をセッションに追加できません")
                #endif
                return
            }
        } catch {
            #if DEBUG
            print("❌ CameraPreviewService: Camera input error: \(error)")
            #endif
            return
        }

        // ここまで来たら構成完了
        isConfigured = true
    }
}
