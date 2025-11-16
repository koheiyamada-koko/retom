// File: Shared/Utils/CameraPicker.swift
import SwiftUI
import UIKit

/// UIKit の UIImagePickerController をラップして、
/// SwiftUI から「画像が1枚返ってくるコンポーネント」として使う
struct CameraPicker: UIViewControllerRepresentable {

    /// どこから画像を取るか（カメラ or ライブラリ）
    enum Source {
        case camera
        case library
    }

    /// 呼び出し元から指定してもらうソース
    let from: Source

    /// 選ばれた画像を返すコールバック
    let onImagePicked: (UIImage?) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        // 指定された Source に応じて UIKit の sourceType を決める
        let sourceType: UIImagePickerController.SourceType
        switch from {
        case .camera:
            // シミュレーターなどでカメラが使えないときは自動でライブラリにフォールバック
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                sourceType = .camera
            } else {
                sourceType = .photoLibrary
            }
        case .library:
            sourceType = .photoLibrary
        }

        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 今回は特に更新することなし
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let image = info[.originalImage] as? UIImage
            parent.onImagePicked(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

