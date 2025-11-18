// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false

    var body: some View {
        ZStack {
            // 背景：少し黄味がかった紙っぽい色
            Color(red: 0.98, green: 0.96, blue: 0.90)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // ヘッダー（タイトル・サブタイトル・枚数）
                headerSection

                // カメラプレビュー風カード
                previewSection

                Spacer()

                // シャッターボタン
                shutterSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .sheet(isPresented: $showPicker) {
            // ✅ ここは動きはそのまま（写真をとったら保存）
            CameraPicker(from: .camera) { uiImage in
                guard let image = uiImage else { return }
                appState.addPhoto(from: image)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カメラ")
                .font(.system(size: 32, weight: .heavy, design: .rounded))

            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .foregroundColor(.black.opacity(0.8))

                Text("retom フィルムカメラ")
                    .font(.system(.headline, design: .rounded))
            }

            HStack {
                // 枠付きのチップ風表示
                Text("保存されている写真：\(appState.photos.count)枚")
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )

                Spacer()
            }
        }
        .foregroundColor(.black.opacity(0.9))
    }

    // MARK: - Preview

    private var previewSection: some View {
        ZStack {
            // 外枠：フィルムカメラのファインダー枠っぽいカード
            RoundedRectangle(cornerRadius: 22)
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
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 10)

            // 内側に一段明るい枠
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
                .padding(10)

            // 中央のテキスト
            Text("Camera Preview")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            // 上下にフィルム穴っぽい飾り
            VStack {
                filmHolesRow
                Spacer()
                filmHolesRow
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
        .frame(height: 280)
    }

    private var filmHolesRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 10, height: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Shutter

    private var shutterSection: some View {
        VStack(spacing: 16) {
            Button {
                showPicker = true
            } label: {
                ZStack {
                    // 外側のリング
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.95, green: 0.94, blue: 0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)

                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 4)
                        .frame(width: 88, height: 88)

                    // 内側（少し凹んでいるっぽく）
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.95, green: 0.95, blue: 0.95)
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                }
            }

            Text("シャッター")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 32)
    }
}

