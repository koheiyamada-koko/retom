// File: Shared/Views/AlbumView.swift
import SwiftUI

struct AlbumView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.photos) { photo in
                    NavigationLink {
                        // ✅ 引数ラベルを photo に統一
                        PhotoDetailView(photo: photo)
                    } label: {
                        AlbumRow(photo: photo)
                    }
                }
            }
            .navigationTitle("アルバム")
        }
    }
}

// MARK: - アルバム1行分の表示

private struct AlbumRow: View {
    let photo: PhotoItem

    // 日付フォーマッタ（年月日）
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    // 時刻フォーマッタ（時:分）
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 16) {

            // サムネイル
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemGray6))

                if let image = UIImage(contentsOfFile: photo.imageDataURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ProgressView()
                }
            }
            // 🔧 テキストとの間が詰まりすぎ問題対策で少し広めに確保
            .frame(width: 90, height: 72)

            // 日付・時間
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: photo.capturedAt))
                    .font(.headline)

                Text(Self.timeFormatter.string(from: photo.capturedAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

