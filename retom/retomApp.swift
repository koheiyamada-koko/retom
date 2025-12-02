// File: retom/retomApp.swift
import SwiftUI

@main
struct retomApp: App {
    /// アプリ全体で共有する状態
    @StateObject private var appState = AppState.shared
    /// 課金管理
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)           // 画面に共有
                .environmentObject(purchaseManager)   // 課金管理を共有
                .task {
                    // アプリ起動時に一度だけ読み込む
                    appState.load()
                    // 購入状態を確認（PurchaseManagerのinitでも呼ばれるが、念のため）
                    await purchaseManager.checkPurchaseStatus()
                }
        }
    }
}

