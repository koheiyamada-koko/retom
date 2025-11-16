// File: retom/retomApp.swift
import SwiftUI

@main
struct retomApp: App {
    /// アプリ全体で共有する状態
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)   // 画面に共有
                .task {
                    // アプリ起動時に一度だけ読み込む
                    appState.load()
                }
        }
    }
}

