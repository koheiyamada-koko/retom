// File: Shared/Models/AppState.swift
import SwiftUI
import UIKit

/// アプリ全体で共有する状態
final class AppState: ObservableObject {

    // MARK: - Singleton
    static let shared = AppState()
    private init() {}

    // MARK: - Properties

    /// 撮影された写真の一覧
    @Published var photos: [PhotoItem] = []

    // MARK: - Load & Save

    /// 起動時に保存済みデータを読み込む
    func load() {
        let url = saveFileURL
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PhotoItem].self, from: data)
            self.photos = decoded
        } catch {
            print("⚠️ AppState load failed: \(error)")
        }
    }

    /// 現在の `photos` を JSON として保存
    func save() {
        let url = saveFileURL
        do {
            let data = try JSONEncoder().encode(photos)
            try data.write(to: url, options: .atomic)
        } catch {
            print("⚠️ AppState save failed: \(error)")
        }
    }

    /// 保存用 JSON ファイルの URL
    private var saveFileURL: URL {
        documentsDirectory.appendingPathComponent("photos.json")
    }

    /// 画像ファイルや JSON を置く Documents ディレクトリ
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: - Photo Handling

    /// 撮影 or 選択した UIImage を受け取り、
    /// レトロ加工 + 日付スタンプを付けて保存し、PhotoItem を追加
    func addPhoto(from uiImage: UIImage) {
        // ① レトロ加工 + 日付スタンプ
        let processed = RetroFilter.apply(to: uiImage, date: Date())

        // ② JPEG データ化
        guard let data = processed.jpegData(compressionQuality: 0.9) else {
            print("⚠️ JPEG 変換に失敗")
            return
        }

        // ③ 保存先 URL を決定
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        // ④ 実際に書き込む
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ 画像の保存に失敗: \(error)")
            return
        }

        // ⑤ PhotoItem を作成して先頭に追加
        let item = PhotoItem(
            id: id,
            capturedAt: Date(),
            imageDataURL: fileURL
        )

        photos.insert(item, at: 0)
        save()
    }
}

