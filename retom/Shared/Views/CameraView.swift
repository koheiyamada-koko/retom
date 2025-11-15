// File: Shared/Views/CameraView.swift
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCapturing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("📷 retom カメラ")
                    .font(.title2)
                    .bold()

                Text("現在の写真枚数：\(appState.photos.count)枚")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // 疑似シャッターボタン
                Button {
                    captureDummyPhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 90, height: 90)

                        Circle()
                            .fill(isCapturing ? .red : .white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 4)

                        if isCapturing {
                            Text("Saving…")
                                .font(.caption)
                                .foregroundColor(.red)
                                .offset(y: 60)
                        }
                    }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isCapturing)

                Spacer()
            }
            .padding()
            .navigationTitle("カメラ")
        }
    }

    private func captureDummyPhoto() {
        guard !isCapturing else { return }

        isCapturing = true
        appState.addDummyPhoto()

        // ちょっとだけアニメーションを見せるための遅延
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isCapturing = false
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState.shared)
}

