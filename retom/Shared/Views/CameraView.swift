// File: Shared/Views/CameraView.swift
import SwiftUI
import CoreImage
import Photos
import UIKit
import AVFoundation

private enum CameraLayoutConstants {
    static let panelWidth: CGFloat = 320
    static let sectionSpacing: CGFloat = 20
    static let headerSpacing: CGFloat = 12
    static let topPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 40
    static let horizontalPadding: CGFloat = 20

    static let paperTextureOpacity: Double = 0.4
    static let grainOpacity: Double = 0.3
    static let lightLeakTopLeftOpacity: Double = 0.35
    static let lightLeakBottomRightOpacity: Double = 0.25

    static let previewHeight: CGFloat = 280
}

private extension View {
    func centerPanel(maxWidth: CGFloat = CameraLayoutConstants.panelWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPicker = false
    @State private var showUpgradeView = false

    @StateObject private var cameraService = CameraService()

    @State private var isShutterPressed = false
    @State private var showFlashOverlay = false
    @State private var isRequestingPermission = false
    @State private var isCapturing = false
    @State private var alertMessage: String?
    @State private var showSettingsButton = false
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Environment(\.scenePhase) private var scenePhase

    private var pickerSource: CameraPicker.Source {
        #if targetEnvironment(simulator)
        return .library
        #else
        return .camera
        #endif
    }

    var body: some View {
        ZStack {
            // ===== 背景レイヤー =====
            ZStack {
                Color(red: 0.95, green: 0.91, blue: 0.80)

                Image("paperTexture")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.multiply)
                    .opacity(CameraLayoutConstants.paperTextureOpacity)

                Image("grainOverlay")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.overlay)
                    .opacity(CameraLayoutConstants.grainOpacity)

                Image("lightLeakTopLeft")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.screen)
                    .opacity(CameraLayoutConstants.lightLeakTopLeftOpacity)

                Image("lightLeakBottomRight")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.screen)
                    .opacity(CameraLayoutConstants.lightLeakBottomRightOpacity)
            }
            .ignoresSafeArea()

            // ===== コンテンツ =====
            ScrollView(showsIndicators: false) {
                VStack(spacing: CameraLayoutConstants.sectionSpacing) {
                    headerSection
                        .centerPanel()

                    previewSection
                        .centerPanel()

                    shutterSection
                        .centerPanel()
                }
                .padding(.horizontal, CameraLayoutConstants.horizontalPadding)
                .padding(.top, CameraLayoutConstants.topPadding)
                .padding(.bottom, CameraLayoutConstants.bottomPadding)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // ===== フラッシュ =====
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
                    let error = appState.addPhoto(from: uiImage, isProUser: purchaseManager.isProUser)
                    handleSaveResult(error)
                }
                isCapturing = false
                showPicker = false
            }
        }
        .sheet(isPresented: $showUpgradeView) {
            UpgradeView()
                .environmentObject(purchaseManager)
        }
        .onAppear {
            setupCameraCallbacks()
            #if !targetEnvironment(simulator)
            checkCameraPermissionAndStart()
            #endif
        }
        .onDisappear {
            #if !targetEnvironment(simulator)
            cameraService.stopSession()
            #endif
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .background || newValue == .inactive {
                showPicker = false
                isCapturing = false
                #if !targetEnvironment(simulator)
                cameraService.stopSession()
                #endif
            } else if newValue == .active {
                #if !targetEnvironment(simulator)
                checkCameraPermissionAndStart()
                #endif
            }
        }
        .alert(isPresented: Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue { alertMessage = nil }
            })
        ) {
            if showSettingsButton {
                return Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage ?? "問題が発生しました"),
                    primaryButton: .default(Text("設定を開く"), action: openSettingsIfNeeded),
                    secondaryButton: .cancel(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage ?? "問題が発生しました"),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: CameraLayoutConstants.headerSpacing) {
            Text("カメラ")
                .font(.largeTitle.bold())
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                Text("retom フィルムカメラ")
                    .font(.title3.bold())
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 4) {
                Text("保存されている写真：\(appState.photos.count)枚")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))

                if !purchaseManager.isProUser {
                    let remaining = max(0, 50 - appState.totalSavedCount)
                    Text("残り\(remaining)枚（無料版）")
                        .font(.caption)
                        .foregroundColor(
                            remaining <= 5
                            ? Color(red: 0.7, green: 0.3, blue: 0.2)
                            : Color(red: 0.45, green: 0.4, blue: 0.35)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Pro版：無制限")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - プレビュー枠

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.07, blue: 0.08),
                            Color(red: 0.02, green: 0.03, blue: 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.45), radius: 26, x: 0, y: 18)

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.6),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 2)
                        .padding(4)
                )

            #if targetEnvironment(simulator)
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
            if cameraAuthorizationStatus == .authorized {
                CameraPreviewView(session: cameraService.session)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .clipped()
                    .padding(4)
            } else {
                VStack {
                    Text("カメラへのアクセスがありません")
                        .font(.callout)
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Button("設定を開く") {
                        openSettingsIfNeeded()
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(4)
            }
            #endif

            VStack {
                capsuleRow
                Spacer()
                capsuleRow
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 26)
        }
        .frame(height: CameraLayoutConstants.previewHeight)
    }

    private var capsuleRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { _ in
                Capsule()
                    .fill(Color(red: 0.7, green: 0.75, blue: 0.6).opacity(0.25))
                    .frame(width: 22, height: 4)
            }
        }
    }

    // MARK: - シャッターボタン

    private var shutterSection: some View {
        VStack(spacing: 16) {
            Button {
                handleShutterTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.90, green: 0.84, blue: 0.72))
                        .frame(width: 96, height: 96)
                        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 12)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.95, blue: 0.92),
                                    Color(red: 0.88, green: 0.82, blue: 0.75),
                                    Color(red: 0.85, green: 0.78, blue: 0.70)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 5,
                                endRadius: 45
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .scaleEffect(isShutterPressed ? 0.88 : 1.0)
                        .colorMultiply(isShutterPressed ? Color(white: 0.85) : Color.white)
                        .animation(.easeOut(duration: 0.12), value: isShutterPressed)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isSavingOrCapturing)

            Text(shutterLabel)
                .font(.footnote)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    // MARK: - シャッター演出

    private func triggerShutterAnimation() {
        isShutterPressed = true

        withAnimation(.easeOut(duration: 0.08)) {
            showFlashOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isShutterPressed = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.18)) {
                showFlashOverlay = false
            }
        }
    }

    private func handleShutterTap() {
        guard !isSavingOrCapturing else {
            #if DEBUG
            print("⚠️ シャッター入力を抑制中 isSaving:\\(appState.isSaving) isCapturing:\\(isCapturing)")
            #endif
            return
        }

        isCapturing = true
        triggerShutterAnimation()

        #if targetEnvironment(simulator)
        Task { @MainActor in
            await requestPhotoAccessAndPresentPicker()
        }
        #else
        guard cameraAuthorizationStatus == .authorized else {
            handleCameraPermissionForCapture()
            return
        }

        cameraService.startSession()
        cameraService.capturePhoto()
        #endif
    }

    private var isSavingOrCapturing: Bool {
        appState.isSaving || isCapturing || isRequestingPermission
    }

    private func setupCameraCallbacks() {
        cameraService.onPhotoCapture = { image in
            handleCapturedPhoto(image)
        }
        cameraService.onError = { error in
            handleCameraError(error)
        }
    }

    private func checkCameraPermissionAndStart() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthorizationStatus = status

        switch status {
        case .authorized:
            cameraService.startSession()
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            showCameraPermissionAlert(for: status)
        @unknown default:
            showCameraPermissionAlert(for: status)
        }
    }

    private func requestCameraPermission() {
        isRequestingPermission = true
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                self.cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

                if granted {
                    self.cameraService.startSession()
                } else {
                    self.isCapturing = false
                    self.showCameraPermissionAlert(for: self.cameraAuthorizationStatus)
                }
            }
        }
    }

    private func handleCameraPermissionForCapture() {
        switch cameraAuthorizationStatus {
        case .authorized:
            cameraService.startSession()
            cameraService.capturePhoto()
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            isCapturing = false
            showCameraPermissionAlert(for: cameraAuthorizationStatus)
        @unknown default:
            isCapturing = false
            showCameraPermissionAlert(for: cameraAuthorizationStatus)
        }
    }

    private func handleCapturedPhoto(_ image: UIImage) {
        let error = appState.addPhoto(from: image, isProUser: purchaseManager.isProUser)
        handleSaveResult(error)
    }

    private func handleCameraError(_ error: CameraServiceError) {
        alertMessage = error.errorDescription
        showSettingsButton = false
        isCapturing = false
    }

    private func showCameraPermissionAlert(for status: AVAuthorizationStatus) {
        let reason: String
        switch status {
        case .denied:
            reason = "ユーザーにより拒否されました。"
        case .restricted:
            reason = "機能制限によりアクセスできません。"
        default:
            reason = "カメラへのアクセス権限がありません。"
        }
        alertMessage = "カメラにアクセスできないため撮影できません。\\n" + reason
        showSettingsButton = true
    }

    private var shutterLabel: String {
        #if targetEnvironment(simulator)
        return "シャッター（フォトライブラリ）"
        #else
        return "シャッター"
        #endif
    }

    private var currentPermissionLabel: String {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized: return "authorized"
        case .limited: return "limited"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    @MainActor
    private func requestPhotoAccessAndPresentPicker() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            presentPicker()
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus == .authorized || newStatus == .limited {
                presentPicker()
            } else {
                showPermissionAlert(for: newStatus)
                isCapturing = false
            }
        case .denied, .restricted:
            showPermissionAlert(for: status)
            isCapturing = false
        @unknown default:
            showPermissionAlert(for: status)
            isCapturing = false
        }
    }

    private func presentPicker() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPicker = true
        }
    }

    private func showPermissionAlert(for status: PHAuthorizationStatus) {
        let baseMessage = "保存に失敗しました。写真へのアクセス権限を確認してください。"
        let reason: String

        switch status {
        case .denied:
            reason = "ユーザーにより拒否されました。"
        case .restricted:
            reason = "機能制限によりアクセスできません。"
        default:
            reason = "権限がありません。"
        }

        alertMessage = baseMessage + "\\n" + reason
        showSettingsButton = true
        #if DEBUG
        print("❌ Photos permission issue: \\(status.rawValue) \\(reason)")
        #endif
    }

    private func openSettingsIfNeeded() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func handleSaveResult(_ error: PhotoSaveError?) {
        showSettingsButton = false
        guard let error = error else {
            isCapturing = false
            return
        }

        switch error {
        case .limitReached:
            showUpgradeView = true
        case .savingInProgress:
            #if DEBUG
            print("⚠️ 保存が重複しないようスキップ")
            #endif
        case .jpegConversionFailed, .fileWriteFailed:
            alertMessage = "保存に失敗しました。写真へのアクセス権限を確認してください。"
            showSettingsButton = false
            #if DEBUG
            print("❌ 保存エラー: \\(error.localizedDescription)")
            #endif
        }

        isCapturing = false
    }
}

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    private static let previewDevices = [
        "iPhone 13",
        "iPhone 15 Pro",
        "iPhone 16 Pro Max"
    ]

    private static let previewAppState: AppState = {
        let appState = AppState.shared
        appState.photos = []
        return appState
    }()

    private static let previewPurchaseManager: PurchaseManager = {
        let manager = PurchaseManager()
        manager.isProUser = false
        return manager
    }()

    static var previews: some View {
        Group {
            ForEach(previewDevices, id: \.self) { device in
                CameraView()
                    .environmentObject(previewAppState)
                    .environmentObject(previewPurchaseManager)
                    .previewDisplayName("\(device) • Light")
                    .previewDevice(PreviewDevice(rawValue: device))
                    .preferredColorScheme(.light)
            }

            ForEach(previewDevices, id: \.self) { device in
                CameraView()
                    .environmentObject(previewAppState)
                    .environmentObject(previewPurchaseManager)
                    .previewDisplayName("\(device) • Dark")
                    .previewDevice(PreviewDevice(rawValue: device))
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
