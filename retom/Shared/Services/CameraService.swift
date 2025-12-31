// File: Shared/Services/CameraService.swift
import Foundation
import AVFoundation
import UIKit

/// 実機用のカメラ制御クラス（写真撮影＆プレビュー用）
final class CameraService: NSObject, ObservableObject {

    /// カメラプレビューに使うセッション
    let session = AVCaptureSession()
    /// カメラ権限の状態
    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

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

    // MARK: - 権限

    func refreshAuthorizationStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if Thread.isMainThread {
            authorizationStatus = status
        } else {
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                completion(granted)
            }
        }
    }

    /// カメラの入出力をセットアップ
    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        session.sessionPreset = .photo

        // 入力（背面カメラ）
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else {
            #if DEBUG
            print("❌ カメラデバイスを取得できません")
            #endif
            DispatchQueue.main.async {
                self.onError?(.deviceUnavailable)
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                #if DEBUG
                print("❌ カメラインプットを追加できません")
                #endif
                DispatchQueue.main.async {
                    self.onError?(.inputUnavailable)
                }
                return
            }
            session.addInput(input)
        } catch {
            #if DEBUG
            print("❌ カメラインプット作成に失敗: \(error)")
            #endif
            DispatchQueue.main.async {
                self.onError?(.inputUnavailable)
            }
            return
        }

        // 出力（静止画）
        guard session.canAddOutput(photoOutput) else {
            #if DEBUG
            print("❌ PhotoOutput を追加できません")
            #endif
            DispatchQueue.main.async {
                self.onError?(.outputUnavailable)
            }
            return
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality

        isConfigured = true
    }

    // MARK: - セッション制御

    func startSession() {
        sessionQueue.async {
            guard self.authorizationStatus == .authorized else {
                #if DEBUG
                print("⚠️ カメラ権限が許可されていないためセッションを開始できません")
                #endif
                return
            }

            self.configureSessionIfNeeded()

            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    #if DEBUG
                    if self.session.isRunning {
                        print("✅ カメラセッションを開始しました")
                    } else {
                        print("❌ カメラセッションの開始に失敗しました")
                    }
                    #endif
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    #if DEBUG
                    print("ℹ️ カメラセッションを停止しました")
                    #endif
                }
            }
        }
    }

    // MARK: - 撮影

    func capturePhoto() {
        sessionQueue.async {
            guard self.authorizationStatus == .authorized else {
                DispatchQueue.main.async {
                    self.onError?(.notAuthorized)
                }
                return
            }

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
    case inputUnavailable
    case outputUnavailable
    case notAuthorized
    case notConfigured
    case captureFailed(Error)
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            return "カメラを準備できませんでした。アプリを再起動してください。"
        case .inputUnavailable:
            return "カメラの準備に失敗しました。もう一度お試しください。"
        case .outputUnavailable:
            return "撮影の準備に失敗しました。もう一度お試しください。"
        case .notAuthorized:
            return "カメラへのアクセスが許可されていません。"
        case .notConfigured:
            return "カメラの準備が完了していません。"
        case .captureFailed:
            return "撮影に失敗しました。もう一度お試しください。"
        case .imageProcessingFailed:
            return "撮影した画像を取得できませんでした。"
        }
    }
}
