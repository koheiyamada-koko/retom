// File: Shared/Models/AppState.swift
import SwiftUI
import Combine

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

    // MARK: - 保存場所
    private var saveURL: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return doc.appendingPathComponent("appState.json")
    }

    // MARK: - 永続化
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("❌ AppState save failed: \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            self.photos = decoded.photos
            self.isPremium = decoded.isPremium
        } catch {
            print("❌ AppState load failed: \(error)")
        }
    }

    // MARK: - テスト用：ダミー写真を1枚追加
    func addDummyPhoto() {
        let id = UUID()
        let now = Date()

        // まだ本物の画像は使わないので、適当な一時ファイルパスを入れておく
        let dummyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dummy-\(id.uuidString).jpg")

        let newPhoto = PhotoItem(
            id: id,
            capturedAt: now,
            readyAt: now,
            isUnlockedEarly: true,
            requiresAdGateBeforeReady: false,
            imageDataURL: dummyURL,
            memoDrawingData: nil
        )

        photos.append(newPhoto)
        save()
    }
}

