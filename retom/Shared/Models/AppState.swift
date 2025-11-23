// File: Shared/Models/AppState.swift
import SwiftUI
import UIKit

/// アプリ全体で共有する状態
final class AppState: ObservableObject {

    // 公開プロパティ：アルバムに表示する写真たち
    @Published var photos: [PhotoItem] = []

    // シングルトン（.environmentObject で渡しているやつ）
    static let shared = AppState()

    private init() {
        // 起動時に保存済みデータを読み込む
        load()
    }

    // MARK: - 保存ファイルの場所

    /// 写真リスト(JSON)を保存するファイルのURL
    private var saveFileURL: URL {
        let fm = FileManager.default
        let dir = try! fm.url(for: .documentDirectory,
                              in: .userDomainMask,
                              appropriateFor: nil,
                              create: true)
        return dir.appendingPathComponent("app_state_photos.json")
    }

    // MARK: - ロード & セーブ

    /// 保存してある PhotoItem の配列を読み込む
    func load() {
        let url = saveFileURL
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PhotoItem].self, from: data)
            self.photos = decoded
        } catch {
            // 初回起動など、ファイルが無いときはここに来るので警告だけ
            print("⚠️ AppState load failed: \(error)")
        }
    }

    /// 現在の photos を JSON として保存
    func save() {
        let url = saveFileURL
        do {
            let data = try JSONEncoder().encode(photos)
            try data.write(to: url, options: .atomic)
        } catch {
            print("⚠️ AppState save failed: \(error)")
        }
    }

    // MARK: - 写真追加（レトロ加工 + 日付スタンプ付き）

    func addPhoto(from uiImage: UIImage) {
        // 📌 1. RetroFilter でレトロ加工＋日付焼き込み
        let processed = RetroFilter.apply(to: uiImage, date: Date())

        // 📌 2. JPEGデータ生成
        guard let data = processed.jpegData(compressionQuality: 0.9) else {
            print("❌ JPEG変換に失敗")
            return
        }

        // 📌 3. Documentsフォルダ取得
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let url = directory.appendingPathComponent(fileName)

        // 📌 4. データ書き込み
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ 画像の保存に失敗: \(error)")
            return
        }

        // 📌 5. PhotoItem を作成して先頭に追加
        let item = PhotoItem(
            id: id,
            capturedAt: Date(),
            imageDataURL: url
        )

        photos.insert(item, at: 0)
        save()
    }


    // MARK: - おまけ：ダミー写真追加（テスト用）

    /// グレーのダミー画像を1枚追加したいとき用（テスト用）
    func addDummyPhoto() {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.systemGray4.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        addPhoto(from: image)
    }
}

