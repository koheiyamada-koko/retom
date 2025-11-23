// File: Shared/Views/CameraView.swift
// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false

    // シミュレータではライブラリ、実機ではカメラ優先
    private var pickerSource: CameraPicker.Source {
        #if targetEnvironment(simulator)
        return .library
        #else
        return .camera
        #endif
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // 背景（レトロっぽいクリーム色）
            Color(red: 0.99, green: 0.96, blue: 0.90)
                .ignoresSafeArea()

            VStack(spacing: 32) {

                // MARK: - Header（タイトルまわり）
                headerSection

                // MARK: - Preview エリア（黒いフィルム窓）
                previewSection

                Spacer()

                // MARK: - シャッターボタン
                shutterSection

                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .sheet(isPresented: $showPicker) {
            CameraPicker(from: pickerSource) { image in
                guard let image = image else { return }
                appState.addPhoto(from: image)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カメラ")
                .font(.largeTitle.bold())

            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.title3)
                Text("retom フィルムカメラ")
                    .font(.title3.weight(.semibold))
            }

            Text("保存されている写真：\(appState.photos.count)枚")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(radius: 2)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Preview

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.95),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 16)

            VStack(spacing: 24) {

                // 上の小さな穴
                HStack(spacing: 8) {
                    ForEach(0..<7) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .frame(width: 20, height: 4)
                    }
                }
                .opacity(0.9)

                Spacer()

                // 中央のメッセージ
                Text(targetEnvironmentMessage)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // 下の小さな穴
                HStack(spacing: 8) {
                    ForEach(0..<7) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .frame(width: 20, height: 4)
                    }
                }
                .opacity(0.9)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
        }
        .frame(height: 260)
    }

    private var targetEnvironmentMessage: String {
        #if targetEnvironment(simulator)
        return "シミュレータでは\nフォトライブラリから選択"
        #else
        return "シャッターを押して撮影"
        #endif
    }

    // MARK: - Shutter

    private var shutterSection: some View {
        VStack(spacing: 12) {
            Button {
                showPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)

                    Circle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 6)
                        .frame(width: 96, height: 96)

                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 74, height: 74)
                }
            }
            .buttonStyle(.plain)

            Text(shutterLabelText)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var shutterLabelText: String {
        #if targetEnvironment(simulator)
        return "シャッター（フォトライブラリ）"
        #else
        return "シャッター"
        #endif
    }
}
