// File: Shared/Views/CameraPreviewView.swift
import SwiftUI
import AVFoundation

/// AVCaptureSession を使ってカメラ映像を表示する SwiftUI ラッパー
struct CameraPreviewView: UIViewRepresentable {

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black

        let previewLayer = view.videoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        updateOrientation(for: previewLayer)

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 端末の回転やサイズ変更に合わせてレイヤーのサイズも更新
        uiView.videoPreviewLayer.frame = uiView.bounds
        updateOrientation(for: uiView.videoPreviewLayer)
    }

    private func updateOrientation(for layer: AVCaptureVideoPreviewLayer) {
        guard let connection = layer.connection,
              connection.isVideoOrientationSupported else { return }

        let orientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) ?? .portrait
        connection.videoOrientation = orientation
    }
}

private extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait, .faceUp, .faceDown, .unknown:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        @unknown default:
            return nil
        }
    }
}
