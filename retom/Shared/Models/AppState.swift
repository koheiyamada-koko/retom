
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


    // MARK: - 保存処理
    private var saveURL: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return doc.appendingPathComponent("appState.json")
    }

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
}