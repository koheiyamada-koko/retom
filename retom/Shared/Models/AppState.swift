// File: Shared/Models/AppState.swift
import SwiftUI

@MainActor
final class AppState: ObservableObject, Codable {
    static let shared = AppState()

    // MARK: - Published State
    @Published var photos: [PhotoItem] = []
    @Published var isPremium: Bool = false

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case photos
        case isPremium
    }

    // MARK: - Init
    init(photos: [PhotoItem] = [], isPremium: Bool = false) {
        self.photos = photos
        self.isPremium = isPremium
    }

    // MARK: - Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        photos = try container.decode([PhotoItem].self, forKey: .photos)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(photos, forKey: .photos)
        try container.encode(isPremium, forKey: .isPremium)
    }

    // MARK: - パス系
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var stateURL: URL {
        documentsDirectory.appendingPathComponent("appState.json")
    }

    // MARK: - 永続化（状態）
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            print("❌ AppState save failed: \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        do {
            let data = try Data(contentsOf: stateURL)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            self.photos = decoded.photos
            self.isPremium = decoded.isPremium
        } catch {
            print("❌ AppState load failed: \(error)")
        }
    }

    // MARK: - 写真の追加（本物の画像版）
    func addPhoto(from image: UIImage) {
        let id = UUID()

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            print("❌ jpegData 変換に失敗")
            return
        }

        let fileName = "photo-\(id.uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ 画像の保存に失敗: \(error)")
            return
        }

        let item = PhotoItem(
            id: id,
            capturedAt: Date(),
            imageDataURL: fileURL,
            isUnlockedEarly: true,
            requiresAdGateBeforeReady: false,
            memoDrawingData: nil
        )

        photos.append(item)
        save()
    }

    // MARK: -（おまけ）テスト用ダミー写真
    func addDummyPhoto() {
        let id = UUID()
        let fileURL = documentsDirectory.appendingPathComponent("dummy-\(id.uuidString).jpg")

        let item = PhotoItem(
            id: id,
            capturedAt: Date(),
            imageDataURL: fileURL,
            isUnlockedEarly: true,
            requiresAdGateBeforeReady: false,
            memoDrawingData: nil
        )

        photos.append(item)
        save()
    }
}

