// File: Shared/Views/CameraView.swift
import SwiftUI
import CoreImage

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPicker = false
    @State private var showUpgradeView = false

    // カメラプレビュー用サービス
    @StateObject private var cameraService = CameraPreviewService()

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
        ZStack {
            // レイヤー構造（下から上へ）
            
            // ① 最下層：クリーム色の背景
            Color(hex: 0xF5F5DC)
                .ignoresSafeArea()
            
            // ② ノイズテクスチャ（フィルムグレイン）
            noiseTexture
                .ignoresSafeArea()
                .blendMode(.overlay)
                .opacity(0.15)
            
            // ③ メインコンテンツ
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
            
            // ④ 光漏れ（light leak）- 左上に配置
            lightLeakOverlay
                .ignoresSafeArea()
            
            // ⑤ フラッシュ演出用オーバーレイ（最上層）
            if showFlashOverlay {
                Color.white
                    .opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showPicker) {
            CameraPicker(from: pickerSource) { uiImage in
                if let uiImage = uiImage {
                    // 保存を試みる
                    if let error = appState.addPhoto(from: uiImage, isProUser: purchaseManager.isProUser) {
                        // 制限に達した場合はアップグレード画面を表示
                        if error == .limitReached {
                            showUpgradeView = true
                        }
                    }
                }
                // ✅ シートを閉じたことを状態にも反映する
                showPicker = false
            }
        }
        .sheet(isPresented: $showUpgradeView) {
            UpgradeView()
                .environmentObject(purchaseManager)
        }
        .onAppear {
            #if !targetEnvironment(simulator)
            cameraService.start()
            #endif
        }
        .onDisappear {
            #if !targetEnvironment(simulator)
            cameraService.stop()
            #endif
        }
    }
    
    // MARK: - ノイズテクスチャ（フィルムグレイン）
    
    private var noiseTexture: some View {
        GeometryReader { geometry in
            if let noiseImage = generateNoiseTexture(size: geometry.size) {
                Image(uiImage: noiseImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // フォールバック：シンプルなパターン
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - 光漏れ（light leak）オーバーレイ
    
    private var lightLeakOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // 左上のオレンジ/黄色の光
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.3),
                        Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.15),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.1, y: 0.1),
                    startRadius: 50,
                    endRadius: geometry.size.width * 0.8
                )
                
                // 右下にも少し光漏れ
                RadialGradient(
                    colors: [
                        Color(red: 0.95, green: 0.75, blue: 0.4).opacity(0.2),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.9, y: 0.9),
                    startRadius: 30,
                    endRadius: geometry.size.width * 0.5
                )
            }
        }
    }

    // MARK: - Header（タイトル等）

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カメラ")
                .font(.largeTitle.bold())
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))

            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                Text("retom フィルムカメラ")
                    .font(.title3.bold())
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("保存されている写真：\(appState.photos.count)枚")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))
                
                // 無料版の場合、残り枚数を表示
                if !purchaseManager.isProUser {
                    let remaining = max(0, 50 - appState.totalSavedCount)
                    Text("残り\(remaining)枚（無料版）")
                        .font(.caption)
                        .foregroundColor(remaining <= 5 ? Color(red: 0.7, green: 0.3, blue: 0.2) : Color(red: 0.45, green: 0.4, blue: 0.35))
                } else {
                    Text("Pro版：無制限")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                // ボーダーなし、柔らかい影で区切りを表現
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - プレビュー枠

    private var previewSection: some View {
        ZStack {
            // 外側の影（柔らかく、レトロ感を出す）
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.85))
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 12)
            
            // 内側のプレビューエリア（ボーダーなし）
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .padding(4)

            // 中身：実機ならカメラ映像、シミュレータならダミー表示
            #if targetEnvironment(simulator)
            // 🔹 シミュレータ用：今までどおりのダミープレビュー
            VStack {
                Text("シミュレータでは\nフォトライブラリから選択")
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(4)
            #else
            // 🔹 実機用：本物のカメラプレビュー
            CameraPreviewView(service: cameraService)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .clipped()
                .padding(4)
            #endif

            // 上下の穴っぽい装飾（より控えめに）
            VStack {
                capsuleRow
                Spacer()
                capsuleRow
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 26)
        }
        .frame(height: 280)
    }

    private var capsuleRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { _ in
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 22, height: 4)
            }
        }
    }

    // MARK: - シャッターボタン

    private var shutterSection: some View {
        VStack(spacing: 16) {
            Button {
                // ✅ 先にフラッシュ/縮みアニメーション
                triggerShutterAnimation()

                // ✅ 少し待ってから Picker を開く
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showPicker = true
                }
            } label: {
                ZStack {
                    // 外側のリング（暖色寄り、柔らかい影）
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.85),
                                    Color(red: 0.9, green: 0.85, blue: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)

                    // 中央ボタン（暖色の白）
                    Circle()
                        .fill(Color(red: 0.98, green: 0.95, blue: 0.92))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color(red: 0.9, green: 0.85, blue: 0.8).opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isShutterPressed ? 0.88 : 1.0)
                        .animation(.easeOut(duration: 0.12), value: isShutterPressed)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Text("シャッター（フォトライブラリ）")
                .font(.footnote)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
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
    
    // MARK: - ノイズテクスチャ生成（CoreImage使用）
    
    private func generateNoiseTexture(size: CGSize) -> UIImage? {
        let ciContext = CIContext()
        
        // ランダムノイズ生成
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else {
            return nil
        }
        
        guard let noiseImage = noiseFilter.outputImage else {
            return nil
        }
        
        // ノイズをグレースケールに変換し、サイズを調整
        let croppedNoise = noiseImage
            .cropped(to: CGRect(origin: .zero, size: size))
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ])
        
        guard let cgImage = ciContext.createCGImage(croppedNoise, from: croppedNoise.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Color Extension（hex値からColorを生成）

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }
}
