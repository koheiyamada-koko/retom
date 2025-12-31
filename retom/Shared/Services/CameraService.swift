// File: Shared/Services/CameraService.swift
import Foundation
import AVFoundation
import UIKit

/// 実機用のカメラ制御クラス（写真撮影＆プレビュー用）
final class CameraService: NSObject, ObservableObject {

    /// カメラプレビューに使うセッション
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()

    /// 撮影完了時に UIImage を受け取るためのコールバック
    var onPhotoCapture: ((UIImage) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    /// カメラの入出力をセットアップ
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // 入力（背面カメラ）
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            #if DEBUG
            print("❌ カメラインプットを追加できません")
            #endif
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // 出力（静止画）
        guard session.canAddOutput(photoOutput) else {
            #if DEBUG
            print("❌ PhotoOutput を追加できません")
            #endif
            session.commitConfiguration()
            return
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true

        session.commitConfiguration()
    }

    // MARK: - セッション制御

    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - 撮影

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()

        // フラッシュ自動（対応していれば）
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        if let error = error {
            #if DEBUG
            print("❌ 写真撮影に失敗: \(error)")
            #endif
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            #if DEBUG
            print("❌ 画像データを取得できません")
            #endif
            return
        }

        DispatchQueue.main.async {
            self.onPhotoCapture?(image)
        }
    }
}
