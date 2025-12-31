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

    private var isConfigured = false

    /// 撮影完了時に UIImage を受け取るためのコールバック
    var onPhotoCapture: ((UIImage) -> Void)?
    /// 何らかのエラーが発生したときに通知するコールバック
    var onError: ((CameraServiceError) -> Void)?

    override init() {
        super.init()
    }

    /// カメラの入出力をセットアップ
    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

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
            DispatchQueue.main.async {
                self.onError?(.deviceUnavailable)
            }
            return
        }
        session.addInput(input)

        // 出力（静止画）
        guard session.canAddOutput(photoOutput) else {
            #if DEBUG
            print("❌ PhotoOutput を追加できません")
            #endif
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.onError?(.outputUnavailable)
            }
            return
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true

        session.commitConfiguration()
        isConfigured = true
    }

    // MARK: - セッション制御

    func startSession() {
        sessionQueue.async {
            self.configureSessionIfNeeded()

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
        sessionQueue.async {
            self.configureSessionIfNeeded()

            guard self.isConfigured else {
                DispatchQueue.main.async {
                    self.onError?(.notConfigured)
                }
                return
            }

            let settings = AVCapturePhotoSettings()

            // フラッシュ自動（対応していれば）
            if self.photoOutput.supportedFlashModes.contains(.auto) {
                settings.flashMode = .auto
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
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
            DispatchQueue.main.async {
                self.onError?(.captureFailed(error))
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            #if DEBUG
            print("❌ 画像データを取得できません")
            #endif
            DispatchQueue.main.async {
                self.onError?(.imageProcessingFailed)
            }
            return
        }

        DispatchQueue.main.async {
            self.onPhotoCapture?(image)
        }
    }
}

// MARK: - CameraServiceError

enum CameraServiceError: LocalizedError {
    case deviceUnavailable
    case outputUnavailable
    case notConfigured
    case captureFailed(Error)
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            return "カメラデバイスを初期化できませんでした。"
        case .outputUnavailable:
            return "撮影出力の初期化に失敗しました。"
        case .notConfigured:
            return "カメラの準備が完了していません。"
        case .captureFailed(let error):
            return "撮影に失敗しました: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "撮影した画像を取得できませんでした。"
        }
    }
}
