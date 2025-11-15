// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState

    /// カメラ画面を出すかどうか
    @State private var isCameraPresented = false
    /// 撮影直後の「保存中…」表示用
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("📷 retom カメラ")
                    .font(.title2)
                    .bold()

                Text("保存されている写真：\(appState.photos.count)枚")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // ===== シャッターボタン =====
                Button {
                    isCameraPresented = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 110, height: 110)

                        Circle()
                            .fill(isSaving ? .red.opacity(0.8) : .white)
                            .frame(width: 82, height: 82)
                            .shadow(radius: 6)

                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("シャッターボタン")

                if isSaving {
                    Text("保存中…")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("カメラ")
        }
        // フルスクリーンでカメラを表示
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { image in
                // 撮影 or フォトライブラリから取得した画像がここにくる
                isSaving = true
                appState.addPhoto(from: image)
                // ちょっとだけ「保存中」を見せる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSaving = false
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState.shared)
}
