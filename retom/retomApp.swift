// File: retom/retomApp.swift
import SwiftUI

@main
struct retomApp: App {
    // アプリ全体で共有する状態
    @StateObject private var appState = AppState.shared

    init() {
        // 起動時に保存済みデータを読み込む
        AppState.shared.load()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // 全画面に渡す
        }
    }
}
