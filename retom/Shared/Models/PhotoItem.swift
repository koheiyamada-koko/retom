// File: Shared/Models/PhotoItem.swift
import Foundation

struct PhotoItem: Identifiable, Codable, Hashable {
    let id: UUID
    let capturedAt: Date

    /// 画像ファイルの保存先（Documents 配下）
    let imageDataURL: URL

    // あとで使うかもしれないフラグ類（今はダミーでもOK）
    let readyAt: Date
    let isUnlockedEarly: Bool
    let requiresAdGateBeforeReady: Bool

    /// 手書きメモなどを保存したいときに使う
    var memoDrawingData: Data?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        imageDataURL: URL,
        readyAt: Date? = nil,
        isUnlockedEarly: Bool = true,
        requiresAdGateBeforeReady: Bool = false,
        memoDrawingData: Data? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.imageDataURL = imageDataURL
        self.readyAt = readyAt ?? capturedAt
        self.isUnlockedEarly = isUnlockedEarly
        self.requiresAdGateBeforeReady = requiresAdGateBeforeReady
        self.memoDrawingData = memoDrawingData
    }
}

