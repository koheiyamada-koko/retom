// File: Shared/Views/CameraView.swift
import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState

    // シミュレータと実機でプロパティを分岐
    #if targetEnvironment(simulator)
    @State private var showPicker = false
    #else
    @StateObject private var cameraService = CameraService()
    #endif

    var body: some View {
        #if targetEnvironment(simulator)
        // ============================
        // 🖥 シミュレータ用（フォトライブラリ）
        // ============================
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.90) // ほんのりベージュ
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    Text("カメラ")
                        .font(.largeTitle.bold())

                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                        Text("retom フィルムカメラ")
                            .font(.title3.bold())
                    }

                    Text("保存されている写真：\(appState.photos.count)枚")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)

                // 擬似プレビュー枠
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text("シミュレータでは\nフォトライブラリから選択")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    )
                    .frame(height: 280)
                    .padding(.horizontal, 32)
                    .shadow(radius: 20)

                Spacer()

                // シャッターボタン
                Button {
                    showPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 84, height: 84)
                        Circle()
                            .strokeBorder(.white.opacity(0.8), lineWidth: 4)
                            .frame(width: 96, height: 96)
                    }
                    .shadow(radius: 8)
                }

                Text("シャッター（フォトライブラリ）")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Spacer().frame(height: 40)
            }
        }
        .sheet(isPresented: $showPicker) {
            // ここは今まで通りの CameraPicker を利用
            CameraPicker(from: .library) { uiImage in
                guard let image = uiImage else { return }
                appState.addPhoto(from: image)
            }
        }

        #else
        // ============================
        // 📱 実機用（フルスクリーンカメラ）
        // ============================
        ZStack {
            // カメラプレビュー
            CameraPreviewLayerView(session: cameraService.session)
                .ignoresSafeArea()

            // 上下にUIをオーバーレイ
            VStack {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    Text("カメラ")
                        .font(.largeTitle.bold())

                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                        Text("retom フィルムカメラ")
                            .font(.title3.bold())
                    }

                    Text("保存されている写真：\(appState.photos.count)枚")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .foregroundColor(.white)
                .shadow(radius: 10)

                Spacer()

                // シャッターボタン
                Button {
                    cameraService.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 84, height: 84)
                        Circle()
                            .strokeBorder(.white.opacity(0.8), lineWidth: 4)
                            .frame(width: 96, height: 96)
                    }
                    .shadow(radius: 8)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 撮影完了時 → AppState に保存（レトロ＋日付付き）
            cameraService.onPhotoCapture = { image in
                appState.addPhoto(from: image)
            }
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        #endif
    }
}

// MARK: - 実機用プレビュービュー（AVCaptureVideoPreviewLayer）

#if !targetEnvironment(simulator)
private struct CameraPreviewLayerView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
#endif

