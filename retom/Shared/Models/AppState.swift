// File: Shared/Models/AppState.swift
import SwiftUI
import UIKit

/// アプリ全体で共有する状態
@MainActor
final class AppState: ObservableObject {

    // 公開プロパティ：アルバムに表示する写真たち
    @Published var photos: [PhotoItem] = []

    // シングルトン（.environmentObject で渡しているやつ）
    static let shared = AppState()

    private init() {
        // 初期化のみ。load()はretomApp.swiftの.taskで呼び出す
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
            
            // 既存の写真数から保存枚数を初期化（初回起動時や不整合を防ぐ）
            let currentCount = totalSavedCount
            let actualCount = decoded.count
            if currentCount < actualCount {
                // 実際の写真数が多い場合は、そちらに合わせる
                UserDefaults.standard.set(actualCount, forKey: UserDefaultsKeys.totalSavedCount)
            }
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

    // MARK: - 保存枚数管理
    
    /// 無料版の撮影・保存上限枚数
    private let freeVersionLimit = 50
    
    /// 現在の保存済み枚数（UserDefaultsから読み込み）
    var totalSavedCount: Int {
        UserDefaults.standard.integer(forKey: UserDefaultsKeys.totalSavedCount)
    }
    
    /// 保存可能かどうかをチェック
    /// - Parameter isProUser: Pro版購入済みかどうか
    /// - Returns: 保存可能な場合true
    func canSavePhoto(isProUser: Bool) -> Bool {
        // Pro版ユーザーは無制限
        if isProUser {
            return true
        }
        // 無料版は50枚まで
        return totalSavedCount < freeVersionLimit
    }
    
    /// 保存枚数をインクリメント
    private func incrementSavedCount() {
        let current = totalSavedCount
        UserDefaults.standard.set(current + 1, forKey: UserDefaultsKeys.totalSavedCount)
    }
    
    /// 保存枚数をデクリメント（削除時用）
    private func decrementSavedCount() {
        let current = totalSavedCount
        if current > 0 {
            UserDefaults.standard.set(current - 1, forKey: UserDefaultsKeys.totalSavedCount)
        }
    }

    // MARK: - 写真追加（レトロ加工 + 日付スタンプ付き）

    /// 写真を追加（レトロ加工 + 日付スタンプ付き）
    /// - Parameters:
    ///   - uiImage: 追加する画像
    ///   - isProUser: Pro版購入済みかどうか
    /// - Returns: 成功した場合nil、制限に達した場合PhotoSaveError.limitReached
    func addPhoto(from uiImage: UIImage, isProUser: Bool) -> PhotoSaveError? {
        // 📌 0. 保存可能かチェック
        guard canSavePhoto(isProUser: isProUser) else {
            return .limitReached
        }
        
        // 📌 1. RetroFilter でレトロ加工＋日付焼き込み
        let processed = RetroFilter.apply(to: uiImage, date: Date())

        // 📌 2. JPEGデータ生成
        guard let data = processed.jpegData(compressionQuality: 0.9) else {
            print("❌ JPEG変換に失敗")
            return .jpegConversionFailed
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
            return .fileWriteFailed
        }

        // 📌 5. PhotoItem を作成して先頭に追加
        let item = PhotoItem(
            id: id,
            capturedAt: Date(),
            imageDataURL: url
        )

        photos.insert(item, at: 0)
        save()
        
        // 📌 6. 保存枚数をインクリメント
        incrementSavedCount()
        
        return nil // 成功
    }


    // MARK: - おまけ：ダミー写真追加（テスト用）

    /// グレーのダミー画像を1枚追加したいとき用（テスト用）
    func addDummyPhoto(isProUser: Bool) {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.systemGray4.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        _ = addPhoto(from: image, isProUser: isProUser)
    }
    
    //------------------------------------
    // MARK: - 写真削除

    func delete(_ photo: PhotoItem) {
        let fileURL = photo.imageDataURL
        let fm = FileManager.default

        // 1. 画像ファイルを削除
        do {
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            }
        } catch {
            print("⚠️ 画像ファイル削除に失敗: \(error)")
        }

        // 2. メモリ上の配列から削除
        photos.removeAll { $0.id == photo.id }

        // 3. 保存枚数をデクリメント
        decrementSavedCount()

        // 4. JSON も更新
        save()
    }

}

// MARK: - Photo Save Errors

enum PhotoSaveError: LocalizedError {
    case limitReached
    case jpegConversionFailed
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "無料版の撮影上限（50枚）に達しました"
        case .jpegConversionFailed:
            return "画像の変換に失敗しました"
        case .fileWriteFailed:
            return "画像の保存に失敗しました"
        }
    }
}

