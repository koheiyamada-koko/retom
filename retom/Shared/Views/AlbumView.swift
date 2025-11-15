// File: Shared/Views/AlbumView.swift
import SwiftUI

struct AlbumView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.photos.isEmpty {
                    VStack(spacing: 16) {
                        Text("🖼 まだ写真がありません")
                            .font(.headline)
                        Text("カメラタブからシャッターボタンを押して\nテスト写真を追加してみてください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(appState.photos.sorted { $0.capturedAt > $1.capturedAt }) { photo in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(photo.capturedAt, style: .date)
                                .font(.body)
                            Text(photo.capturedAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("アルバム")
        }
    }
}

#Preview {
    AlbumView()
        .environmentObject(AppState.shared)
}

