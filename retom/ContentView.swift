// File: retom/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            // カメラタブ（あとで本物のカメラ画面に差し替える）
            NavigationStack {
                VStack(spacing: 16) {
                    Text("📷 カメラ画面（これから作ります）")
                        .font(.title3)

                    Text("いま保存されている写真：\(appState.photos.count)枚")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("retom カメラ")
            }
            .tabItem {
                Label("カメラ", systemImage: "camera")
            }

            // アルバムタブ（これから実装）
            NavigationStack {
                VStack(spacing: 16) {
                    Text("🖼 アルバム画面（これから作ります）")
                        .font(.title3)

                    if appState.photos.isEmpty {
                        Text("まだ写真はありません")
                            .foregroundColor(.secondary)
                    } else {
                        Text("写真が \(appState.photos.count) 枚あります")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .navigationTitle("retom アルバム")
            }
            .tabItem {
                Label("アルバム", systemImage: "photo.on.rectangle")
            }
        }
    }
}
