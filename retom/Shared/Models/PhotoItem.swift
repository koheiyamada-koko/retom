// File: Shared/Models/PhotoItem.swift
import Foundation

struct PhotoItem: Identifiable, Codable, Equatable {
    let id: UUID
    let capturedAt: Date
    var readyAt: Date
    var isUnlockedEarly: Bool
    var requiresAdGateBeforeReady: Bool
    var imageDataURL: URL
    var memoDrawingData: Data?

    var hasMemo: Bool {
        memoDrawingData != nil
    }

    /// 閲覧可能かどうか（プレミアムは常に閲覧可）
    func isViewable(isPremium: Bool) -> Bool {
        if isPremium { return true }
        if isUnlockedEarly { return true }
        return Date() >= readyAt
    }

    /// 残り秒数
    var remainingSeconds: Int {
        max(0, Int(readyAt.timeIntervalSince(Date())))
    }

    var remainingTimeString: String {
        let total = remainingSeconds
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

