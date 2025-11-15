// File: retom/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("カメラ", systemImage: "camera")
                }

            AlbumView()
                .tabItem {
                    Label("アルバム", systemImage: "photo.on.rectangle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}

