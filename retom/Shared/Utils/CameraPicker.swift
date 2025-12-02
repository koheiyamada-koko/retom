// File: retom/Shared/Utils/CameraPicker.swift
import SwiftUI
import UIKit

/// カメラ or フォトライブラリから UIImage を1枚返すラッパー
struct CameraPicker: UIViewControllerRepresentable {

    /// どこから画像を取るか（今は .camera だけ使う想定）
    enum Source {
        case camera
        case library
    }

    let from: Source
    let onImagePicked: (UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        // ✅ シミュレータと実機で挙動を分ける
        #if targetEnvironment(simulator)
        // シミュレータではカメラが不安定なのでライブラリ固定
        picker.sourceType = .photoLibrary
        #else
        // 実機では .camera を優先、ダメなら .photoLibrary
        switch from {
        case .camera:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
            } else {
                picker.sourceType = .photoLibrary
            }
        case .library:
            picker.sourceType = .photoLibrary
        }
        #endif

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: Context) {
        // 更新処理は特に不要
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {

        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // 編集後 > オリジナルの順で拾う
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.onImagePicked(image)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            parent.dismiss()
        }
    }
}

