// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 24) {

            // MARK: - タイトル
            VStack(spacing: 6) {
                Text("カメラ")
                    .font(.system(size: 32, weight: .bold))

                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("retom カメラ")
                        .font(.system(size: 20, weight: .semibold))
                }

                Text("保存されている写真：\(appState.photos.count)枚")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 32)

            Spacer()

            // MARK: - プレビュー領域（仮）
            Rectangle()
                .fill(Color.black.opacity(0.85))
                .frame(
                    width: UIScreen.main.bounds.width * 0.85,
                    height: UIScreen.main.bounds.height * 0.35
                )
                .cornerRadius(16)
                .shadow(radius: 8)
                .overlay(
                    Text("Camera Preview")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 18))
                )

            Spacer()

            // MARK: - シャッターボタン
            Button {
                showPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                        .shadow(radius: 6)

                    Circle()
                        .stroke(Color.black.opacity(0.15), lineWidth: 6)
                        .frame(width: 88, height: 88)
                }
            }
            .padding(.bottom, 36)
        }
        .sheet(isPresented: $showPicker) {
            // ⭐️ ここが今回のキモ。from: .camera を明示して init と一致させる
            CameraPicker(
                from: .camera,
                onImagePicked: { uiImage in
                    guard let image = uiImage else { return }
                    appState.addPhoto(from: image)
                }
            )
        }
    }
}

