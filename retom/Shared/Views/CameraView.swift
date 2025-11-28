// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false

    // シャッターボタン演出用の状態
    @State private var isShutterPressed = false
    @State private var showFlashOverlay = false

    // シミュレータではフォトライブラリ、実機ではカメラ優先
    private var pickerSource: CameraPicker.Source {
        #if targetEnvironment(simulator)
        return .library          // シミュレータはライブラリ固定
        #else
        return .camera           // 実機ではカメラ優先
        #endif
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // 背景（レトロっぽいクリーム色）
            Color(red: 0.99, green: 0.96, blue: 0.90)
                .ignoresSafeArea()

            // フラッシュ演出用オーバーレイ
            if showFlashOverlay {
                Color.white
                    .opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 32) {
                headerSection
                previewSection

                Spacer()

                shutterSection

                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .sheet(isPresented: $showPicker) {
            CameraPicker(from: pickerSource) { uiImage in
                if let uiImage = uiImage {
                    appState.addPhoto(from: uiImage)
                }
                // ✅ シートを閉じたことを状態にも反映する
                showPicker = false
            }
        }

    }

    // MARK: - Header（タイトル等）

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - プレビュー枠（今はダミー）

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 16)

            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
                .padding(8)

            // 上下の小さな穴っぽい装飾（フィルムの窓っぽく）
            VStack {
                capsuleRow
                Spacer()
                capsuleRow
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 26)

            // 中央テキスト
            Text("シミュレータでは\nフォトライブラリから選択")
                .font(.callout)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(height: 280)
    }

    private var capsuleRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { _ in
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 22, height: 4)
            }
        }
    }

    // MARK: - シャッターボタン

    private var shutterSection: some View {
        VStack(spacing: 12) {
            Button {
                // ① シャッター演出（縮む & フラッシュ）
                triggerShutterAnimation()

                // ② 少し待ってから Picker を開く
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showPicker = true
                }

            } label: {
                ZStack {
                    // 外側のリング
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)

                    // 中央ボタン
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                        )
                        .scaleEffect(isShutterPressed ? 0.88 : 1.0)
                        .animation(.easeOut(duration: 0.12), value: isShutterPressed)
                }
            }
            .buttonStyle(PlainButtonStyle())


            Text("シャッター（フォトライブラリ）")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - シャッター演出ロジック

    private func triggerShutterAnimation() {
        // ボタン縮小
        isShutterPressed = true

        // フラッシュ表示
        withAnimation(.easeOut(duration: 0.08)) {
            showFlashOverlay = true
        }

        // 少しだけ時間をおいて元に戻す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isShutterPressed = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.18)) {
                showFlashOverlay = false
            }
        }
    }
}

