// File: Shared/Views/AlbumView.swift
import SwiftUI
import UIKit

struct AlbumView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            List(appState.photos) { photo in
                AlbumRow(photo: photo)
            }
            .navigationTitle("アルバム")
        }
    }
}

private struct AlbumRow: View {
    let photo: PhotoItem
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {

            // サムネイル部分
            ZStack {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.black.opacity(0.05)
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            // 日付テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: photo.capturedAt))
                    .font(.headline)

                Text(Self.timeFormatter.string(from: photo.capturedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task {
            await loadThumbnailIfNeeded()
        }
    }

    // MARK: - 画像読み込み

    private func loadThumbnailIfNeeded() async {
        guard thumbnail == nil else { return }

        let url = photo.imageDataURL

        do {
            let data = try Data(contentsOf: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.thumbnail = image
                }
            }
        } catch {
            print("⚠️ サムネイル読み込み失敗: \(error)")
        }
    }

    // MARK: - 日付フォーマッタ

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}

