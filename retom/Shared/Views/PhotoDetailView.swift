// File: Shared/Views/PhotoDetailView.swift
import SwiftUI

struct PhotoDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let photo: PhotoItem

    // ズーム & パン用の状態
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = UIImage(contentsOfFile: photo.imageDataURL.path) {
                GeometryReader { geo in
                    let magnification = MagnificationGesture()
                        .onChanged { value in
                            // 最小1倍〜最大4倍くらいまでに制限
                            let newScale = lastScale * value
                            scale = min(max(1.0, newScale), 4.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }

                    let drag = DragGesture()
                        .onChanged { value in
                            guard scale > 1.0 else {
                                // ズームしてないときはパンしない
                                offset = .zero
                                lastOffset = .zero
                                return
                            }
                            offset = CGSize(
                                width:  lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnification)
                        .simultaneousGesture(drag)
                }
            } else {
                Text("写真を読み込めませんでした")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("写真")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 右上ゴミ箱（削除）
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    deletePhoto()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func deletePhoto() {
        appState.delete(photo)
        dismiss()
    }
}

